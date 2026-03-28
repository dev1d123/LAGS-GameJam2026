extends Node2D

@export var flecha_scene: PackedScene
@export var puntos_victoria: int = 10
@export var limite_errores: int = 10

var direcciones = ["arriba", "abajo", "izquierda", "derecha"]
var puntos = 0
var errores = 0
var estres_actual = 0.0
var current_language = "es"
var juego_activo = false

@onready var sprite_cabeza = $CanvasLayer/FondoModal/HitZone/SpriteCabeza

@onready var spawn_timer = $SpawnTimer
@onready var fondo_modal = $CanvasLayer/FondoModal
@onready var label_pregunta = $CanvasLayer/LabelPregunta
@onready var barra_progreso = $CanvasLayer/BarraProgreso
@onready var flash_rojo = $CanvasLayer/FlashRojo

@onready var sfx_open = $SfxOpen
@onready var sfx_close = $SfxClose
@onready var sfx_success = $SfxSuccess
@onready var sfx_error = $SfxError

var lista_preguntas = []

func _ready():
	estres_actual = 50
	
	if barra_progreso:
		barra_progreso.max_value = puntos_victoria
		barra_progreso.value = 0
	
	load_questions()
	await iniciar_secuencia_entrada()

func iniciar_secuencia_entrada():
	if sfx_open: sfx_open.play()
	mostrar_pregunta_aleatoria()
	await get_tree().create_timer(1.2).timeout
	juego_activo = true
	spawn_timer.start()

func load_questions():
	var file_path = "res://scenes/minigameIndications/preguntas_indicaciones.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var json = JSON.parse_string(json_text)
		if json and json.has("preguntas"):
			lista_preguntas = json["preguntas"]

func mostrar_pregunta_aleatoria():
	if lista_preguntas.size() > 0:
		var pregunta_data = lista_preguntas.pick_random()
		label_pregunta.text = pregunta_data[current_language]
		label_pregunta.visible_ratio = 0
		var tween = create_tween()
		tween.tween_property(label_pregunta, "visible_ratio", 1.0, 1.0)

func _on_spawn_timer_timeout():
	if !juego_activo: return 

	var nuevo_wait = 1.0
	if estres_actual <= 20: nuevo_wait = 1.0
	elif estres_actual <= 40: nuevo_wait = 0.8
	elif estres_actual <= 60: nuevo_wait = 0.5
	else: nuevo_wait = 0.4
	
	spawn_timer.wait_time = nuevo_wait
	crear_flecha()

func crear_flecha():
	var nueva_flecha = flecha_scene.instantiate()
	var dir = direcciones.pick_random()
	nueva_flecha.direccion = dir

	var v_min = 300.0; var v_max = 300.0
	var parpadeo = false; var prob_falsa = 0.15

	if estres_actual > 20 and estres_actual <= 40:
		v_min = 250.0; v_max = 450.0; prob_falsa = 0.2
	elif estres_actual > 40:
		v_min = 200.0; v_max = 550.0; parpadeo = true; prob_falsa = 0.25

	nueva_flecha.velocidad = randf_range(v_min, v_max)
	nueva_flecha.tiene_parpadeo = parpadeo
	if randf() < prob_falsa:
		nueva_flecha.es_falsa = true

	nueva_flecha.se_paso.connect(_on_flecha_pasada)

	fondo_modal.add_child(nueva_flecha)
	configurar_posicion_flecha(nueva_flecha, nueva_flecha.direccion)

func _on_flecha_pasada():
	if juego_activo:
		registrar_error()

func configurar_posicion_flecha(f, d):
	var spawn_point = fondo_modal.get_node("SpawnPoint")
	var pos_inicial = spawn_point.position
	var separacion = 60

	match d:
		"izquierda": f.position = Vector2(pos_inicial.x - (separacion * 1.5), pos_inicial.y)
		"arriba": f.position = Vector2(pos_inicial.x - (separacion * 0.5), pos_inicial.y)
		"abajo": f.position = Vector2(pos_inicial.x + (separacion * 0.5), pos_inicial.y)
		"derecha": f.position = Vector2(pos_inicial.x + (separacion * 1.5), pos_inicial.y)

func _input(event):
	for dir in direcciones:
		if event.is_action_pressed(dir):
			validar_hit(dir)

func validar_hit(dir_presionada):
	if !juego_activo: return
	
	var zona = fondo_modal.get_node("HitZone")
	if zona and zona.flecha_actual:
		if zona.flecha_actual.direccion == dir_presionada and !zona.flecha_actual.es_falsa:
			animar_cabeza_acierto()
			
			if sfx_success:
				sfx_success.pitch_scale = randf_range(0.9, 1.1)
				sfx_success.play()
				
			zona.flecha_actual.queue_free()
			zona.flecha_actual = null
			puntos += 1
			actualizar_barra()
			verificar_victoria()
		else:
			registrar_error()
			animar_cabeza_error()
			zona.flecha_actual.queue_free()
			zona.flecha_actual = null

func animar_cabeza_acierto():
	var tween = create_tween()
	tween.tween_property(sprite_cabeza, "scale", Vector2(1.2, 0.8), 0.05)
	tween.tween_property(sprite_cabeza, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_ELASTIC)

func animar_cabeza_error():
	var tween = create_tween()
	sprite_cabeza.modulate = Color(1, 0, 0)
	tween.tween_property(sprite_cabeza, "modulate", Color(1, 1, 1), 0.2)

func registrar_error():
	if !juego_activo: return
	
	if sfx_error: sfx_error.play()
	errores += 1
	
	if flash_rojo:
		var tween = create_tween()
		flash_rojo.modulate.a = 0.4 
		tween.tween_property(flash_rojo, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	if errores >= limite_errores:
		perder_juego()

func actualizar_barra():
	if barra_progreso:
		var tween = create_tween()
		tween.tween_property(barra_progreso, "value", puntos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func verificar_victoria():
	if puntos >= puntos_victoria:
		finalizar_partida(true)

func perder_juego():
	finalizar_partida(false)

func finalizar_partida(ganado: bool):
	juego_activo = false 
	spawn_timer.stop()

	for f in fondo_modal.get_children():
		if f.is_in_group("flechas"): 
			f.queue_free()
	
	if sfx_close: sfx_close.play()
	
	if ganado: print("¡Victoria!")
	else: print("Derrota...")
	
	await sfx_close.finished
	#queue_free() o volver a la tienda
