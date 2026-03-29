extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_store_search"
const STRESS_SHADER := preload("res://assets/shaders/stress_store_search.gdshader")
const STANDARD_UI_TEXT_COLOR := Color(0.687779, 0.643646, 0.632612, 1.0)

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
@onready var search_field: Control = $MainPanel/Margin/VBox/Content/CenterPanel/SearchField
@onready var board_grid: GridContainer = $MainPanel/Margin/VBox/Content/CenterPanel/SearchField/Center/BoardGridCenter
@onready var errors_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/Errors
@onready var found_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/Found
@onready var skip_button: Button = $MainPanel/Margin/VBox/Content/CenterPanel/ActionRow/SkipButton
@onready var round_result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

@onready var sfx_voltear: AudioStreamPlayer = $Audio/SFX_Voltear
@onready var sfx_fallo: AudioStreamPlayer = $Audio/SFX_Fallo
@onready var sfx_correcto: AudioStreamPlayer = $Audio/SFX_Correcto
@onready var sfx_ok_base: AudioStreamPlayer = $Audio/SFX_OkBase
@onready var sfx_error: AudioStreamPlayer = $Audio/SFX_Error
@onready var sfx_reloj: AudioStreamPlayer = $Audio/SFX_Reloj
var playing_reloj: bool = false

var item_types: Array[String] = ["aceite", "arroz", "harina", "huevos", "jabon", "leche", "pan", "pila", "soda", "tomates"]
var current_round: int = 0
var score: int = 0
var round_time_left: float = 0.0
var pending_next_round: float = -1.0
var memorization_time_left: float = 0.0
var desempeno: float = 0.0
var eficiencia: float = 0.0
var recompensa_total: int = 0
var estres: float = 0.0
var stress_difficulty: float = 0.0
var mission_money_min: int = 0
var mission_money_max: int = 0

var target_item: String = ""
var target_count: int = 1
var errors_count: int = 0
var found_count: int = 0
var board_locked: bool = false
var stress_fx_overlay: ColorRect
var stress_fx_material: ShaderMaterial
var stress_fx_time: float = 0.0


func _ready() -> void:
	randomize()
	_setup_stress_shader()
	skip_button.pressed.connect(_on_skip_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
	
	
	call_deferred("_start_round")


func _process(delta: float) -> void:
	_update_stress_shader(delta)
	if current_round <= 0:
		return

	var current_timer = 0.0
	if memorization_time_left > 0.0: current_timer = memorization_time_left
	elif not board_locked: current_timer = round_time_left
	
	if current_timer > 0.0 and current_timer <= 7.0:
		if not playing_reloj:
			playing_reloj = true
			sfx_reloj.play()
	else:
		if playing_reloj:
			playing_reloj = false
			sfx_reloj.stop()

	if memorization_time_left > 0.0:
		memorization_time_left -= delta
		if memorization_time_left <= 0.0:
			memorization_time_left = -1.0
			timer_label.text = "Memoriza: 0.0s"
			
			var flip_delay = 0.0
			for wrapper in board_grid.get_children():
				if is_instance_valid(wrapper):
					var btn = wrapper.get_node_or_null("Button")
					if btn:
						_flip_card(btn, false, true, flip_delay)
						flip_delay += 0.04
			
			get_tree().create_timer(flip_delay + 0.35).timeout.connect(func():
				if not is_instance_valid(self) or current_round <= 0: return
				board_locked = false
				skip_button.disabled = false
				instruction_label.text = _t("instruction")
				round_time_left = max(9.0, round_time_base - float(current_round - 1) * 1.8)
			)
		else:
			timer_label.text = "Memoriza: %ss" % snappedf(memorization_time_left, 0.1)
			
	elif not board_locked:
		round_time_left = max(0.0, round_time_left - delta)
		timer_label.text = _t("timer") % [snappedf(round_time_left, 0.1)]
		if round_time_left <= 0.0:
			_resolve_round(false, "timeout")
			return

	if pending_next_round >= 0.0:
		pending_next_round -= delta
		if pending_next_round <= 0.0:
			pending_next_round = -1.0
			_clear_board_animated(Callable(self, "_start_round"))


func _clear_board_animated(callback: Callable) -> void:
	var children = board_grid.get_children()
	if children.is_empty():
		callback.call()
		return
		
	var delay = 0.0
	var final_tween: Tween = null
	for wrapper in children:
		if is_instance_valid(wrapper):
			var btn = wrapper.get_node_or_null("Button")
			if btn:
				btn.pivot_offset = btn.size / 2.0
				var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				t.tween_interval(delay)
				t.tween_property(btn, "scale", Vector2.ZERO, 0.15)
				final_tween = t
			var lbl = wrapper.get_node_or_null("Label")
			if lbl:
				lbl.pivot_offset = lbl.size / 2.0
				var t2 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				t2.tween_interval(delay)
				t2.tween_property(lbl, "scale", Vector2.ZERO, 0.15)
			delay += 0.02
			
	if final_tween:
		final_tween.tween_interval(0.5)
		final_tween.tween_callback(callback)
	else:
		callback.call()

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
	_apply_standard_ui_colors()


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	board_locked = true
	skip_button.disabled = true
	round_result_label.visible = false
	errors_count = 0
	found_count = 0

	_build_round_board(current_round)

	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	errors_label.text = _t("errors") % [errors_count, max_errors_per_round]
	found_label.text = "Encontrados: %d / %d" % [found_count, target_count]
	
	instruction_label.text = _t("memorize_instruction") if _t("memorize_instruction") != "memorize_instruction" else "¡Memoriza el tablero!"

	memorization_time_left = -1.0
	timer_label.text = "Repartiendo..."
	
	await get_tree().process_frame
	
	var anim_delay = 0.0
	var last_tween: Tween = null
	for wrapper in board_grid.get_children():
		wrapper.modulate.a = 1.0
		var btn = wrapper.get_node_or_null("Button")
		if btn:
			btn.pivot_offset = btn.size / 2.0
			btn.scale = Vector2.ZERO
			var t1 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t1.tween_interval(anim_delay)
			t1.tween_property(btn, "scale", Vector2.ONE, 0.25)
			last_tween = t1
			
		var lbl = wrapper.get_node_or_null("Label")
		if lbl:
			lbl.pivot_offset = lbl.size / 2.0
			lbl.scale = Vector2.ZERO
			var t2 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t2.tween_interval(anim_delay)
			t2.tween_property(lbl, "scale", Vector2.ONE, 0.25)
			
		anim_delay += 0.03
		
	if last_tween:
		var mem_time = max(2.5, 6.0 - float(current_round) * 0.6)
		last_tween.tween_callback(func(): 
			if is_instance_valid(self):
				for w in board_grid.get_children():
					var b = w.get_node_or_null("Button")
					if b: _flip_card(b, true, true)
				
				get_tree().create_timer(0.35).timeout.connect(func():
					if is_instance_valid(self):
						memorization_time_left = mem_time
				)
		)
	else:
		memorization_time_left = max(2.5, 6.0 - float(current_round) * 0.6)


func _build_round_board(round_number: int) -> void:
	for child in board_grid.get_children():
		board_grid.remove_child(child)
		child.queue_free()

	target_item = item_types[randi_range(0, item_types.size() - 1)]
	
	var translated_target = _t("item_" + target_item)
	if translated_target == "item_" + target_item:
		translated_target = target_item.to_upper()

	var cell_count: int
	if round_number == 1: cell_count = 8
	elif round_number == 2: cell_count = 15
	elif round_number == 3: cell_count = 24
	elif round_number == 4: cell_count = 32
	else: cell_count = 40

	if round_number == 1: target_count = 2
	elif round_number == 2: target_count = 3
	elif round_number == 3: target_count = 4
	elif round_number == 4: target_count = 4
	else: target_count = 5

	request_label.text = "BUSCAR %d: %s" % [target_count, translated_target]

	if cell_count <= 8: board_grid.columns = 4
	elif cell_count <= 15: board_grid.columns = 5
	elif cell_count <= 24: board_grid.columns = 6
	else: board_grid.columns = 8

	var possible_fillers = item_types.duplicate()
	possible_fillers.erase(target_item)

	var target_indices: Array[int] = []
	var all_indices = range(cell_count)
	all_indices.shuffle()
	for i in range(target_count):
		target_indices.append(all_indices[i])

	for i in cell_count:
		var item_type: String = target_item if i in target_indices else possible_fillers[randi_range(0, possible_fillers.size() - 1)]
		
		var wrapper = preload("res://store_card.tscn").instantiate()
		wrapper.modulate.a = 0.0
		wrapper.show()
		
		var button: TextureButton = wrapper.get_node("Button")
		button.disabled = false # Forzamos activo al clonar
		button.set_meta("item_type", item_type)
		button.set_meta("is_flipped", false)
		
		var icon = button.get_node("Icon")
		icon.texture = load("res://assets/textures/minijuego-store-search/" + item_type + ".png")
		icon.modulate.a = 0.0
		
		var label = wrapper.get_node("Label")
		var translated_item = _t("item_" + item_type)
		if translated_item == "item_" + item_type:
			translated_item = item_type.to_upper()
		label.text = translated_item
		label.modulate.a = 0.0
		
		var bg = button.get_node("Background")
		bg.texture = load("res://assets/textures/minijuego-store-search/tarjeta_back.png")
		
		button.mouse_entered.connect(_on_card_hovered.bind(button, true))
		button.mouse_exited.connect(_on_card_hovered.bind(button, false))
		button.pressed.connect(_on_item_pressed.bind(button))
		
		board_grid.add_child(wrapper)


func _setup_stress_shader() -> void:
	var shader_host: Control = search_field if search_field != null else self
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
	var normalized := clampf((stress_difficulty - 20.0) / 80.0, 0.0, 1.0)
	return clampf(pow(normalized, 1.15) * 1.8, 0.0, 1.8)



func _flip_card(button: TextureButton, face_up: bool, animate: bool = true, delay: float = 0.0) -> void:
	if not is_instance_valid(button): return
	button.set_meta("is_flipped", face_up)
	sfx_voltear.play()
	if button.size.x > 0:
		button.pivot_offset = button.size / 2.0
	var bg = button.get_node_or_null("Background")
	var icon = button.get_node_or_null("Icon")
	var label = button.get_parent().get_node_or_null("Label")
	
	var path_front = "res://assets/textures/minijuego-store-search/tarjeta_front.png"
	var path_back = "res://assets/textures/minijuego-store-search/tarjeta_back.png"
	
	if animate:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if delay > 0: tween.tween_interval(delay)
		tween.tween_property(button, "scale:x", 0.0, 0.15)
		tween.tween_callback(func():
			if is_instance_valid(bg):
				bg.texture = load(path_front) if face_up else load(path_back)
				icon.modulate.a = 1.0 if face_up else 0.0
				label.modulate.a = 1.0 if face_up else 0.0
		)
		tween.tween_property(button, "scale:x", 1.0, 0.15)
	else:
		if is_instance_valid(bg):
			bg.texture = load(path_front) if face_up else load(path_back)
			icon.modulate.a = 1.0 if face_up else 0.0
			label.modulate.a = 1.0 if face_up else 0.0


func _on_card_hovered(button: TextureButton, entered: bool) -> void:
	if board_locked or button.get_meta("is_flipped", false):
		if is_instance_valid(button):
			create_tween().tween_property(button, "position:y", 0.0, 0.1)
			button.self_modulate = Color(1, 1, 1, 1)
		return
		
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if entered:
		tween.tween_property(button, "position:y", -8.0, 0.1)
		button.self_modulate = Color(1.2, 1.2, 1.2, 1.0)
	else:
		tween.tween_property(button, "position:y", 0.0, 0.1)
		button.self_modulate = Color(1, 1, 1, 1)


func _on_item_pressed(button: TextureButton) -> void:
	if board_locked or button.get_meta("is_flipped", false):
		return

	var item_type: String = String(button.get_meta("item_type", ""))

	if item_type == target_item:
		_flip_card(button, true, true)
		
		# Efecto de victoria en la carta correcta
		var t = create_tween().set_trans(Tween.TRANS_ELASTIC)
		t.tween_property(button, "scale", Vector2(1.2, 1.2), 0.3)
		t.tween_property(button, "scale", Vector2(1.0, 1.0), 0.3)
		
		found_count += 1
		found_label.text = "Encontrados: %d / %d" % [found_count, target_count]
		sfx_correcto.play()
		
		if found_count >= target_count:
			board_locked = true
			t.tween_callback(func(): _resolve_round(true, "found"))
	else:
		_flip_card(button, true, true)
		
		# Temblor y tinte rojo por error
		var t = create_tween()
		t.tween_property(button, "rotation_degrees", 10.0, 0.05)
		t.tween_property(button, "rotation_degrees", -10.0, 0.05)
		t.tween_property(button, "rotation_degrees", 5.0, 0.05)
		t.tween_property(button, "rotation_degrees", 0.0, 0.05)
		button.self_modulate = Color(1.5, 0.5, 0.5, 1.0)
		sfx_fallo.play()
		
		errors_count += 1
		errors_label.text = _t("errors") % [errors_count, max_errors_per_round]
		if errors_count >= max_errors_per_round:
			_resolve_round(false, "errors")


func _on_skip_button_pressed() -> void:
	if board_locked:
		return
	_resolve_round(false, "skip")


func _resolve_round(success: bool, reason: String) -> void:
	if pending_next_round >= 0.0:
		return

	if playing_reloj:
		playing_reloj = false
		sfx_reloj.stop()

	board_locked = true
	skip_button.disabled = true

	for wrapper in board_grid.get_children():
		var button := wrapper.get_node_or_null("Button") as TextureButton
		if button != null:
			button.disabled = true

	if success:
		score += 1
		sfx_ok_base.play()
		round_result_label.text = _t("correct")
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		sfx_error.play()
		if reason == "timeout":
			round_result_label.text = _t("timeout")
		elif reason == "errors":
			round_result_label.text = _t("too_many_errors")
		else:
			round_result_label.text = _t("incorrect")
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	pending_next_round = 1.8


func _finish_minigame() -> void:
	board_locked = true
	if playing_reloj:
		playing_reloj = false
		sfx_reloj.stop()

	skip_button.disabled = true
	memorization_time_left = -1.0

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
	for label in [guide_title_label, guide1_label, guide2_label, guide3_label, objectives_title_label, rounds_label, instruction_label, results_title_label, round_result_label, errors_label, found_label]:
		if label != null:
			label.add_theme_color_override("font_color", STANDARD_UI_TEXT_COLOR)


func _calc_recompensa_from_eficiencia() -> int:
	var min_money: int = mission_money_min
	var max_money: int = max(mission_money_min, mission_money_max)
	return int(round(lerpf(float(min_money), float(max_money), clamp(eficiencia / 100.0, 0.0, 1.0))))




func _t(key: String) -> String:
	return LocaleManager.get_text(I18N_CATEGORY, key)
