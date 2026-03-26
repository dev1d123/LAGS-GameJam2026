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

# Idioma
var lang := "es"

# Control input
var cooldown := 0.2
var timer := 0.0

func _ready() -> void:
	lang = LocaleManager.current_language
	actualizar_todo()

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
			test_stress()
			timer = cooldown

		elif Input.is_key_pressed(KEY_6):
			test_energy()
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

func actualizar_perdidos(cantidad: int):
	perdidos += cantidad

	match lang:
		"es":
			label_perdidos.text = "Perdidos: %d" % perdidos
		"en":
			label_perdidos.text = "Missed: %d" % perdidos
		"pt":
			label_perdidos.text = "Perdidos: %d" % perdidos

	animar_ui(label_perdidos)

func actualizar_stress(cantidad: float):
	stress_bar.value = clamp(stress_bar.value + cantidad, 0, stress_bar.max_value)
	animar_ui(stress_bar)

func actualizar_energy(cantidad: float):
	energy_bar.value = clamp(energy_bar.value + cantidad, 0, energy_bar.max_value)
	animar_ui(energy_bar)

# =========================
# REFRESH
# =========================

func actualizar_todo():
	actualizar_dinero(0)
	actualizar_dia(0)
	actualizar_hora(0)
	actualizar_perdidos(0)

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

func test_stress():
	actualizar_stress(10)

func test_energy():
	actualizar_energy(10)
