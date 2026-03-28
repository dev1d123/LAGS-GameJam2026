extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_store_search"

@export var total_rounds: int = 5
@export var round_time_base: float = 20.0
@export var max_errors_per_round: int = 3

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
@onready var board_grid: GridContainer = $MainPanel/Margin/VBox/Content/CenterPanel/SearchField/BoardGrid
@onready var errors_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/Errors
@onready var found_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/Found
@onready var skip_button: Button = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SkipButton
@onready var round_result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

var item_types: Array[String] = ["milk", "bread", "soap", "battery", "soda", "cookies", "rice"]
var current_round: int = 0
var score: int = 0
var round_time_left: float = 0.0
var pending_next_round: float = -1.0

var target_item: String = ""
var errors_count: int = 0
var found_count: int = 0
var board_locked: bool = false


func _ready() -> void:
	randomize()
	skip_button.pressed.connect(_on_skip_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
	call_deferred("_start_round")


func _process(delta: float) -> void:
	if current_round <= 0:
		return

	if not board_locked:
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
	skip_button.text = _t("skip")
	finish_button.text = _t("finish")
	rounds_label.text = _t("rounds") % [0, total_rounds]
	timer_label.text = _t("timer") % [0.0]
	request_label.text = ""
	errors_label.text = _t("errors") % [0, max_errors_per_round]
	found_label.text = _t("found") % [0]
	round_result_label.text = ""
	round_result_label.visible = false
	finish_button.visible = false


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	board_locked = false
	round_result_label.visible = false
	skip_button.disabled = false
	errors_count = 0
	found_count = 0

	_build_round_board(current_round)

	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	round_time_left = max(9.0, round_time_base - float(current_round - 1) * 1.8)
	timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
	errors_label.text = _t("errors") % [errors_count, max_errors_per_round]
	found_label.text = _t("found") % [found_count]


func _build_round_board(round_number: int) -> void:
	for child in board_grid.get_children():
		child.queue_free()

	target_item = item_types[randi_range(0, item_types.size() - 1)]
	request_label.text = _t("request") % [_t("item_" + target_item)]

	var cell_count: int = min(30, 12 + round_number * 3)
	var target_index: int = randi_range(0, cell_count - 1)

	for i in cell_count:
		var item_type: String = target_item if i == target_index else item_types[randi_range(0, item_types.size() - 1)]
		var button := _create_item_button(item_type)
		board_grid.add_child(button)


func _create_item_button(item_type: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(105, 64)
	button.text = "?"
	button.add_theme_font_size_override("font_size", 22)
	button.set_meta("item_type", item_type)
	button.pressed.connect(_on_item_pressed.bind(button))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.42, 0.34, 0.22, 1.0)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.15, 0.09, 0.02, 1.0)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.67, 0.56, 0.35, 1.0)
	pressed.border_width_left = 2
	pressed.border_width_top = 2
	pressed.border_width_right = 2
	pressed.border_width_bottom = 2
	pressed.border_color = Color(0.15, 0.09, 0.02, 1.0)
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_right = 6
	pressed.corner_radius_bottom_left = 6

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	return button


func _on_item_pressed(button: Button) -> void:
	if board_locked:
		return
	if button.disabled:
		return

	button.disabled = true
	var item_type: String = String(button.get_meta("item_type", ""))
	button.text = _t("item_" + item_type)

	if item_type == target_item:
		found_count += 1
		found_label.text = _t("found") % [found_count]
		_resolve_round(true, "found")
	else:
		errors_count += 1
		errors_label.text = _t("errors") % [errors_count, max_errors_per_round]
		if errors_count >= max_errors_per_round:
			_resolve_round(false, "errors")


func _on_skip_button_pressed() -> void:
	if board_locked:
		return
	_resolve_round(false, "skip")


func _resolve_round(success: bool, reason: String) -> void:
	if board_locked:
		return

	board_locked = true
	skip_button.disabled = true

	for child in board_grid.get_children():
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
		elif reason == "errors":
			round_result_label.text = _t("too_many_errors")
		else:
			round_result_label.text = _t("incorrect")
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	pending_next_round = 0.9


func _finish_minigame() -> void:
	board_locked = true
	skip_button.disabled = true

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
