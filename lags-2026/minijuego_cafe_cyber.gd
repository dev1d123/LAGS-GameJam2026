extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_cafe_cyber"
const STRESS_SHADER := preload("res://assets/shaders/stress_cafe_cyber.gdshader")
const STANDARD_UI_TEXT_COLOR := Color(0.687779, 0.643646, 0.632612, 1.0)

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
@onready var source_grid: GridContainer = $MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/PanelContainer/SourceGrid
@onready var target_grid: GridContainer = $MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/PanelContainer2/TargetGrid
@onready var selected_source_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SelectedSource
@onready var progress_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/Progress
@onready var submit_button: Button = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SubmitButton
@onready var round_result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

@onready var sfx_enchufado: AudioStreamPlayer = $Audio/SFX_Enchufado
@onready var sfx_fallo: AudioStreamPlayer = $Audio/SFX_Fallo
@onready var sfx_ok_base: AudioStreamPlayer = $Audio/SFX_OkBase
@onready var sfx_error: AudioStreamPlayer = $Audio/SFX_Error
@onready var sfx_reloj: AudioStreamPlayer = $Audio/SFX_Reloj
var playing_reloj: bool = false
var cable_types: Array[String] = ["amarillo", "verde", "negro", "morado", "azul", "rojo", "blanco", "naranja"]

@onready var lines_container: Control = $MainPanel/Margin/VBox/Content/CenterPanel/CableArea/LinesContainer
@onready var cable_area: PanelContainer = $MainPanel/Margin/VBox/Content/CenterPanel/CableArea
@onready var cable_template: PanelContainer = lines_container.get_node_or_null("CableTemplate")

var all_source_ports: Dictionary = {}
var all_target_ports: Dictionary = {}

var current_round: int = 0
var score: int = 0
var round_time_left: float = 0.0
var pending_next_round: float = -1.0
var desempeno: float = 0.0
var eficiencia: float = 0.0
var recompensa_total: int = 0
var estres: float = 0.0
var stress_difficulty: float = 0.0
var mission_money_min: int = 0
var mission_money_max: int = 0

var connected_cables: Array = []
var active_types: Array[String] = []
var selected_source_type: String = ""
var matched_count: int = 0
var expected_matches: int = 0

var source_buttons_by_type: Dictionary = {}
var target_buttons_by_type: Dictionary = {}

var is_round_locked: bool = false
var preview_time_left: float = -1.0  # Locked preview before round starts

# Live drag cable
var drag_line: Line2D = null
var drag_plug_a: TextureRect = null
var drag_plug_b_cursor: Control = null  # cable-b sprite following mouse
var drag_source_btn: TextureButton = null
var drag_source_type: String = ""
var stress_fx_overlay: ColorRect
var stress_fx_material: ShaderMaterial
var stress_fx_time: float = 0.0


func _ready() -> void:
	ninepatch_shader.code = NINEPATCH_SHADER_CODE
	randomize()
	_setup_stress_shader()
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


func _input(event: InputEvent) -> void:
	if drag_line != null and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_drag()


func _cancel_drag() -> void:
	if drag_line != null:
		drag_line.queue_free()
		drag_line = null
	if drag_plug_a != null:
		drag_plug_a.queue_free()
		drag_plug_a = null
	if drag_plug_b_cursor != null:
		drag_plug_b_cursor.queue_free()
		drag_plug_b_cursor = null
	if drag_source_btn != null:
		drag_source_btn.set_pressed_no_signal(false)
		drag_source_btn.self_modulate = Color(1, 1, 1, 1)
		drag_source_btn = null
	drag_source_type = ""
	selected_source_type = ""
	selected_source_label.text = _t("selected_source_none")


func _process(delta: float) -> void:
	_update_stress_shader(delta)
	if current_round <= 0:
		return

	# Preview phase countdown
	if preview_time_left > 0.0:
		preview_time_left -= delta
		timer_label.text = "Observa: %.1fs" % preview_time_left
		if preview_time_left <= 0.0:
			preview_time_left = -1.0
			is_round_locked = false
			submit_button.disabled = false
			cable_area.self_modulate = Color(1, 1, 1, 1)
			timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
		return

	if not is_round_locked:
		round_time_left = max(0.0, round_time_left - delta)
		timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
		
		if round_time_left > 0.0 and round_time_left <= 7.0:
			if not playing_reloj:
				playing_reloj = true
				sfx_reloj.play()
		else:
			if playing_reloj:
				playing_reloj = false
				sfx_reloj.stop()
				
		if round_time_left <= 0.0:
			_resolve_round(false, "timeout")
			return

	# Update drag preview line to follow mouse
	if drag_line != null and drag_source_btn != null and is_instance_valid(drag_source_btn):
		var l_inv = lines_container.get_global_transform().inverse()
		var p1 = l_inv * (drag_source_btn.global_position + cable_offset_a)
		var p2 = l_inv * get_global_mouse_position()
		
		var curve = Curve2D.new()
		var dist_x = abs(p2.x - p1.x)
		var sag = 60.0
		curve.add_point(p1, Vector2.ZERO, Vector2(dist_x * 0.45, sag))
		curve.add_point(p2, Vector2(-dist_x * 0.45, sag), Vector2.ZERO)
		
		drag_line.clear_points()
		for point in curve.get_baked_points():
			drag_line.add_point(point)
		if drag_line.material:
			drag_line.material.set_shader_parameter("line_length", curve.get_baked_length())
	
	# Move plug-b cursor icon to mouse position
	if drag_plug_b_cursor != null:
		drag_plug_b_cursor.global_position = get_global_mouse_position() - drag_plug_b_cursor.size / 2.0

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
	_apply_standard_ui_colors()


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	is_round_locked = true  # Locked during preview
	round_result_label.visible = false
	submit_button.disabled = true
	selected_source_type = ""

	_build_round_board(current_round)

	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	# Time = cables × secs_per_cable + buffer
	# secs_per_cable: ~2.5s in round 1 (find + 2 clicks), drops 0.2s per round
	# buffer: 3s flat (mistakes / hesitation)
	var secs_per_cable: float = max(1.5, 2.5 - float(current_round - 1) * 0.2)
	round_time_left = max(8.0, float(expected_matches) * secs_per_cable + 3.0)
	timer_label.text = "Observa: 2.0s"
	preview_time_left = 2.0
	cable_area.self_modulate = Color(0.45, 0.45, 0.5, 1.0)
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


func _setup_stress_shader() -> void:
	var shader_host: Control = cable_area if cable_area != null else self
	stress_fx_overlay = ColorRect.new()
	stress_fx_overlay.name = "StressFXOverlay"
	stress_fx_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stress_fx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stress_fx_overlay.color = Color(1, 1, 1, 0)
	stress_fx_overlay.z_index = 300
	stress_fx_material = ShaderMaterial.new()
	stress_fx_material.shader = STRESS_SHADER
	stress_fx_overlay.material = stress_fx_material
	shader_host.add_child(stress_fx_overlay)
	shader_host.move_child(stress_fx_overlay, shader_host.get_child_count() - 1)
	stress_fx_material.set_shader_parameter("intensity", _stress_to_power())


func _update_stress_shader(delta: float) -> void:
	if stress_fx_material == null:
		return
	stress_fx_time += delta
	stress_fx_material.set_shader_parameter("time_sec", stress_fx_time)


func _stress_to_power() -> float:
	var normalized := clampf(stress_difficulty / 100.0, 0.0, 1.0)
	return clampf(pow(normalized, 0.86) * 1.6, 0.0, 1.6)


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
		# Cancel any existing drag first
		_cancel_drag()
		
		selected_source_type = this_type
		drag_source_btn = button
		button.set_pressed_no_signal(true)
		button.self_modulate = Color(1.4, 1.4, 1.4, 1.0)
		
		for cable_type in source_buttons_by_type.keys():
			var src: TextureButton = source_buttons_by_type[cable_type]
			if src != button:
				src.set_pressed_no_signal(false)
				src.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
				
		selected_source_label.text = _t("selected_source") % [_t("cable_" + selected_source_type)]
		
		# Show plug-a overlay on the source button
		var path_base := "res://assets/textures/minigame-cafe-cyber/"
		drag_plug_a = TextureRect.new()
		drag_plug_a.texture = load(path_base + "cable-a-" + this_type + ".png")
		drag_plug_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drag_plug_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		drag_plug_a.set_anchors_preset(PRESET_FULL_RECT)
		drag_plug_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(drag_plug_a)
		
		# Create ghost drag line
		var line = Line2D.new()
		line.texture = load(path_base + "cable-" + this_type + ".png")
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.modulate.a = 0.7
		if line.texture: line.width = float(line.texture.get_height())
		else: line.width = 15.0
		
		var mat = ShaderMaterial.new()
		mat.shader = ninepatch_shader
		mat.set_shader_parameter("margin", 10.0)
		if line.texture:
			mat.set_shader_parameter("tex_width", float(line.texture.get_width()))
		line.material = mat
		
		lines_container.add_child(line)
		drag_line = line
		drag_source_type = this_type
		
		# Create cursor plug-b icon
		var plug_b_cursor = TextureRect.new()
		plug_b_cursor.texture = load(path_base + "cable-b-" + this_type + ".png")
		plug_b_cursor.custom_minimum_size = Vector2(96, 96)
		plug_b_cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plug_b_cursor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plug_b_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(plug_b_cursor)
		drag_plug_b_cursor = plug_b_cursor
	else:
		if selected_source_type == this_type:
			_cancel_drag()


func _on_target_pressed(button: TextureButton) -> void:
	if is_round_locked:
		return
	
	var target_type: String = String(button.get_meta("cable_type", ""))
	
	# --- UNPLUG existing cable from this target (reroute) ---
	var existing_idx := -1
	for i in connected_cables.size():
		if connected_cables[i]["tgt_btn"] == button:
			existing_idx = i
			break
	
	if existing_idx >= 0:
		var old = connected_cables[existing_idx]
		var old_line: Line2D = old["line"]
		var old_src: TextureButton = old["src_btn"]
		var was_correct: bool = old.get("correct", false)
		
		if is_instance_valid(old_line): old_line.queue_free()
		
		# Remove plug overlays, re-enable ports
		if is_instance_valid(old_src):
			for ch in old_src.get_children():
				if ch is TextureRect: ch.queue_free()
			old_src.disabled = false
			old_src.self_modulate = Color(1, 1, 1, 1)
		for ch in button.get_children():
			if ch is TextureRect: ch.queue_free()
		button.self_modulate = Color(1, 1, 1, 1)
		
		if was_correct:
			matched_count -= 1
			progress_label.text = _t("progress") % [matched_count, expected_matches]
		
		connected_cables.remove_at(existing_idx)
		
		# Re-activate the old cable as the current selection in drag mode
		var rescued_type := old_src.get_meta("cable_type", "") as String
		# Cancel any existing drag first
		if drag_line != null:
			drag_line.queue_free()
			drag_line = null
		if drag_plug_a != null:
			drag_plug_a.queue_free()
			drag_plug_a = null
		if drag_plug_b_cursor != null:
			drag_plug_b_cursor.queue_free()
			drag_plug_b_cursor = null
		
		# Set up new drag from the unplugged source
		selected_source_type = rescued_type
		drag_source_type = rescued_type
		drag_source_btn = old_src
		old_src.disabled = false
		old_src.self_modulate = Color(1.4, 1.4, 1.4, 1.0)
		old_src.set_pressed_no_signal(true)
		selected_source_label.text = _t("selected_source") % [_t("cable_" + rescued_type)]
		
		var path_base_r := "res://assets/textures/minigame-cafe-cyber/"
		# Add plug-a overlay back
		var plug_a_r = TextureRect.new()
		plug_a_r.texture = load(path_base_r + "cable-a-" + rescued_type + ".png")
		plug_a_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plug_a_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plug_a_r.set_anchors_preset(PRESET_FULL_RECT)
		plug_a_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		old_src.add_child(plug_a_r)
		drag_plug_a = plug_a_r
		
		# Rebuild ghost drag line
		var new_line = Line2D.new()
		new_line.texture = load(path_base_r + "cable-" + rescued_type + ".png")
		new_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		new_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		new_line.joint_mode = Line2D.LINE_JOINT_ROUND
		new_line.modulate.a = 0.7
		if new_line.texture: new_line.width = float(new_line.texture.get_height())
		else: new_line.width = 15.0
		var mat_r = ShaderMaterial.new()
		mat_r.shader = ninepatch_shader
		mat_r.set_shader_parameter("margin", 10.0)
		if new_line.texture:
			mat_r.set_shader_parameter("tex_width", float(new_line.texture.get_width()))
		new_line.material = mat_r
		lines_container.add_child(new_line)
		drag_line = new_line
		
		# Create new cursor plug-b icon
		var plug_b_cur = TextureRect.new()
		plug_b_cur.texture = load(path_base_r + "cable-b-" + rescued_type + ".png")
		plug_b_cur.custom_minimum_size = Vector2(96, 96)
		plug_b_cur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plug_b_cur.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plug_b_cur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(plug_b_cur)
		drag_plug_b_cursor = plug_b_cur
		return  # Done — don't place a new cable yet
	else:
		# No cable here - require source selected to place one
		if selected_source_type == "":
			return
	
	# --- PLACE new cable from selected source to this target ---
	var src_btn: TextureButton = source_buttons_by_type.get(selected_source_type)
	if src_btn == null:
		return
	
	var is_correct: bool = (target_type == selected_source_type)
	var path_base := "res://assets/textures/minigame-cafe-cyber/"
	
	# Lock source port visually
	src_btn.disabled = true
	src_btn.set_pressed_no_signal(false)
	src_btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	# Remove any drag-preview plug overlay
	if drag_plug_a != null:
		drag_plug_a.queue_free()
		drag_plug_a = null
	var plug_a = TextureRect.new()
	plug_a.texture = load(path_base + "cable-a-" + selected_source_type + ".png")
	plug_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plug_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plug_a.set_anchors_preset(PRESET_FULL_RECT)
	plug_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	src_btn.add_child(plug_a)
	
	# Place plug-b with source cable color (not target color)
	button.self_modulate = Color(1.0, 1.0, 1.0, 1.0) if is_correct else Color(1.3, 0.6, 0.6, 1.0)
	var plug_b = TextureRect.new()
	plug_b.texture = load(path_base + "cable-b-" + selected_source_type + ".png")
	plug_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plug_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plug_b.set_anchors_preset(PRESET_FULL_RECT)
	plug_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(plug_b)
	
	# Build permanent cable line
	var line = Line2D.new()
	line.texture = load(path_base + "cable-" + selected_source_type + ".png")
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	if not is_correct: line.modulate = Color(1.2, 0.6, 0.6, 1.0)
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
		"tgt_btn": button,
		"correct": is_correct
	})
	sfx_enchufado.play()
	
	if is_correct:
		matched_count += 1
	else:
		round_time_left = max(0.0, round_time_left - 1.5)
		sfx_fallo.play()
	
	# Clear drag preview state
	if drag_line != null:
		drag_line.queue_free()
		drag_line = null
	if drag_plug_b_cursor != null:
		drag_plug_b_cursor.queue_free()
		drag_plug_b_cursor = null
	drag_source_btn = null
	drag_source_type = ""
	selected_source_type = ""
	selected_source_label.text = _t("selected_source_none")
	progress_label.text = _t("progress") % [matched_count, expected_matches]
	
	if matched_count >= expected_matches:
		_resolve_round(true, "all_matched")


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

	if playing_reloj:
		playing_reloj = false
		sfx_reloj.stop()

	for child in source_grid.get_children():
		if child is TextureButton:
			child.disabled = true
	for child in target_grid.get_children():
		if child is TextureButton:
			child.disabled = true

	if success:
		score += 1
		sfx_ok_base.play()
		round_result_label.text = _t("correct")
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		sfx_error.play()
		if reason == "timeout":
			round_result_label.text = _t("timeout")
		else:
			round_result_label.text = _t("incorrect")
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	_cancel_drag()
	pending_next_round = 2.0


func _finish_minigame() -> void:
	is_round_locked = true
	submit_button.disabled = true

	if playing_reloj:
		playing_reloj = false
		sfx_reloj.stop()

	var success: bool = score >= int(ceil(float(total_rounds) * 0.6))
	eficiencia = clamp((float(score) / max(1.0, float(total_rounds))) * 100.0, 0.0, 100.0)
	desempeno = clamp(100.0 - eficiencia, 0.0, 100.0)
	estres = lerpf(2.0, 22.0, desempeno / 100.0)
	recompensa_total = _calc_recompensa_from_eficiencia()
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


func _apply_standard_ui_colors() -> void:
	for label in [guide_title_label, guide1_label, guide2_label, guide3_label, objectives_title_label, rounds_label, instruction_label, results_title_label, round_result_label]:
		if label != null:
			label.add_theme_color_override("font_color", STANDARD_UI_TEXT_COLOR)


func _calc_recompensa_from_eficiencia() -> int:
	var min_money: int = mission_money_min
	var max_money: int = max(mission_money_min, mission_money_max)
	return int(round(lerpf(float(min_money), float(max_money), clamp(eficiencia / 100.0, 0.0, 1.0))))




func _t(key: String) -> String:
	return LocaleManager.get_text(I18N_CATEGORY, key)
