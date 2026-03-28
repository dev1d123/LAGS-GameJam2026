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
var extrayendo_porcion: bool = false

@export_category("UI Pedidos")
@export var contenedores_pedidos: Array[PanelContainer] # ¡Asigna Primer, Segundo y Tercer Pedido aquí!

var total_rondas: int = 1
var ronda_actual: int = 1

var estado_final: bool = false
var tiempo_total: float = 0.0
var tiempo_ronda_actual: float = 0.0
var acumulado_puntos: int = 0

var audio_bgm: AudioStreamPlayer
var audio_medalla: AudioStreamPlayer
var audio_siguiente: AudioStreamPlayer
@export var label_resultado_texto: Label
@export var boton_continuar: Button
@export_category("UI Final")
@export var label_tiempo_total: Label # <- ¡Nuevo! Asigna tu Label de Tiempo Total aquí

func _ready():
	randomize()
	# 1. Configurar Audio Musical, Medallas y Siguiente dinámicamente
	audio_bgm = AudioStreamPlayer.new()
	var bgm = load("res://assets/audio/minigame-granel/minijuego_granel_musica.mp3")
	if bgm is AudioStreamMP3: bgm.loop = false
	audio_bgm.stream = bgm
	audio_bgm.bus = &"Music"
	audio_bgm.volume_db = -8.0
	add_child(audio_bgm)
	
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
	
	audio_siguiente = AudioStreamPlayer.new()
	audio_siguiente.stream = load("res://assets/audio/minigame-granel/siguiente.mp3")
	audio_siguiente.bus = &"SFX"
	add_child(audio_siguiente)

	# 2. Conectar las señales
	saco.sumar_peso_continuo.connect(_on_saco_sumar_continuo)
	saco.sumar_peso_precision.connect(_on_saco_sumar_precision)
	boton_aceptar.pressed.connect(_on_boton_aceptar_presionado)
	if boton_continuar:
		boton_continuar.pressed.connect(_on_boton_continuar_presionado)

	# 3. Preparar Lógica Multirondas
	total_rondas = randi_range(1, 3)
	ronda_actual = 1
	tiempo_total = 0.0
	acumulado_puntos = 0
	estado_final = false
	if label_tiempo_total: label_tiempo_total.visible = false
	
	# Ocultamos los paneles de pedidos que no se usarán
	for i in range(contenedores_pedidos.size()):
		if i < total_rondas:
			contenedores_pedidos[i].visible = true
			var icon = _get_icono_pedido(contenedores_pedidos[i])
			if icon: icon.visible = false
		else:
			contenedores_pedidos[i].visible = false
			
	_preparar_ronda()

func _get_label_pedido(panel: PanelContainer) -> Label:
	return panel.get_node("MarginContainer/HBoxContainer/Label") as Label

func _get_icono_pedido(panel: PanelContainer) -> TextureRect:
	return panel.get_node("MarginContainer/HBoxContainer/Icono_Medalla") as TextureRect

func _preparar_ronda():
	# Generar peso de 0 a 10, pero con un 70% de probabilidad de caer entre 2 y 5
	if randf() < 0.7:
		peso_objetivo = randf_range(2.0, 5.0)
	else:
		peso_objetivo = randf_range(0.0, 10.0)
	peso_objetivo = snappedf(peso_objetivo, 0.01)
	
	peso_actual = 0.0
	juego_terminado = false
	extrayendo_porcion = false
	tiempo_ronda_actual = 0.0
	if label_tiempo_total: label_tiempo_total.visible = false
	
	balanza.set_peso(0.0)
	sello_calificacion.visible = false
	if label_resultado_texto: label_resultado_texto.visible = false
	if boton_continuar: boton_continuar.visible = false
	boton_aceptar.visible = true
	
	label_objetivo.text = "PESO OBJETIVO:\n%.2f KG" % peso_objetivo
	if contenedores_pedidos.size() > 0:
		var lbl_pedido = _get_label_pedido(contenedores_pedidos[ronda_actual - 1])
		if lbl_pedido:
			lbl_pedido.text = str(ronda_actual) + "° PEDIDO: %.2f KG" % peso_objetivo

func _formatear_tiempo(segundos: float) -> String:
	var mins = int(segundos) / 60
	var secs = int(segundos) % 60
	return "%02d:%02d" % [mins, secs]

func _process(delta):
	if not juego_terminado and not estado_final:
		tiempo_ronda_actual += delta
		tiempo_total += delta
		
	if juego_terminado or extrayendo_porcion or estado_final: return # Bloquea controles si ya terminó o está sacando
	
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
	
	var tex_medalla: Texture2D
	var tex_icono: Texture2D
	
	# Definimos los márgenes de error ajustados para alta precisión (0.01 por C)
	if diferencia <= 0.01:
		acumulado_puntos += 3
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_oro.png")
		tex_icono = load("res://assets/textures/minigame-granel/icono-oro.png")
		if label_resultado_texto: label_resultado_texto.text = "¡EXCELENTE!"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 1.3 # Tono más feliz y agudo
	elif diferencia <= 0.10:
		acumulado_puntos += 2
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_plata.png")
		tex_icono = load("res://assets/textures/minigame-granel/icono-plata.png")
		if label_resultado_texto: label_resultado_texto.text = "¡MUY BIEN!"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 1.0 # Tono base
	elif diferencia <= 0.30:
		acumulado_puntos += 1
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_cobre.png")
		tex_icono = load("res://assets/textures/minigame-granel/icono-cobre.png")
		if label_resultado_texto: label_resultado_texto.text = "NADA MAL"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 0.75 # Tono grave/decepcionante
	else:
		acumulado_puntos += 0
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_error.png")
		tex_icono = load("res://assets/textures/minigame-granel/icono-fallo.png")
		if label_resultado_texto: label_resultado_texto.text = "¡FALLASTE!"
		audio_medalla.stream = stream_error
		audio_medalla.pitch_scale = 1.0
		
	sello_calificacion.texture = tex_medalla
	audio_medalla.play()
	
	# Actualizar el panel de "Pedido" con el icono y tiempo
	if contenedores_pedidos.size() > 0:
		var icon = _get_icono_pedido(contenedores_pedidos[ronda_actual - 1])
		if icon:
			icon.texture = tex_icono
			icon.visible = true
		var lbl_pedido = _get_label_pedido(contenedores_pedidos[ronda_actual - 1])
		if lbl_pedido:
			lbl_pedido.text = str(ronda_actual) + "° PEDIDO: %.2f KG - " % peso_objetivo + _formatear_tiempo(tiempo_ronda_actual)
			
	if boton_continuar:
		if ronda_actual < total_rondas:
			boton_continuar.text = "SIGUIENTE"
		else:
			boton_continuar.text = "VER RESULTADOS"
			
	_animar_medalla()

func _on_boton_continuar_presionado():
	if estado_final:
		self.queue_free()
		return
		
	if ronda_actual < total_rondas:
		if audio_siguiente: audio_siguiente.play()
		ronda_actual += 1
		_preparar_ronda()
	else:
		_mostrar_resultado_final()

func _mostrar_resultado_final():
	estado_final = true
	var prom = float(acumulado_puntos) / total_rondas
	
	var stream_ok = load("res://assets/audio/minigame-granel/ok_base.mp3")
	var stream_error = load("res://assets/audio/minigame-granel/error.mp3")
	var tex_medalla: Texture2D
	
	if prom >= 2.5:
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_oro.png")
		if label_resultado_texto: label_resultado_texto.text = "¡MAESTRO GRANELERO!"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 1.3
	elif prom >= 1.5:
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_plata.png")
		if label_resultado_texto: label_resultado_texto.text = "¡TRABAJO SÓLIDO!"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 1.0
	elif prom >= 0.5:
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_cobre.png")
		if label_resultado_texto: label_resultado_texto.text = "PUEDES MEJORAR"
		audio_medalla.stream = stream_ok
		audio_medalla.pitch_scale = 0.75
	else:
		tex_medalla = load("res://assets/textures/minigame-granel/medalla_error.png")
		if label_resultado_texto: label_resultado_texto.text = "DESPIDO INMINENTE"
		audio_medalla.stream = stream_error
		audio_medalla.pitch_scale = 1.0
		
	sello_calificacion.texture = tex_medalla
	audio_medalla.play()
	
	if label_tiempo_total:
		label_tiempo_total.text = "TIEMPO TOTAL: " + _formatear_tiempo(tiempo_total)
		label_tiempo_total.visible = true
		label_tiempo_total.modulate.a = 0.0
		
	if boton_continuar:
		boton_continuar.text = "FINALIZAR"
		
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
		
	if label_tiempo_total and label_tiempo_total.visible:
		label_tiempo_total.pivot_offset = label_tiempo_total.size / 2.0
		label_tiempo_total.scale = Vector2.ZERO
		label_tiempo_total.modulate.a = 0.0

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
		
	if label_tiempo_total and label_tiempo_total.visible:
		tween.tween_property(label_tiempo_total, "scale", Vector2(1, 1), 0.5)
		tween.tween_property(label_tiempo_total, "modulate:a", 1.0, 0.5)
		
	if boton_continuar:
		tween.tween_property(boton_continuar, "modulate:a", 1.0, 0.5)
