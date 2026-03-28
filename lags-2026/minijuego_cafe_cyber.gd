extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_cafe_cyber"

@export var total_rounds: int = 5
@export var round_time_base: float = 20.0

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

var cable_types: Array[String] = ["blue", "red", "green", "yellow", "white", "black"]
var cable_type_colors: Dictionary = {
	"blue": Color(0.38, 0.57, 0.95, 1.0),
	"red": Color(0.90, 0.36, 0.36, 1.0),
	"green": Color(0.34, 0.82, 0.45, 1.0),
	"yellow": Color(0.94, 0.83, 0.33, 1.0),
	"white": Color(0.90, 0.90, 0.90, 1.0),
	"black": Color(0.24, 0.24, 0.24, 1.0)
}

var current_round: int = 0
var score: int = 0
var round_time_left: float = 0.0
var pending_next_round: float = -1.0

var active_types: Array[String] = []
var selected_source_type: String = ""
var matched_count: int = 0
var expected_matches: int = 0

var source_buttons_by_type: Dictionary = {}
var target_buttons_by_type: Dictionary = {}

var is_round_locked: bool = false


func _ready() -> void:
	randomize()
	submit_button.pressed.connect(_on_submit_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
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
	for child in source_grid.get_children():
		child.queue_free()
	for child in target_grid.get_children():
		child.queue_free()

	source_buttons_by_type.clear()
	target_buttons_by_type.clear()

	var cable_count: int = min(6, 3 + round_number)
	active_types = cable_types.duplicate()
	active_types.shuffle()
	active_types = active_types.slice(0, cable_count)

	var shuffled_targets: Array[String] = active_types.duplicate()
	shuffled_targets.shuffle()
	while _is_same_order(active_types, shuffled_targets):
		shuffled_targets.shuffle()

	for cable_type in active_types:
		var source_btn := _create_cable_button(cable_type, true)
		source_grid.add_child(source_btn)
		source_buttons_by_type[cable_type] = source_btn

	for cable_type in shuffled_targets:
		var target_btn := _create_cable_button(cable_type, false)
		target_grid.add_child(target_btn)
		target_buttons_by_type[cable_type] = target_btn

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


func _create_cable_button(cable_type: String, is_source: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 58)
	button.toggle_mode = is_source
	button.text = _t("cable_" + cable_type)
	button.add_theme_font_size_override("font_size", 21)
	button.set_meta("cable_type", cable_type)
	button.set_meta("is_source", is_source)

	var normal := StyleBoxFlat.new()
	normal.bg_color = _get_button_normal_color(cable_type)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.18, 0.12, 0.08, 1.0)
	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_right = 7
	normal.corner_radius_bottom_left = 7

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = _get_button_pressed_color(cable_type)
	pressed.border_width_left = 2
	pressed.border_width_top = 2
	pressed.border_width_right = 2
	pressed.border_width_bottom = 2
	pressed.border_color = Color(0.18, 0.12, 0.08, 1.0)
	pressed.corner_radius_top_left = 7
	pressed.corner_radius_top_right = 7
	pressed.corner_radius_bottom_right = 7
	pressed.corner_radius_bottom_left = 7

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)

	if is_source:
		button.toggled.connect(_on_source_toggled.bind(button))
	else:
		button.pressed.connect(_on_target_pressed.bind(button))

	return button


func _get_button_normal_color(cable_type: String) -> Color:
	var base: Color = cable_type_colors.get(cable_type, Color(0.7, 0.7, 0.7, 1.0))
	return Color(base.r * 0.82, base.g * 0.82, base.b * 0.82, 1.0)


func _get_button_pressed_color(cable_type: String) -> Color:
	var base: Color = cable_type_colors.get(cable_type, Color(0.7, 0.7, 0.7, 1.0))
	return Color(min(1.0, base.r + 0.12), min(1.0, base.g + 0.12), min(1.0, base.b + 0.12), 1.0)


func _on_source_toggled(pressed: bool, button: Button) -> void:
	if is_round_locked:
		button.set_pressed_no_signal(false)
		return

	var this_type: String = String(button.get_meta("cable_type", ""))
	if pressed:
		selected_source_type = this_type
		for cable_type in source_buttons_by_type.keys():
			var src: Button = source_buttons_by_type[cable_type]
			if src != button:
				src.set_pressed_no_signal(false)
		selected_source_label.text = _t("selected_source") % [_t("cable_" + selected_source_type)]
	else:
		if selected_source_type == this_type:
			selected_source_type = ""
			selected_source_label.text = _t("selected_source_none")


func _on_target_pressed(button: Button) -> void:
	if is_round_locked:
		return
	if selected_source_type == "":
		return

	var target_type: String = String(button.get_meta("cable_type", ""))
	if target_type == selected_source_type:
		var src_btn: Button = source_buttons_by_type.get(selected_source_type)
		if src_btn != null:
			src_btn.disabled = true
			src_btn.set_pressed_no_signal(false)
		var tgt_btn: Button = target_buttons_by_type.get(target_type)
		if tgt_btn != null:
			tgt_btn.disabled = true

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
		var button := child as Button
		if button != null:
			button.disabled = true
	for child in target_grid.get_children():
		var button := child as Button
		if button != null:
			button.disabled = true

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
