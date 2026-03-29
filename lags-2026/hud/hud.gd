extends Control

# Referencias a nodos
@onready var stress_bar = $StressProgressBar
@onready var energy_bar = $EnergyProgressBar

@onready var label_dinero = $PanelDinero/LabelDinero
@onready var label_dia = $"PanelDía"/LabelDia
@onready var label_hora = $PanelHora/LabelHora
@onready var label_perdidos = $PanelPerdidos/LabelPerdidos
@onready var inventory_title = $InventoryPanel/InventoryTitle
@onready var slot_cola: Button = $InventoryPanel/SlotsRow/SlotCola
@onready var slot_leche: Button = $InventoryPanel/SlotsRow/SlotLeche
@onready var slot_caramelo: Button = $InventoryPanel/SlotsRow/SlotCaramelo
@onready var sfx_inventory_click: AudioStreamPlayer = $InventorySfxClick

# Variables de estado
var dinero: int = 0
var dia: int = 1
var max_dias: int = 4

var hora: int = 8
var perdidos: int = 0

const LOST_LIMITS_BY_DAY := {
	1: 4,
	2: 5,
	3: 6,
	4: 7,
}
const STRESS_PER_EXCESS_LOST: float = 6.0
const MONEY_BAD_THRESHOLD: int = 3000
const MONEY_GOOD_THRESHOLD: int = 5000
const MONEY_COLOR_BAD := Color(0.62, 0.62, 0.62, 1.0)
const MONEY_COLOR_NORMAL := Color(0.95, 0.84, 0.30, 1.0)
const MONEY_COLOR_GOOD := Color(0.47, 0.88, 0.46, 1.0)
const COLA_ENERGY_PERCENT: float = 30.0
const LECHE_STRESS_REDUCE: float = 20.0
const CARAMELO_SPEED_MULTIPLIER: float = 1.35
const CARAMELO_DURATION_SECONDS: float = 10.0

var cola_available: bool = true
var leche_available: bool = true
var caramelo_available: bool = true
var speed_boost_active: bool = false
var speed_boost_time_left: float = 0.0

# Idioma
var lang := "es"
	
# Control input
var cooldown := 0.2
var timer := 0.0

func _ready() -> void:
	add_to_group("hud")
	add_to_group("translatable")
	lang = LocaleManager.current_language
	_prepare_money_label_style()
	_connect_inventory_ui()
	_reset_inventory_for_new_day()
	actualizar_todo()


func update_translation() -> void:
	lang = LocaleManager.current_language
	_refrescar_labels_sin_animacion()
	_update_inventory_labels()

func _process(delta: float) -> void:
	if speed_boost_active:
		speed_boost_time_left = maxf(0.0, speed_boost_time_left - delta)
		if speed_boost_time_left <= 0.0:
			speed_boost_active = false

	timer -= delta

	if timer <= 0:
		if Input.is_key_pressed(KEY_1):
			test_dinero()
			timer = cooldown

		elif Input.is_key_pressed(KEY_2):
			test_dia()
			timer = cooldown

		elif Input.is_key_pressed(KEY_3):
			test_hora()
			timer = cooldown

		elif Input.is_key_pressed(KEY_4):
			test_perdidos()
			timer = cooldown

		elif Input.is_key_pressed(KEY_5):
			test_stress_down()
			timer = cooldown

		elif Input.is_key_pressed(KEY_6):
			test_stress_up()
			timer = cooldown

		elif Input.is_key_pressed(KEY_7):
			test_energy_down()
			timer = cooldown

		elif Input.is_key_pressed(KEY_8):
			test_energy_up()
			timer = cooldown

# =========================
# ANIMACIÓN UI
# =========================

func animar_ui(nodo: Control):
	var original_pos = nodo.position
	var original_scale = nodo.scale

	var tween = create_tween()
	tween.set_parallel(true)

	# Escala tipo "pop"
	tween.tween_property(nodo, "scale", original_scale * 1.1, 0.1)
	tween.tween_property(nodo, "scale", original_scale, 0.1).set_delay(0.1)

	# Vibración (shake)
	tween.tween_property(nodo, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(nodo, "position", original_pos + Vector2(-5, 0), 0.05).set_delay(0.05)
	tween.tween_property(nodo, "position", original_pos, 0.05).set_delay(0.1)

# =========================
# ACTUALIZACIONES
# =========================

func actualizar_dinero(cantidad: int):
	dinero += cantidad

	match lang:
		"es":
			label_dinero.text = "Dinero: %d" % dinero
		"en":
			label_dinero.text = "Money: %d" % dinero
		"pt":
			label_dinero.text = "Dinheiro: %d" % dinero
		_:
			label_dinero.text = str(dinero)

	_apply_money_color()

	animar_ui(label_dinero)

func actualizar_dia(cantidad: int):
	dia += cantidad

	if dia > max_dias:
		dia = 1
	elif dia < 1:
		dia = max_dias

	match lang:
		"es":
			label_dia.text = "Día %d/%d" % [dia, max_dias]
		"en":
			label_dia.text = "Day %d/%d" % [dia, max_dias]
		"pt":
			label_dia.text = "Dia %d/%d" % [dia, max_dias]

	animar_ui(label_dia)


func set_dia(valor: int) -> void:
	var previous_day: int = dia
	dia = valor
	if dia > max_dias:
		dia = ((dia - 1) % max_dias) + 1
	elif dia < 1:
		dia = max_dias

	if dia != previous_day:
		perdidos = 0
		_reset_inventory_for_new_day()

	match lang:
		"es":
			label_dia.text = "Día %d/%d" % [dia, max_dias]
		"en":
			label_dia.text = "Day %d/%d" % [dia, max_dias]
		"pt":
			label_dia.text = "Dia %d/%d" % [dia, max_dias]

	_update_perdidos_label()

	animar_ui(label_dia)

func actualizar_hora(cantidad: int):
	hora += cantidad

	if hora >= 24:
		hora = 0
	elif hora < 0:
		hora = 23

	var periodo = "AM"
	var hora_mostrar = hora

	if hora >= 12:
		periodo = "PM"
		if hora > 12:
			hora_mostrar = hora - 12
	if hora == 0:
		hora_mostrar = 12

	match lang:
		"es":
			label_hora.text = "Hora %d %s" % [hora_mostrar, periodo]
		"en":
			label_hora.text = "Time %d %s" % [hora_mostrar, periodo]
		"pt":
			label_hora.text = "Hora %d %s" % [hora_mostrar, periodo]

	animar_ui(label_hora)


func set_hora(valor: int) -> void:
	hora = wrapi(valor, 0, 24)

	var periodo = "AM"
	var hora_mostrar = hora

	if hora >= 12:
		periodo = "PM"
		if hora > 12:
			hora_mostrar = hora - 12
	if hora == 0:
		hora_mostrar = 12

	match lang:
		"es":
			label_hora.text = "Hora %d %s" % [hora_mostrar, periodo]
		"en":
			label_hora.text = "Time %d %s" % [hora_mostrar, periodo]
		"pt":
			label_hora.text = "Hora %d %s" % [hora_mostrar, periodo]

	animar_ui(label_hora)

func actualizar_perdidos(cantidad: int):
	var prev_perdidos := perdidos
	perdidos += cantidad

	_apply_excess_lost_stress(prev_perdidos, perdidos)
	_update_perdidos_label()

	animar_ui(label_perdidos)

func actualizar_stress(cantidad: float):
	stress_bar.value = clamp(stress_bar.value + cantidad, 0, stress_bar.max_value)
	animar_ui(stress_bar)

func actualizar_energy(cantidad: float):
	energy_bar.value = clamp(energy_bar.value + cantidad, 0, energy_bar.max_value)
	animar_ui(energy_bar)


func iniciar_dia_stats() -> void:
	# Cada inicio de dia: energia al 100%.
	energy_bar.value = energy_bar.max_value
	animar_ui(energy_bar)

	# El estres no se recalcula por arrastre de perdidos entre dias.
	stress_bar.value = clamp(float(stress_bar.value), 0.0, float(stress_bar.max_value))
	animar_ui(stress_bar)


func consumir_energia_mision(coste_percent: float = 20.0) -> void:
	var max_energy: float = float(energy_bar.max_value)
	var delta: float = -(max_energy * (coste_percent / 100.0))
	energy_bar.value = clamp(float(energy_bar.value) + delta, 0.0, max_energy)
	animar_ui(energy_bar)


func get_energy_percent() -> float:
	var max_energy: float = float(energy_bar.max_value)
	if max_energy <= 0.0:
		return 0.0
	return clamp((float(energy_bar.value) / max_energy) * 100.0, 0.0, 100.0)


func get_stress_percent() -> float:
	var max_stress: float = float(stress_bar.max_value)
	if max_stress <= 0.0:
		return 0.0
	return clamp((float(stress_bar.value) / max_stress) * 100.0, 0.0, 100.0)

# =========================
# REFRESH
# =========================

func actualizar_todo():
	actualizar_dinero(0)
	actualizar_dia(0)
	actualizar_hora(0)
	actualizar_perdidos(0)


func _refrescar_labels_sin_animacion() -> void:
	match lang:
		"es":
			label_dinero.text = "Dinero: %d" % dinero
			label_dia.text = "Día %d/%d" % [dia, max_dias]
			label_perdidos.text = "Perdidos: %d/%d" % [perdidos, _get_lost_limit_for_day(dia)]
		"en":
			label_dinero.text = "Money: %d" % dinero
			label_dia.text = "Day %d/%d" % [dia, max_dias]
			label_perdidos.text = "Missed: %d/%d" % [perdidos, _get_lost_limit_for_day(dia)]
		"pt":
			label_dinero.text = "Dinheiro: %d" % dinero
			label_dia.text = "Dia %d/%d" % [dia, max_dias]
			label_perdidos.text = "Perdidos: %d/%d" % [perdidos, _get_lost_limit_for_day(dia)]
		_:
			label_dinero.text = str(dinero)
			label_dia.text = "Día %d/%d" % [dia, max_dias]
			label_perdidos.text = "Perdidos: %d/%d" % [perdidos, _get_lost_limit_for_day(dia)]

	_apply_money_color()

	var periodo = "AM"
	var hora_mostrar = hora
	if hora >= 12:
		periodo = "PM"
		if hora > 12:
			hora_mostrar = hora - 12
	if hora == 0:
		hora_mostrar = 12

	match lang:
		"es":
			label_hora.text = "Hora %d %s" % [hora_mostrar, periodo]
		"en":
			label_hora.text = "Time %d %s" % [hora_mostrar, periodo]
		"pt":
			label_hora.text = "Hora %d %s" % [hora_mostrar, periodo]
		_:
			label_hora.text = "Hora %d %s" % [hora_mostrar, periodo]


func _get_lost_limit_for_day(day_value: int) -> int:
	if LOST_LIMITS_BY_DAY.has(day_value):
		return int(LOST_LIMITS_BY_DAY[day_value])
	return int(LOST_LIMITS_BY_DAY[max_dias])


func _update_perdidos_label() -> void:
	var limit: int = _get_lost_limit_for_day(dia)
	match lang:
		"es":
			label_perdidos.text = "Perdidos: %d/%d" % [perdidos, limit]
		"en":
			label_perdidos.text = "Missed: %d/%d" % [perdidos, limit]
		"pt":
			label_perdidos.text = "Perdidos: %d/%d" % [perdidos, limit]
		_:
			label_perdidos.text = "Perdidos: %d/%d" % [perdidos, limit]


func _apply_excess_lost_stress(prev_lost: int, new_lost: int) -> void:
	if new_lost <= prev_lost:
		return
	var limit: int = _get_lost_limit_for_day(dia)
	var prev_excess: int = maxi(0, prev_lost - limit)
	var new_excess: int = maxi(0, new_lost - limit)
	var newly_exceeded: int = maxi(0, new_excess - prev_excess)
	if newly_exceeded > 0:
		actualizar_stress(float(newly_exceeded) * STRESS_PER_EXCESS_LOST)


func _apply_money_color() -> void:
	var money_color: Color = MONEY_COLOR_NORMAL
	if dinero <= MONEY_BAD_THRESHOLD:
		money_color = MONEY_COLOR_BAD
	elif dinero >= MONEY_GOOD_THRESHOLD:
		money_color = MONEY_COLOR_GOOD
	label_dinero.add_theme_color_override("font_color", money_color)
	label_dinero.self_modulate = money_color
	if label_dinero.label_settings != null:
		label_dinero.label_settings.font_color = money_color


func _prepare_money_label_style() -> void:
	if label_dinero == null:
		return
	if label_dinero.label_settings != null:
		label_dinero.label_settings = label_dinero.label_settings.duplicate(true)


func _connect_inventory_ui() -> void:
	if slot_cola != null and not slot_cola.pressed.is_connected(_on_slot_cola_pressed):
		slot_cola.pressed.connect(_on_slot_cola_pressed)
	if slot_leche != null and not slot_leche.pressed.is_connected(_on_slot_leche_pressed):
		slot_leche.pressed.connect(_on_slot_leche_pressed)
	if slot_caramelo != null and not slot_caramelo.pressed.is_connected(_on_slot_caramelo_pressed):
		slot_caramelo.pressed.connect(_on_slot_caramelo_pressed)


func _reset_inventory_for_new_day() -> void:
	cola_available = true
	leche_available = true
	caramelo_available = true
	speed_boost_active = false
	speed_boost_time_left = 0.0
	_refresh_inventory_slots()


func _update_inventory_labels() -> void:
	if inventory_title != null:
		match lang:
			"en":
				inventory_title.text = "ITEMS"
			"pt":
				inventory_title.text = "ITENS"
			_:
				inventory_title.text = "OBJ"

	if slot_cola != null:
		slot_cola.text = ""
		match lang:
			"en":
				slot_cola.tooltip_text = "Cola: restore energy"
			"pt":
				slot_cola.tooltip_text = "Refrigerante: aumenta energia"
			_:
				slot_cola.tooltip_text = "Refrigerante: aumenta energía"
	if slot_leche != null:
		slot_leche.text = ""
		match lang:
			"en":
				slot_leche.tooltip_text = "Milk: reduce stress"
			"pt":
				slot_leche.tooltip_text = "Leite: reduz estresse"
			_:
				slot_leche.tooltip_text = "Leche: reduce estrés"
	if slot_caramelo != null:
		slot_caramelo.text = ""
		match lang:
			"en":
				slot_caramelo.tooltip_text = "Candy: speed boost"
			"pt":
				slot_caramelo.tooltip_text = "Caramelo: aumenta velocidade"
			_:
				slot_caramelo.tooltip_text = "Caramelo: aumenta velocidad"


func _refresh_inventory_slots() -> void:
	_update_inventory_labels()
	_apply_slot_state(slot_cola, cola_available)
	_apply_slot_state(slot_leche, leche_available)
	_apply_slot_state(slot_caramelo, caramelo_available)


func _apply_slot_state(slot: Button, is_available: bool) -> void:
	if slot == null:
		return
	slot.disabled = not is_available
	slot.self_modulate = Color(1, 1, 1, 1) if is_available else Color(0.35, 0.35, 0.35, 1)


func _play_inventory_sfx(pitch: float = 1.0) -> void:
	if sfx_inventory_click == null:
		return
	sfx_inventory_click.pitch_scale = pitch
	sfx_inventory_click.play()


func _on_slot_cola_pressed() -> void:
	if not cola_available:
		_play_inventory_sfx(0.85)
		return
	cola_available = false
	_play_inventory_sfx(1.0)
	var gain := float(energy_bar.max_value) * (COLA_ENERGY_PERCENT / 100.0)
	actualizar_energy(gain)
	animar_ui(slot_cola)
	_refresh_inventory_slots()


func _on_slot_leche_pressed() -> void:
	if not leche_available:
		_play_inventory_sfx(0.85)
		return
	leche_available = false
	_play_inventory_sfx(1.0)
	actualizar_stress(-LECHE_STRESS_REDUCE)
	animar_ui(slot_leche)
	_refresh_inventory_slots()


func _on_slot_caramelo_pressed() -> void:
	if not caramelo_available:
		_play_inventory_sfx(0.85)
		return
	caramelo_available = false
	speed_boost_active = true
	speed_boost_time_left = CARAMELO_DURATION_SECONDS
	_play_inventory_sfx(1.1)
	animar_ui(slot_caramelo)
	_refresh_inventory_slots()


func get_speed_multiplier() -> float:
	return CARAMELO_SPEED_MULTIPLIER if speed_boost_active else 1.0

# =========================
# TEST
# =========================

func test_dinero():
	actualizar_dinero(10)

func test_dia():
	actualizar_dia(1)

func test_hora():
	actualizar_hora(1)

func test_perdidos():
	actualizar_perdidos(1)

func test_stress_down():
	actualizar_stress(-10)

func test_stress_up():
	actualizar_stress(10)

func test_energy_down():
	actualizar_energy(-10)

func test_energy_up():
	actualizar_energy(10)
	
