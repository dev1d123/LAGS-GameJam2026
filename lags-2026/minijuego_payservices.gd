extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_payservices"
const BILL_FONT := preload("res://assets/fonts/PixelOperatorMonoHB.ttf")

@export var total_rounds: int = 5
@export var options_per_round: int = 3
@export var fall_speed: float = 180.0
@export var round_time_limit: float = 9.0

@onready var title_label: Button = $MainPanel/Margin/VBox/TitleSlot/Title
@onready var guide_title_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/GuideTitle/GuideTitleLabel
@onready var guide1_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide1/Guide1Label
@onready var guide2_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide2/Guide2Label
@onready var guide3_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide3/Guide3Label
@onready var objectives_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesTitle/ObjectivesTitleLabel
@onready var rounds_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Rounds
@onready var instruction_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Instruction
@onready var results_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsTitle/ResultsTitleLabel
@onready var client_request_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ClientRequest
@onready var timer_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/Timer
@onready var bills_area: Control = $MainPanel/Margin/VBox/Content/CenterPanel/BillsContainer/BillsArea
@onready var result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

var providers: Array[String] = [
	"Energia Norte",
	"Aguas del Barrio",
	"Internet Plus",
	"Gas Hogar",
	"Telefono Sur"
]

var clients: Array[String] = [
	"Dona Rosa",
	"Don Julio",
	"Ana",
	"Kevin",
	"Juanito",
	"Dona Carmen"
]

var current_round: int = 0
var score: int = 0
var round_time_left: float = 0.0
var round_locked: bool = false
var pending_next_round: float = -1.0

var current_target_id: String = ""
var current_target_text: String = ""
var active_bill_buttons: Array[Button] = []

func _ready() -> void:
	randomize()
	finish_button.visible = false
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
	call_deferred("_start_round")


func _process(delta: float) -> void:
	if current_round <= 0:
		return

	if not round_locked:
		round_time_left = max(0.0, round_time_left - delta)
		timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
		_update_falling_bills(delta)
		if round_time_left <= 0.0:
			_resolve_round(false, -1)

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
	finish_button.text = _t("finish")
	rounds_label.text = _t("rounds") % [0, total_rounds]
	timer_label.text = _t("timer") % [round_time_limit]
	result_label.text = ""
	result_label.visible = false


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	round_time_left = round_time_limit
	round_locked = false
	result_label.visible = false
	_clear_bills()

	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]

	var target_bill: Dictionary = _make_bill_data()
	current_target_id = target_bill["id"]
	current_target_text = _bill_description(target_bill)

	var all_bills: Array[Dictionary] = [target_bill]
	while all_bills.size() < options_per_round:
		var candidate: Dictionary = _make_bill_data()
		if _contains_bill_id(all_bills, candidate["id"]):
			continue
		all_bills.append(candidate)

	all_bills.shuffle()
	_spawn_falling_bills(all_bills)

	var client_name: String = clients[randi_range(0, clients.size() - 1)]
	client_request_label.text = _t("client_request") % [client_name, current_target_text]


func _make_bill_data() -> Dictionary:
	var provider: String = providers[randi_range(0, providers.size() - 1)]
	var amount: int = randi_range(20, 300)
	var reference: String = str(randi_range(100000, 999999))
	var due_day: int = randi_range(1, 28)
	var id: String = "%s|%s|%d|%d" % [provider, reference, amount, due_day]

	return {
		"id": id,
		"provider": provider,
		"reference": reference,
		"amount": amount,
		"due_day": due_day
	}


func _spawn_falling_bills(bills: Array[Dictionary]) -> void:
	active_bill_buttons.clear()
	if bills_area.size.x < 10.0:
		await get_tree().process_frame
		await get_tree().process_frame

	var area_w: float = bills_area.size.x
	if area_w < 10.0:
		area_w = 960.0

	var count: int = bills.size()
	var side_padding: float = 16.0
	var gap: float = 12.0
	var available_w: float = max(0.0, area_w - side_padding * 2.0)
	var computed_btn_w: float = (available_w - gap * float(max(0, count - 1))) / float(max(1, count))
	var btn_w: float = clampf(computed_btn_w, 220.0, 320.0)
	var slot_w: float = btn_w + gap
	var total_w: float = slot_w * float(count) - gap
	var start_x: float = max(0.0, (area_w - total_w) * 0.5)

	for i in range(bills.size()):
		var bill: Dictionary = bills[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(btn_w, 156)
		btn.size = Vector2(btn_w, 156)
		var x_pos := start_x + slot_w * float(i)
		btn.position = Vector2(x_pos, -btn.size.y - randi_range(0, 90))
		btn.text = _bill_button_text(bill)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_override("font", BILL_FONT)
		btn.add_theme_font_size_override("font_size", 23)
		btn.add_theme_constant_override("h_separation", 12)
		btn.add_theme_constant_override("outline_size", 6)
		btn.add_theme_color_override("font_color", Color(0.687779, 0.643646, 0.632612, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.687779, 0.643646, 0.632612, 1))
		btn.add_theme_color_override("font_hover_color", Color(0.687779, 0.643646, 0.632612, 1))
		btn.add_theme_color_override("font_outline_color", Color(0.189829, 0.0827736, 0.0013467, 1))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.set_meta("bill_id", bill["id"])
		btn.pressed.connect(func(): _on_bill_selected(btn))
		bills_area.add_child(btn)
		active_bill_buttons.append(btn)


func _bill_button_text(bill: Dictionary) -> String:
	return "%s\n%s: %s\n%s: $%d\n%s: %02d" % [
		bill["provider"],
		_t("ref"), bill["reference"],
		_t("amount"), int(bill["amount"]),
		_t("due"), int(bill["due_day"])
	]


func _bill_description(bill: Dictionary) -> String:
	return "%s (%s %s, %s $%d, %s %02d)" % [
		bill["provider"],
		_t("ref"), bill["reference"],
		_t("amount"), int(bill["amount"]),
		_t("due"), int(bill["due_day"])
	]


func _contains_bill_id(list: Array[Dictionary], id: String) -> bool:
	for item in list:
		if item["id"] == id:
			return true
	return false


func _update_falling_bills(delta: float) -> void:
	var area_h: float = bills_area.size.y
	for btn in active_bill_buttons:
		if not is_instance_valid(btn):
			continue
		btn.position.y += fall_speed * delta
		if btn.position.y > area_h + 10.0:
			_resolve_round(false, -1)
			return


func _on_bill_selected(btn: Button) -> void:
	if round_locked:
		return

	var selected_id: String = str(btn.get_meta("bill_id"))
	var is_correct: bool = selected_id == current_target_id
	var selected_index: int = active_bill_buttons.find(btn)
	_resolve_round(is_correct, selected_index)


func _resolve_round(is_correct: bool, selected_index: int) -> void:
	if round_locked:
		return

	round_locked = true
	if is_correct:
		score += 1

	for i in range(active_bill_buttons.size()):
		var btn: Button = active_bill_buttons[i]
		if not is_instance_valid(btn):
			continue
		btn.disabled = true
		var bill_id: String = str(btn.get_meta("bill_id"))
		if bill_id == current_target_id:
			btn.modulate = Color(0.55, 1.0, 0.55, 1.0)
		elif i == selected_index:
			btn.modulate = Color(1.0, 0.55, 0.55, 1.0)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85, 1.0)

	result_label.visible = true
	result_label.text = _t("correct") if is_correct else _t("incorrect")
	pending_next_round = 0.9


func _finish_minigame() -> void:
	_clear_bills()
	round_locked = true
	result_label.visible = true

	var success: bool = score >= int(ceil(float(total_rounds) * 0.6))
	if success:
		result_label.text = _t("final_success") % [score, total_rounds]
	else:
		result_label.text = _t("final_fail") % [score, total_rounds]

	finish_button.visible = true
	emit_signal("minigame_finished", success, score, total_rounds)


func _on_finish_button_pressed() -> void:
	queue_free()


func _clear_bills() -> void:
	for btn in active_bill_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	active_bill_buttons.clear()


func _t(key: String) -> String:
	return LocaleManager.get_text(I18N_CATEGORY, key)
