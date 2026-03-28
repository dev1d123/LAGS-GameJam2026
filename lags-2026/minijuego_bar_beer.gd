extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_bar_beer"

@export var total_rounds: int = 5
@export var hit_tolerance: float = 0.07

@onready var title_label: Button = $MainPanel/Margin/VBox/TitleSlot/Title
@onready var guide_title_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/GuideTitle/GuideTitleLabel
@onready var guide1_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide1/Guide1Label
@onready var guide2_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide2/Guide2Label
@onready var guide3_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide3/Guide3Label
@onready var objectives_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesTitle/ObjectivesTitleLabel
@onready var rounds_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Rounds
@onready var instruction_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Instruction
@onready var results_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsTitle/ResultsTitleLabel
@onready var request_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ClientRequest
@onready var timer_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/Timer
@onready var glass_fill: ColorRect = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass/GlassBody/FillRect
@onready var target_line: ColorRect = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass/GlassBody/TargetLine
@onready var handle_button: Button = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass/HandleButton
@onready var round_result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

var current_round: int = 0
var score: int = 0
var round_time_left: float = 0.0
var pending_next_round: float = -1.0

var target_fill: float = 0.5
var fill_level: float = 0.0
var fill_speed: float = 0.2

var is_round_locked: bool = false
var is_pouring: bool = false


func _ready() -> void:
	randomize()
	handle_button.button_down.connect(_on_handle_button_down)
	handle_button.button_up.connect(_on_handle_button_up)
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
	call_deferred("_start_round")


func _process(delta: float) -> void:
	if current_round <= 0:
		return

	if not is_round_locked:
		round_time_left = max(0.0, round_time_left - delta)
		timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]

		if is_pouring:
			fill_level = clampf(fill_level + fill_speed * delta, 0.0, 1.0)
			_update_glass_visual()
			if fill_level >= 1.0:
				_resolve_round(false, "overfill")
				return

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
	handle_button.text = _t("hold")
	finish_button.text = _t("finish")
	rounds_label.text = _t("rounds") % [0, total_rounds]
	timer_label.text = _t("timer") % [0.0]
	request_label.text = ""
	round_result_label.text = ""
	round_result_label.visible = false
	finish_button.visible = false


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	is_round_locked = false
	is_pouring = false
	round_result_label.visible = false
	handle_button.disabled = false

	fill_level = 0.0
	target_fill = randf_range(0.35, 0.9)

	var expected_seconds: float = randf_range(3.0, 10.0)
	fill_speed = 1.0 / expected_seconds
	round_time_left = expected_seconds + 2.0

	request_label.text = _t("client_request") % [int(round(target_fill * 100.0))]
	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
	_update_glass_visual()


func _update_glass_visual() -> void:
	var body_h: float = 250.0
	var fill_h: float = body_h * fill_level
	glass_fill.offset_top = body_h - fill_h

	var target_y: float = body_h * (1.0 - target_fill)
	target_line.offset_top = target_y - 2.0
	target_line.offset_bottom = target_y + 2.0


func _on_handle_button_down() -> void:
	if is_round_locked:
		return
	is_pouring = true


func _on_handle_button_up() -> void:
	if is_round_locked:
		return
	if not is_pouring:
		return

	is_pouring = false
	var diff: float = absf(fill_level - target_fill)
	var success: bool = diff <= hit_tolerance
	_resolve_round(success, "released")


func _resolve_round(success: bool, reason: String) -> void:
	if is_round_locked:
		return

	is_round_locked = true
	is_pouring = false
	handle_button.disabled = true

	if success:
		score += 1
		round_result_label.text = _t("correct")
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		if reason == "timeout":
			round_result_label.text = _t("timeout")
		elif reason == "overfill":
			round_result_label.text = _t("overfill")
		else:
			round_result_label.text = _t("incorrect")
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	pending_next_round = 0.9


func _finish_minigame() -> void:
	is_round_locked = true
	is_pouring = false
	handle_button.disabled = true

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
