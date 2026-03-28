extends Control

# Referencias a tus módulos
@export var saco: Node2D
@export var balanza: Node2D
@export var boton_aceptar: Button
@export var sello_calificacion: TextureRect # (O Sprite2D, según el que hayas dejado)
@export var label_objetivo: Label

# --- VARIABLES DE DISEÑO (Ajustables desde el Inspector) ---
@export var peso_objetivo: float = 2.75
@export var tasa_llenado_continuo: float = 1.5 # kg por segundo (Espacio)
@export var peso_por_toque: float = 0.1 # kg por toque (Tecla C)
@export var peso_devuelto: float = 0.25 # kg devueltos (Tecla R)

# Variables internas
var peso_actual: float = 0.0
var juego_terminado: bool = false

func _ready():
	# 1. Configurar estado inicial
	sello_calificacion.visible = false
	balanza.set_peso(0.0) # Aseguramos que empiece vacía
	
	label_objetivo.text = "PESO OBJETIVO: " + str(peso_objetivo) + " kg"
	
	# 2. Conectar las señales del Saco al Controlador
	saco.sumar_peso_continuo.connect(_on_saco_sumar_continuo)
	saco.sumar_peso_precision.connect(_on_saco_sumar_precision)
	
	# 3. Conectar el botón de Aceptar
	boton_aceptar.pressed.connect(_on_boton_aceptar_presionado)

func _process(delta):
	if juego_terminado: return # Bloquea controles si ya terminó
	
	# Lógica de la Tecla R (Devolver porción)
	if Input.is_action_just_pressed("ui_cancel") or Input.is_key_pressed(KEY_R):
		_devolver_porcion()

# --- FUNCIONES DE RECEPCIÓN (Desde el Saco) ---

func _on_saco_sumar_continuo(delta):
	if juego_terminado: return
	
	# Aumentamos el peso gradualmente según el tiempo (delta)
	peso_actual += tasa_llenado_continuo * delta
	balanza.set_peso(peso_actual)

func _on_saco_sumar_precision():
	if juego_terminado: return
	
	# Aumentamos un "bloque" exacto de peso
	peso_actual += peso_por_toque
	balanza.set_peso(peso_actual)

func _devolver_porcion():
	if peso_actual > 0:
		peso_actual -= peso_devuelto
		peso_actual = max(0.0, peso_actual) # Nunca menor a 0
		balanza.set_peso(peso_actual)
		# Opcional: Aquí podrías reproducir el sonido de la cuchara medidora

# --- LÓGICA DE CALIFICACIÓN (Fin del juego) ---

func _on_boton_aceptar_presionado():
	if juego_terminado: return
	juego_terminado = true
	
	# Calculamos la diferencia entre lo que echó y el objetivo
	var diferencia = abs(peso_actual - peso_objetivo)
	
	# Definimos los márgenes de error (Puedes ajustar esto)
	if diferencia <= 0.05:
		print("¡EXCELENTE! Precisión perfecta.")
		# Aquí cargarías la textura del sello Excelente:
		sello_calificacion.texture = load("res://assets/textures/minigame-granel/medalla_oro.png")
	elif diferencia <= 0.2:
		print("BUENO. Un poco desviado, pero aceptable.")
		sello_calificacion.texture = load("res://assets/textures/minigame-granel/medalla_plata.png")
	else:
		print("MALO. Muy lejos del peso solicitado.")
		sello_calificacion.texture = load("res://assets/textures/minigame-granel/medalla_cobre.png")
		
	sello_calificacion.visible = true
	_animar_medalla()

func _animar_medalla():
	sello_calificacion.visible = true
	
	# 1. Preparamos el sello: lo hacemos diminuto y lo rotamos un poco
	sello_calificacion.scale = Vector2.ZERO
	sello_calificacion.rotation_degrees = -30

	# 2. Creamos el Tween (el motor de animación por código de Godot)
	var tween = create_tween()
	tween.set_parallel(true) # Hace que las animaciones ocurran al mismo tiempo
	tween.set_trans(Tween.TRANS_BACK) # TRANS_BACK hace ese efecto elástico de "pasarse un poquito y volver"
	tween.set_ease(Tween.EASE_OUT)

	# 3. Le decimos qué animar, a qué valor llegar, y en cuánto tiempo (0.5 segundos)
	tween.tween_property(sello_calificacion, "scale", Vector2(1, 1), 0.5)
	tween.tween_property(sello_calificacion, "rotation_degrees", 0.0, 0.5)
