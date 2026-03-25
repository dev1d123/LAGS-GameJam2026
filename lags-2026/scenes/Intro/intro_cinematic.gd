extends Control

var dialog_data = []
var current_scene_index = 0
var current_language = "es" # Esto lo controlará el menú de idiomas [cite: 211]

@onready var button_label = $CanvasLayer/DialogueBox/SkipButton/ButtonLabel
@onready var anim_player = $AnimationPlayer
@onready var label = $CanvasLayer/DialogueBox/DialogueLabel
@onready var background = $Background
@onready var timer = $CanvasLayer/TypewriterTimer
@onready var blip = $CanvasLayer/BlipPlayer

func _ready():
	load_dialog_data()
	if dialog_data.size() > 0:
		show_scene(0)

func load_dialog_data():
	# Cargamos la ruta que corregiste [cite: 211]
	var file = FileAccess.open("res://data/cinematic/intro_cinematic.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		dialog_data = json["scenes"]

func show_scene(index):
	# Si terminamos las escenas, vamos al juego (Don JC entra al quiosco) [cite: 32, 67]
	if index >= dialog_data.size():
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
		return
		
	current_scene_index = index
	var data = dialog_data[index]
	
	# Actualizamos imagen y textos [cite: 213]
	background.texture = load(data["background"])
	label.text = data[current_language]
	label.visible_characters = 0
	
	# Actualizamos el botón con el idioma correcto (ES, EN, PT)
	var btn_key = "btn_" + current_language
	button_label.text = data[btn_key]

	# Esperamos a que el fade termine de aclararse para empezar a escribir
	await get_tree().create_timer(0.5).timeout
	timer.start()

	# Lógica del temblor (Escena 3: El colapso de Eusebio) [cite: 26-27, 209]
	if index == 2: 
		anim_player.play("shake")
	else:
		# Si no es la escena de estrés, nos aseguramos de que el fondo esté quieto
		if anim_player.current_animation == "shake":
			anim_player.stop()
			background.position = Vector2.ZERO 

func _on_typewriter_timer_timeout():
	if label.visible_characters < label.text.length():
		label.visible_characters += 1
		# Sonido de voz tipo Undertale con variación [cite: 210]
		blip.pitch_scale = randf_range(0.9, 1.1) 
		blip.play()
	else:
		timer.stop()

func _on_skip_button_pressed():
	# Si el texto se está escribiendo, lo mostramos todo
	if label.visible_characters < label.text.length():
		label.visible_characters = label.text.length()
		timer.stop()
	else:
		# Si ya terminó, hacemos el fade y pasamos a la siguiente
		anim_player.play("fade_transition")
		await get_tree().create_timer(0.5).timeout
		show_scene(current_scene_index + 1)
