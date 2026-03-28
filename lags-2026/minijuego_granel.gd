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
@export var peso_por_toque: float = 0.01 # kg por toque (Tecla C)
@export var peso_devuelto: float = 0.25 # kg devueltos (Tecla R)

# Variables internas
var peso_actual: float = 0.0
var juego_terminado: bool = false
var extrayendo_porcion: bool = false # Bloquea acciones durante sacudida

var audio_bgm: AudioStreamPlayer
var audio_medalla: AudioStreamPlayer
@export var label_resultado_texto: Label # <- ¡Asigna tu nodo 'Resultado Label' aquí desde el Inspector!
@export var boton_continuar: Button # <- ¡Asigna tu nuevo botón de Continuar aquí!

func _ready():
	# 1. Configurar estado inicial
	sello_calificacion.visible = false
	if label_resultado_texto:
		label_resultado_texto.visible = false
	if boton_continuar:
		boton_continuar.visible = false
		
	balanza.set_peso(0.0) # Aseguramos que empiece vacía
	
	label_objetivo.text = "PESO OBJETIVO: " + str(peso_objetivo) + " kg"
	
	# 2. Conectar las señales del Saco al Controlador
	saco.sumar_peso_continuo.connect(_on_saco_sumar_continuo)
	saco.sumar_peso_precision.connect(_on_saco_sumar_precision)
	
	# 3. Conectar los botones de la Interfaz
	boton_aceptar.pressed.connect(_on_boton_aceptar_presionado)
	if boton_continuar:
		# Elimina este modal de la memoria y la pantalla al finalizar
		boton_continuar.pressed.connect(func(): self.queue_free())
	
	# 4. Configurar Audio Musical y Medallas dinámicamente
	audio_bgm = AudioStreamPlayer.new()
	var bgm = load("res://assets/audio/minigame-granel/minijuego_granel_musica.mp3")
	if bgm is AudioStreamMP3: bgm.loop = false
	audio_bgm.stream = bgm
	audio_bgm.bus = &"Music"
	audio_bgm.volume_db = -8.0
	add_child(audio_bgm)
	
	# Timer para bucle con 5s de retraso
	var timer_bgm = Timer.new()
	timer_bgm.wait_time = 5.0
	timer_bgm.one_shot = true
	audio_bgm.finished.connect(func(): timer_bgm.start())
	timer_bgm.timeout.connect(func(): audio_bgm.play())
	add_child(timer_bgm)
	audio_bgm.play()
	
	audio_medalla = AudioStreamPlayer.new()
	audio_medalla.bus = &"SFX"
	add_child(audio_medalla)

func _process(delta):
	if juego_terminado or extrayendo_porcion: return # Bloquea controles si ya terminó o está sacando
	
	# Lógica de la Tecla R (Devolver porción)
	if Input.is_action_just_pressed("ui_cancel") or Input.is_key_pressed(KEY_R):
		_iniciar_extraccion()

# --- FUNCIONES DE RECEPCIÓN (Desde el Saco) ---

func _on_saco_sumar_continuo(delta):
	if juego_terminado or extrayendo_porcion: return
	
	# Aumentamos el peso gradualmente según el tiempo (delta)
	peso_actual += tasa_llenado_continuo * delta
	balanza.set_peso(peso_actual)

func _on_saco_sumar_precision():
	if juego_terminado or extrayendo_porcion: return
	
	# Aumentamos un "bloque" exacto de peso
	peso_actual += peso_por_toque
	balanza.set_peso(peso_actual)

func _iniciar_extraccion():
	if peso_actual <= 0: return # Nada que extraer
	
	extrayendo_porcion = true
	if saco and "bloqueado" in saco:
		saco.bloqueado = true # Obliga al saco a que deje de tirar arroz visualmente
		
	var pos_original = balanza.position
	var tween = create_tween()
	
	# Tiempo total 0.35s dividido en pequeños pasos de 0.05s
	# 1. Empieza a agitarse
	tween.tween_property(balanza, "position", pos_original + Vector2(15, -5), 0.05)
	tween.tween_property(balanza, "position", pos_original + Vector2(-15, 5), 0.05)
	tween.tween_property(balanza, "position", pos_original + Vector2(10, -5), 0.05)
	
	# 2. A la mitad exacta de la animación, descontar el arroz visual y numéricamente
	tween.tween_callback(_ejecutar_descuento)
	
	# 3. Termina de temblar
	tween.tween_property(balanza, "position", pos_original + Vector2(-10, 5), 0.05)
	tween.tween_property(balanza, "position", pos_original + Vector2(5, -5), 0.05)
	tween.tween_property(balanza, "position", pos_original + Vector2(-5, 5), 0.05)
	tween.tween_property(balanza, "position", pos_original, 0.05) # Aseguramos que vuelva exacto al centro
	
	# 4. Cuando el temblor finalice por completo, liberar los controles
	tween.tween_callback(func():
		extrayendo_porcion = false
		if saco and "bloqueado" in saco:
			saco.bloqueado = false
	)

func _ejecutar_descuento():
	peso_actual -= peso_devuelto
	peso_actual = max(0.0, peso_actual) # Nunca menor a 0
	balanza.set_peso(peso_actual)

# --- LÓGICA DE CALIFICACIÓN (Fin del juego) ---

func _on_boton_aceptar_presionado():
	if juego_terminado: return
	juego_terminado = true
	
	# Ocultamos el botón de aceptar para limpiar la interfaz final
	boton_aceptar.visible = false
	
	# Calculamos la diferencia entre lo que echó y el objetivo
	var diferencia = abs(peso_actual - peso_objetivo)
	
	var stream_ok = load("res://assets/audio/minigame-granel/ok_base.mp3")
	var stream_error = load("res://assets/audio/minigame-granel/error.mp3")
	
	# Definimos los márgenes de error ajustados para alta precisión (0.01 por C)
	if diferencia <= 0.01:
		print("¡EXCELENTE! Precisión perfecta.")
		sello_calificacion.texture = load("res://assets/textures/minigame-granel/medalla_oro.png")
		if label_resultado_texto: label_resultado_texto.text = "¡EXCELENTE!"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 1.3 # Tono más feliz y agudo
	elif diferencia <= 0.10:
		print("BUENO. Un poco desviado, pero aceptable.")
		sello_calificacion.texture = load("res://assets/textures/minigame-granel/medalla_plata.png")
		if label_resultado_texto: label_resultado_texto.text = "¡MUY BIEN!"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 1.0 # Tono base
	elif diferencia <= 0.30:
		print("REGULAR. Bastante alejado de la meta.")
		sello_calificacion.texture = load("res://assets/textures/minigame-granel/medalla_cobre.png")
		if label_resultado_texto: label_resultado_texto.text = "NADA MAL"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 0.75 # Tono grave/decepcionante
	else:
		print("MALO. Fallaste por completo el peso solicitado.")
		sello_calificacion.texture = load("res://assets/textures/minigame-granel/medalla_error.png")
		if label_resultado_texto: label_resultado_texto.text = "¡FALLASTE!"
		audio_medalla.stream = stream_error
		audio_medalla.pitch_scale = 1.0
		
	audio_medalla.play()
	sello_calificacion.visible = true
	_animar_medalla()

func _animar_medalla():
	sello_calificacion.visible = true
	if label_resultado_texto: 
		label_resultado_texto.visible = true
	
	# 1. Preparamos el sello: lo hacemos diminuto y lo rotamos un poco
	sello_calificacion.scale = Vector2.ZERO
	sello_calificacion.rotation_degrees = -30
	
	if label_resultado_texto:
		label_resultado_texto.pivot_offset = label_resultado_texto.size / 2.0
		label_resultado_texto.scale = Vector2.ZERO
		label_resultado_texto.modulate.a = 0.0

	if boton_continuar:
		boton_continuar.modulate.a = 0.0
		boton_continuar.visible = true

	# 2. Creamos el Tween (el motor de animación por código de Godot)
	var tween = create_tween()
	tween.set_parallel(true) # Hace que las animaciones ocurran al mismo tiempo
	tween.set_trans(Tween.TRANS_BACK) # TRANS_BACK hace ese efecto elástico de "pasarse un poquito y volver"
	tween.set_ease(Tween.EASE_OUT)

	# 3. Le decimos qué animar, a qué valor llegar, y en cuánto tiempo (0.5 segundos)
	tween.tween_property(sello_calificacion, "scale", Vector2(1, 1), 0.5)
	tween.tween_property(sello_calificacion, "rotation_degrees", 0.0, 0.5)
	
	if label_resultado_texto:
		tween.tween_property(label_resultado_texto, "scale", Vector2(1, 1), 0.5)
		tween.tween_property(label_resultado_texto, "modulate:a", 1.0, 0.5)
		
	if boton_continuar:
		tween.tween_property(boton_continuar, "modulate:a", 1.0, 0.5)
