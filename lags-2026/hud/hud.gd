extends Control

# Referencias a nodos
@onready var stress_bar = $StressProgressBar
@onready var energy_bar = $EnergyProgressBar

@onready var label_dinero = $PanelDinero/LabelDinero
@onready var label_dia = $"PanelDía"/LabelDia
@onready var label_hora = $PanelHora/LabelHora
@onready var label_perdidos = $PanelPerdidos/LabelPerdidos

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
	actualizar_todo()


func update_translation() -> void:
	lang = LocaleManager.current_language
	_refrescar_labels_sin_animacion()

func _process(delta: float) -> void:
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
	
