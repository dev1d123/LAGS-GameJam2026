extends Control

const SCENARIO_SCENE_PATH := "res://levels/TestLevel.tscn"
const INTRO_JSON_PATH := "res://data/cinematic/intro_cinematic.json"
const INTRO_BGM_STREAM := preload("res://assets/audio/game/introCinematic.ogg")

var dialog_data = []
var current_scene_index = 0
var current_language: String = "es"
var is_transitioning: bool = false
var bgm_player: AudioStreamPlayer

@onready var button_label = $CanvasLayer/DialogueBox/SkipButton/ButtonLabel
@onready var anim_player = $AnimationPlayer
@onready var label = $CanvasLayer/DialogueBox/DialogueLabel
@onready var background = $Background
@onready var timer = $CanvasLayer/TypewriterTimer
@onready var blip = $CanvasLayer/BlipPlayer

func _ready() -> void:
	_setup_intro_bgm()
	_resolve_language()
	load_dialog_data()
	if dialog_data.size() > 0:
		show_scene(0)


func _setup_intro_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "IntroBgmPlayer"
	bgm_player.stream = INTRO_BGM_STREAM
	bgm_player.volume_db = -8.0
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)
	bgm_player.play()

func _resolve_language() -> void:
	var locale_manager := get_node_or_null("/root/LocaleManager")
	if locale_manager != null:
		if locale_manager.has_method("get_current_language"):
			current_language = str(locale_manager.call("get_current_language"))
		elif locale_manager.get("current_language") != null:
			current_language = str(locale_manager.get("current_language"))

	if current_language not in ["es", "en", "pt"]:
		current_language = "es"


func load_dialog_data() -> void:
	if not FileAccess.file_exists(INTRO_JSON_PATH):
		push_warning("No se encontro el archivo de cinematicas: %s" % INTRO_JSON_PATH)
		return

	var file := FileAccess.open(INTRO_JSON_PATH, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir el archivo de cinematicas")
		return

	var content: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("JSON de cinematica invalido")
		return

	var parsed_dict: Dictionary = parsed
	var scenes_variant: Variant = parsed_dict.get("scenes", [])
	if typeof(scenes_variant) == TYPE_ARRAY:
		var scenes_array: Array = scenes_variant
		dialog_data = scenes_array

func show_scene(index: int) -> void:
	if index >= dialog_data.size():
		get_tree().change_scene_to_file(SCENARIO_SCENE_PATH)
		return
		
	current_scene_index = index
	var data: Dictionary = dialog_data[index]
	
	if data.has("background"):
		background.texture = load(str(data["background"]))

	var line_text := str(data.get(current_language, data.get("es", "")))
	label.text = line_text
	label.visible_characters = 0
	
	var btn_key: String = "btn_" + current_language
	button_label.text = str(data.get(btn_key, "Siguiente"))

	await get_tree().create_timer(0.5).timeout
	timer.start()

	if index == 2: 
		anim_player.play("shake")
	else:
		if anim_player.current_animation == "shake":
			anim_player.stop()
			background.position = Vector2.ZERO 
 
	is_transitioning = false

func _on_typewriter_timer_timeout() -> void:
	if label.visible_characters < label.text.length():
		label.visible_characters += 1
		blip.pitch_scale = randf_range(0.9, 1.1) 
		blip.play()
	else:
		timer.stop()

func _on_skip_button_pressed() -> void:
	if is_transitioning:
		return

	if label.visible_characters < label.text.length():
		label.visible_characters = label.text.length()
		timer.stop()
	else:
		is_transitioning = true
		anim_player.play("fade_transition")
		await get_tree().create_timer(0.5).timeout
		show_scene(current_scene_index + 1)
