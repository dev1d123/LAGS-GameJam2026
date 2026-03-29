extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_cafe_candy"
const SFX_CLICK_STREAM := preload("res://assets/audio/button_click_1.mp3")
const SFX_SUCCESS_STREAM := preload("res://scenes/minigameIndications/success.ogg")
const SFX_ERROR_STREAM := preload("res://scenes/minigameIndications/error.ogg")
const SFX_FINAL_SUCCESS_STREAM := preload("res://assets/audio/game/WinMinigame.ogg")
const SFX_FINAL_FAIL_STREAM := preload("res://assets/audio/game/LoseMinigame.ogg")
const STRESS_SHADER := preload("res://assets/shaders/stress_cafe_candy.gdshader")
const STANDARD_UI_TEXT_COLOR := Color(0.687779, 0.643646, 0.632612, 1.0)

@export var total_rounds: int = 5
@export var round_time_base: float = 18.0

@onready var title_label: Button = $MainPanel/Margin/VBox/TitleSlot/Title
@onready var left_panel: VBoxContainer = $MainPanel/Margin/VBox/Content/LeftPanel
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
@onready var candy_field: Control = $MainPanel/Margin/VBox/Content/CenterPanel/CandyField
@onready var candy_grid: GridContainer = $MainPanel/Margin/VBox/Content/CenterPanel/CandyField/CandyGrid
@onready var submit_button: Button = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SubmitButton
@onready var selected_counter_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SelectedCounter
@onready var round_result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

var candy_types: Array[String] = ["strawberry", "mint", "cola", "lemon"]
var candy_type_textures: Dictionary = {
	"strawberry": preload("res://assets/sprites/ui/strawberry_caramel.png"),
	"mint": preload("res://assets/sprites/ui/mint_caramel.png"),
	"cola": preload("res://assets/sprites/ui/cola_caramel.png"),
	"lemon": preload("res://assets/sprites/ui/lemon_caramel.png")
}
var candy_type_colors: Dictionary = {
	"strawberry": Color(0.96, 0.39, 0.46, 1.0),
	"mint": Color(0.39, 0.84, 0.56, 1.0),
	"cola": Color(0.58, 0.43, 0.34, 1.0),
	"lemon": Color(0.95, 0.86, 0.35, 1.0)
}

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

var request_type: String = ""
var request_amount: int = 0
var selected_count: int = 0

var is_round_locked: bool = false
var sfx_click_player: AudioStreamPlayer
var sfx_success_player: AudioStreamPlayer
var sfx_error_player: AudioStreamPlayer
var sfx_final_player: AudioStreamPlayer
var stress_fx_overlay: ColorRect
var stress_fx_material: ShaderMaterial
var stress_fx_time: float = 0.0


func _ready() -> void:
	randomize()
	_setup_sfx()
	_setup_stress_shader()
	submit_button.pressed.connect(_on_submit_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
	_populate_guide_reference()
	call_deferred("_start_round")


func _setup_sfx() -> void:
	sfx_click_player = AudioStreamPlayer.new()
	sfx_click_player.stream = SFX_CLICK_STREAM
	sfx_click_player.bus = &"SFX"
	sfx_click_player.volume_db = -9.0
	add_child(sfx_click_player)

	sfx_success_player = AudioStreamPlayer.new()
	sfx_success_player.stream = SFX_SUCCESS_STREAM
	sfx_success_player.bus = &"SFX"
	sfx_success_player.volume_db = -8.0
	add_child(sfx_success_player)

	sfx_error_player = AudioStreamPlayer.new()
	sfx_error_player.stream = SFX_ERROR_STREAM
	sfx_error_player.bus = &"SFX"
	sfx_error_player.volume_db = -8.0
	add_child(sfx_error_player)

	sfx_final_player = AudioStreamPlayer.new()
	sfx_final_player.bus = &"SFX"
	sfx_final_player.volume_db = -8.0
	add_child(sfx_final_player)


func _process(delta: float) -> void:
	_update_stress_shader(delta)
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
	selected_counter_label.text = _t("selected_counter") % [0, 0]
	round_result_label.text = ""
	round_result_label.visible = false
	finish_button.visible = false
	_apply_standard_ui_colors()


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	is_round_locked = false
	round_result_label.visible = false
	submit_button.disabled = false

	_build_round_board(current_round)

	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	round_time_left = max(8.0, round_time_base - float(current_round - 1) * 1.5)
	timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
	selected_counter_label.text = _t("selected_counter") % [selected_count, request_amount]


func _build_round_board(round_number: int) -> void:
	for child in candy_grid.get_children():
		child.queue_free()

	request_type = candy_types[randi_range(0, candy_types.size() - 1)]
	request_amount = randi_range(2, min(6, 2 + round_number))

	var total_cells: int = 10 + round_number * 2
	var required_positions: Array[int] = []
	while required_positions.size() < request_amount:
		var idx: int = randi_range(0, total_cells - 1)
		if not required_positions.has(idx):
			required_positions.append(idx)

	selected_count = 0
	request_label.text = _t("request") % [_t("candy_" + request_type), request_amount]

	for i in total_cells:
		var candy_type: String = request_type if required_positions.has(i) else candy_types[randi_range(0, candy_types.size() - 1)]
		var button := _create_candy_button(candy_type)
		candy_grid.add_child(button)


func _create_candy_button(candy_type: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(110, 96)
	button.toggle_mode = true
	button.text = ""
	button.icon = _get_candy_texture(candy_type)
	button.expand_icon = true

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0, 0, 0, 0)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0, 0, 0, 0)
	pressed.border_width_left = 2
	pressed.border_width_top = 2
	pressed.border_width_right = 2
	pressed.border_width_bottom = 2
	pressed.border_color = Color(1.0, 0.95, 0.75, 0.9)
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_right = 6
	pressed.corner_radius_bottom_left = 6

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.set_meta("candy_type", candy_type)
	button.toggled.connect(_on_candy_toggled.bind(button))
	return button


func _populate_guide_reference() -> void:
	if left_panel == null:
		return

	var existing := left_panel.get_node_or_null("FlavorGuide")
	if existing != null:
		existing.queue_free()

	var flavor_guide := PanelContainer.new()
	flavor_guide.name = "FlavorGuide"
	left_panel.add_child(flavor_guide)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	flavor_guide.add_child(list)

	for candy_type in candy_types:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(36, 36)
		icon_rect.texture = _get_candy_texture(candy_type)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon_rect)

		var flavor_label := Label.new()
		flavor_label.text = _t("candy_" + candy_type)
		flavor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(flavor_label)


func _get_candy_texture(candy_type: String) -> Texture2D:
	return candy_type_textures.get(candy_type, null) as Texture2D


func _get_button_normal_color(candy_type: String) -> Color:
	var base: Color = candy_type_colors.get(candy_type, Color(0.8, 0.8, 0.8, 1.0))
	return Color(base.r * 0.85, base.g * 0.85, base.b * 0.85, 1.0)


func _get_button_pressed_color(candy_type: String) -> Color:
	var base: Color = candy_type_colors.get(candy_type, Color(0.8, 0.8, 0.8, 1.0))
	return Color(min(1.0, base.r + 0.1), min(1.0, base.g + 0.1), min(1.0, base.b + 0.1), 1.0)


func _setup_stress_shader() -> void:
	var shader_host: Control = candy_field if candy_field != null else self
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
	var base_intensity := _stress_to_power()
	var pulse := 1.0 + sin(stress_fx_time * 3.2) * 0.03
	stress_fx_material.set_shader_parameter("intensity", base_intensity * pulse)


func _stress_to_power() -> float:
	var normalized := clampf(stress_difficulty / 100.0, 0.0, 1.0)
	return clampf(pow(normalized, 1.0) * 0.9, 0.0, 0.9)


func _on_candy_toggled(pressed: bool, button: Button) -> void:
	if is_round_locked:
		button.set_pressed_no_signal(false)
		return

	if pressed:
		selected_count += 1
	else:
		selected_count = max(0, selected_count - 1)

	if sfx_click_player != null:
		sfx_click_player.pitch_scale = randf_range(0.95, 1.08)
		sfx_click_player.play()

	selected_counter_label.text = _t("selected_counter") % [selected_count, request_amount]


func _on_submit_button_pressed() -> void:
	if is_round_locked:
		return

	if sfx_click_player != null:
		sfx_click_player.pitch_scale = 1.0
		sfx_click_player.play()

	var right_selected: int = 0
	var wrong_selected: int = 0
	for child in candy_grid.get_children():
		var button := child as Button
		if button == null or not button.button_pressed:
			continue
		if String(button.get_meta("candy_type", "")) == request_type:
			right_selected += 1
		else:
			wrong_selected += 1

	var success: bool = right_selected == request_amount and wrong_selected == 0
	_resolve_round(success, "submit")


func _resolve_round(success: bool, reason: String) -> void:
	if is_round_locked:
		return

	is_round_locked = true
	submit_button.disabled = true

	for child in candy_grid.get_children():
		var button := child as Button
		if button != null:
			button.disabled = true

	if success:
		score += 1
		round_result_label.text = _t("correct")
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
		if sfx_success_player != null:
			sfx_success_player.pitch_scale = randf_range(0.95, 1.1)
			sfx_success_player.play()
	else:
		if reason == "timeout":
			round_result_label.text = _t("timeout")
		else:
			round_result_label.text = _t("incorrect")
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)
		if sfx_error_player != null:
			sfx_error_player.pitch_scale = 0.95 if reason == "timeout" else 1.0
			sfx_error_player.play()

	round_result_label.visible = true
	pending_next_round = 1.0


func _finish_minigame() -> void:
	is_round_locked = true
	submit_button.disabled = true

	var success: bool = score >= int(ceil(float(total_rounds) * 0.6))
	eficiencia = clamp((float(score) / max(1.0, float(total_rounds))) * 100.0, 0.0, 100.0)
	desempeno = clamp(100.0 - eficiencia, 0.0, 100.0)
	estres = lerpf(2.0, 22.0, desempeno / 100.0)
	recompensa_total = _calc_recompensa_from_eficiencia()
	if success:
		round_result_label.text = _t("final_success") % [score, total_rounds]
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
		if sfx_final_player != null:
			sfx_final_player.stream = SFX_FINAL_SUCCESS_STREAM
			sfx_final_player.play()
	else:
		round_result_label.text = _t("final_fail") % [score, total_rounds]
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)
		if sfx_final_player != null:
			sfx_final_player.stream = SFX_FINAL_FAIL_STREAM
			sfx_final_player.play()

	round_result_label.visible = true
	finish_button.visible = true
	emit_signal("minigame_finished", success, score, total_rounds)


func _on_finish_button_pressed() -> void:
	if sfx_click_player != null:
		sfx_click_player.pitch_scale = 1.0
		sfx_click_player.play()
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
