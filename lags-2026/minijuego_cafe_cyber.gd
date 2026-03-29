extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_cafe_cyber"

@export var total_rounds: int = 5
@export var round_time_base: float = 20.0
@export var cable_offset_a: Vector2 = Vector2(80, 35)
@export var cable_offset_b: Vector2 = Vector2(20, 35)

const NINEPATCH_SHADER_CODE = """
shader_type canvas_item;
uniform float line_length = 100.0;
uniform float tex_width = 100.0;
uniform float margin = 10.0;

void fragment() {
    float pixel_x = UV.x * line_length;
    float new_uv_x = 0.0;

    if (pixel_x < margin) {
        new_uv_x = pixel_x / tex_width;
    } else if (pixel_x > line_length - margin) {
        float dist_from_right = line_length - pixel_x;
        new_uv_x = (tex_width - dist_from_right) / tex_width;
    } else {
        float mid_len = line_length - margin * 2.0;
        float tex_mid_len = tex_width - margin * 2.0;
        float tiles = round(mid_len / tex_mid_len);
        tiles = max(1.0, tiles);
        
        float local_mid_x = pixel_x - margin;
        float phase = fract((local_mid_x / mid_len) * tiles);
        new_uv_x = (margin + phase * tex_mid_len) / tex_width;
    }
    
    COLOR = texture(TEXTURE, vec2(new_uv_x, UV.y));
}
"""
var ninepatch_shader: Shader = Shader.new()

@onready var title_label: Button = $MainPanel/Margin/VBox/TitleSlot/Title
@onready var guide_title_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/GuideTitle/GuideTitleLabel
@onready var guide1_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide1/Guide1Label
@onready var guide2_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide2/Guide2Label
@onready var guide3_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide3/Guide3Label
@onready var objectives_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesTitle/ObjectivesTitleLabel
@onready var rounds_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Rounds
@onready var instruction_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Instruction
@onready var results_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsTitle/ResultsTitleLabel
@onready var request_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/Request
@onready var timer_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/Timer
@onready var source_grid: GridContainer = $MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/SourceGrid
@onready var target_grid: GridContainer = $MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/TargetGrid
@onready var selected_source_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SelectedSource
@onready var progress_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/Progress
@onready var submit_button: Button = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SubmitButton
@onready var round_result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton
var cable_types: Array[String] = ["amarillo", "verde", "negro", "morado", "azul", "rojo", "blanco", "naranja"]

@onready var lines_container: Control = $MainPanel/Margin/VBox/Content/CenterPanel/CableArea/LinesContainer
@onready var cable_template: PanelContainer = lines_container.get_node_or_null("CableTemplate")

var all_source_ports: Dictionary = {}
var all_target_ports: Dictionary = {}

var current_round: int = 0
var score: int = 0
var round_time_left: float = 0.0
var pending_next_round: float = -1.0

var connected_cables: Array = []
var active_types: Array[String] = []
var selected_source_type: String = ""
var matched_count: int = 0
var expected_matches: int = 0

var source_buttons_by_type: Dictionary = {}
var target_buttons_by_type: Dictionary = {}

var is_round_locked: bool = false


func _ready() -> void:
	ninepatch_shader.code = NINEPATCH_SHADER_CODE
	randomize()
	submit_button.pressed.connect(_on_submit_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
	
	if cable_template:
		cable_template.hide()
		
	# Gather all editor ports
	for c in cable_types:
		var src = source_grid.get_node_or_null("PortA_" + c)
		if src:
			all_source_ports[c] = src
			src.toggled.connect(_on_source_toggled.bind(src))
			src.set_meta("cable_type", c)
			src.set_meta("is_source", true)
		
		var tgt = target_grid.get_node_or_null("PortB_" + c)
		if tgt:
			all_target_ports[c] = tgt
			tgt.pressed.connect(_on_target_pressed.bind(tgt))
			tgt.set_meta("cable_type", c)
			tgt.set_meta("is_source", false)
	
	call_deferred("_start_round")


func _process(delta: float) -> void:
	if current_round <= 0:
		return

	if not is_round_locked:
		round_time_left = max(0.0, round_time_left - delta)
		timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
		if round_time_left <= 0.0:
			_resolve_round(false, "timeout")
			return

	if pending_next_round >= 0.0:
		pending_next_round -= delta
		if pending_next_round <= 0.0:
			pending_next_round = -1.0
			_start_round()

	for data in connected_cables:
		var line: Line2D = data["line"]
		var src: TextureButton = data["src_btn"]
		var tgt: TextureButton = data["tgt_btn"]
		
		if is_instance_valid(line) and is_instance_valid(src) and is_instance_valid(tgt):
			var l_inv = lines_container.get_global_transform().inverse()
			var p1 = l_inv * (src.global_position + cable_offset_a)
			var p2 = l_inv * (tgt.global_position + cable_offset_b)
			
			var curve = Curve2D.new()
			var dist_x = abs(p2.x - p1.x)
			var sag = 90.0
			
			curve.add_point(p1, Vector2.ZERO, Vector2(dist_x * 0.45, sag))
			curve.add_point(p2, Vector2(-dist_x * 0.45, sag), Vector2.ZERO)
			
			line.clear_points()
			for point in curve.get_baked_points():
				line.add_point(point)
				
			if line.material:
				line.material.set_shader_parameter("line_length", curve.get_baked_length())

func _update_static_texts() -> void:
	title_label.text = _t("title")
	guide_title_label.text = _t("quick_guide")
	guide1_label.text = _t("guide_1")
	guide2_label.text = _t("guide_2")
	guide3_label.text = _t("guide_3")
	objectives_title_label.text = _t("objectives")
	results_title_label.text = _t("results")
	instruction_label.text = _t("instruction")
	submit_button.text = _t("submit")
	finish_button.text = _t("finish")
	rounds_label.text = _t("rounds") % [0, total_rounds]
	timer_label.text = _t("timer") % [0.0]
	request_label.text = ""
	selected_source_label.text = _t("selected_source_none")
	progress_label.text = _t("progress") % [0, 0]
	round_result_label.text = ""
	round_result_label.visible = false
	finish_button.visible = false


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	is_round_locked = false
	round_result_label.visible = false
	submit_button.disabled = false
	selected_source_type = ""

	_build_round_board(current_round)

	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	round_time_left = max(9.0, round_time_base - float(current_round - 1) * 1.7)
	timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
	selected_source_label.text = _t("selected_source_none")
	progress_label.text = _t("progress") % [matched_count, expected_matches]


func _build_round_board(round_number: int) -> void:
	for c in all_source_ports.keys():
		var src: TextureButton = all_source_ports[c]
		if src.get_parent():
			src.get_parent().remove_child(src)
		src.disabled = false
		src.set_pressed_no_signal(false)
		src.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		for child in src.get_children():
			if child is TextureRect and not child.name.begins_with("Plug"):
				child.queue_free()
			elif child is TextureRect and child.name.begins_with("Plug"):
				child.queue_free()

	for c in all_target_ports.keys():
		var tgt: TextureButton = all_target_ports[c]
		if tgt.get_parent():
			tgt.get_parent().remove_child(tgt)
		tgt.disabled = false
		tgt.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		for child in tgt.get_children():
			if child is TextureRect and not child.name.begins_with("Plug"):
				child.queue_free()
			elif child is TextureRect and child.name.begins_with("Plug"):
				child.queue_free()

	for child in lines_container.get_children():
		if child != cable_template:
			child.queue_free()
			
	connected_cables.clear()

	source_buttons_by_type.clear()
	target_buttons_by_type.clear()

	var cable_count: int = randi_range(4, min(8, cable_types.size()))
	active_types = cable_types.duplicate()
	active_types.shuffle()
	active_types = active_types.slice(0, cable_count)

	var shuffled_targets: Array[String] = active_types.duplicate()
	shuffled_targets.shuffle()
	while _is_same_order(active_types, shuffled_targets) and cable_count > 1:
		shuffled_targets.shuffle()

	for cable_type in active_types:
		var btn = all_source_ports.get(cable_type)
		if btn:
			source_grid.add_child(btn)
			source_buttons_by_type[cable_type] = btn

	for cable_type in shuffled_targets:
		var btn = all_target_ports.get(cable_type)
		if btn:
			target_grid.add_child(btn)
			target_buttons_by_type[cable_type] = btn

	matched_count = 0
	expected_matches = cable_count
	request_label.text = _t("request") % [cable_count]


func _is_same_order(a: Array[String], b: Array[String]) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true


func _on_source_toggled(pressed: bool, button: TextureButton) -> void:
	if is_round_locked:
		button.set_pressed_no_signal(false)
		return

	var this_type: String = String(button.get_meta("cable_type", ""))
	if pressed:
		selected_source_type = this_type
		button.self_modulate = Color(1.4, 1.4, 1.4, 1.0) # Highlight visually
		
		for cable_type in source_buttons_by_type.keys():
			var src: TextureButton = source_buttons_by_type[cable_type]
			if src != button:
				src.set_pressed_no_signal(false)
				src.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
				
		selected_source_label.text = _t("selected_source") % [_t("cable_" + selected_source_type)]
	else:
		if selected_source_type == this_type:
			selected_source_type = ""
			button.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
			selected_source_label.text = _t("selected_source_none")


func _on_target_pressed(button: TextureButton) -> void:
	if is_round_locked:
		return
	if selected_source_type == "":
		return

	var target_type: String = String(button.get_meta("cable_type", ""))
	if target_type == selected_source_type:
		var src_btn: TextureButton = source_buttons_by_type.get(selected_source_type)
		var tgt_btn: TextureButton = target_buttons_by_type.get(target_type)
		
		var path_base := "res://assets/textures/minigame-cafe-cyber/"
		if src_btn != null:
			src_btn.disabled = true
			src_btn.set_pressed_no_signal(false)
			src_btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			var plug_a = TextureRect.new()
			plug_a.texture = load(path_base + "cable-a-" + selected_source_type + ".png")
			plug_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			plug_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			plug_a.set_anchors_preset(PRESET_FULL_RECT)
			src_btn.add_child(plug_a)
			
		if tgt_btn != null:
			tgt_btn.disabled = true
			
			var plug_b = TextureRect.new()
			plug_b.texture = load(path_base + "cable-b-" + selected_source_type + ".png")
			plug_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			plug_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			plug_b.set_anchors_preset(PRESET_FULL_RECT)
			tgt_btn.add_child(plug_b)

		if src_btn and tgt_btn:
			var line = Line2D.new()
			line.texture = load(path_base + "cable-" + selected_source_type + ".png")
			line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
			line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			
			if line.texture: line.width = float(line.texture.get_height())
			else: line.width = 15.0
			
			var mat = ShaderMaterial.new()
			mat.shader = ninepatch_shader
			mat.set_shader_parameter("margin", 10.0)
			if line.texture:
				mat.set_shader_parameter("tex_width", float(line.texture.get_width()))
			line.material = mat
			
			lines_container.add_child(line)
			
			connected_cables.append({
				"line": line,
				"src_btn": src_btn,
				"tgt_btn": tgt_btn
			})

		matched_count += 1
		selected_source_type = ""
		selected_source_label.text = _t("selected_source_none")
		progress_label.text = _t("progress") % [matched_count, expected_matches]

		if matched_count >= expected_matches:
			_resolve_round(true, "all_matched")
	else:
		round_time_left = max(0.0, round_time_left - 1.5)


func _on_submit_button_pressed() -> void:
	if is_round_locked:
		return
	var success: bool = matched_count >= expected_matches
	_resolve_round(success, "submit")


func _resolve_round(success: bool, reason: String) -> void:
	if is_round_locked:
		return

	is_round_locked = true
	submit_button.disabled = true

	for child in source_grid.get_children():
		if child is TextureButton:
			child.disabled = true
	for child in target_grid.get_children():
		if child is TextureButton:
			child.disabled = true

	if success:
		score += 1
		round_result_label.text = _t("correct")
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		if reason == "timeout":
			round_result_label.text = _t("timeout")
		else:
			round_result_label.text = _t("incorrect")
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	pending_next_round = 1.0


func _finish_minigame() -> void:
	is_round_locked = true
	submit_button.disabled = true

	var success: bool = score >= int(ceil(float(total_rounds) * 0.6))
	if success:
		round_result_label.text = _t("final_success") % [score, total_rounds]
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		round_result_label.text = _t("final_fail") % [score, total_rounds]
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	finish_button.visible = true
	emit_signal("minigame_finished", success, score, total_rounds)


func _on_finish_button_pressed() -> void:
	queue_free()


func _t(key: String) -> String:
	return LocaleManager.get_text(I18N_CATEGORY, key)
