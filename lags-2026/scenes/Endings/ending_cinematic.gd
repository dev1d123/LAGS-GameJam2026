extends Control

const ENDINGS_JSON_PATH := "res://data/cinematic/endings_cinematic.json"
const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"
const ENDING_BGM_GOOD := preload("res://assets/audio/game/goodEnding.ogg")
const ENDING_BGM_NORMAL := preload("res://assets/audio/game/normalEnding.ogg")
const ENDING_BGM_BAD := preload("res://assets/audio/game/badEnding.ogg")
const UI_FONT := preload("res://assets/fonts/PixelOperatorMonoHB.ttf")

const MONEY_BAD_THRESHOLD: int = 3000
const MONEY_GOOD_THRESHOLD: int = 5000
const MONEY_COLOR_BAD := Color(0.62, 0.62, 0.62, 1.0)
const MONEY_COLOR_NORMAL := Color(0.95, 0.84, 0.30, 1.0)
const MONEY_COLOR_GOOD := Color(0.47, 0.88, 0.46, 1.0)

var dialog_data = []
var current_scene_index = 0
var current_language: String = "es"
var is_transitioning: bool = false
var bgm_player: AudioStreamPlayer
var money_result_label: Label

var estres_final := 10.0
var dinero_final := 150.0
var tipo_final := "normal"

@onready var button_label = $CanvasLayer/DialogueBox/SkipButton/ButtonLabel
@onready var anim_player = $AnimationPlayer
@onready var label = $CanvasLayer/DialogueBox/DialogueLabel
@onready var background = $Background
@onready var timer = $CanvasLayer/TypewriterTimer
@onready var blip = $CanvasLayer/BlipPlayer
@onready var fade_overlay = $CanvasLayer/FadeOverlay

func _ready() -> void:
	_load_final_stats()
	
	_resolve_language()
	_determinar_tipo_final()
	_setup_money_result_label()
	_setup_ending_bgm()
	load_dialog_data()
	
	if dialog_data.size() > 0:
		show_scene(0)


func _setup_ending_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "EndingBgmPlayer"
	bgm_player.bus = &"Music"
	bgm_player.volume_db = -8.0
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS

	match tipo_final:
		"good":
			bgm_player.stream = ENDING_BGM_GOOD
		"bad":
			bgm_player.stream = ENDING_BGM_BAD
		_:
			bgm_player.stream = ENDING_BGM_NORMAL

	add_child(bgm_player)
	bgm_player.play()


func _load_final_stats() -> void:
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager == null:
		return

	if game_manager.get("final_stress_percent") != null:
		estres_final = float(game_manager.get("final_stress_percent"))

	if game_manager.get("final_money") != null:
		dinero_final = float(game_manager.get("final_money"))

func _determinar_tipo_final() -> void:
	if estres_final < 30 and dinero_final >= MONEY_GOOD_THRESHOLD:
		tipo_final = "good"
	elif estres_final > 70 or dinero_final <= MONEY_BAD_THRESHOLD:
		tipo_final = "bad"
	else:
		tipo_final = "normal"


func _setup_money_result_label() -> void:
	money_result_label = Label.new()
	money_result_label.name = "MoneyResultLabel"
	money_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	money_result_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	money_result_label.position = Vector2(36, 28)
	money_result_label.size = Vector2(740, 72)
	money_result_label.add_theme_font_override("font", UI_FONT)
	money_result_label.add_theme_font_size_override("font_size", 40)
	money_result_label.add_theme_constant_override("outline_size", 6)
	money_result_label.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 1.0))
	money_result_label.text = _get_money_summary_text()
	money_result_label.add_theme_color_override("font_color", _get_money_color())
	$CanvasLayer.add_child(money_result_label)


func _get_money_summary_text() -> String:
	match current_language:
		"en":
			return "Final money: %d" % int(round(dinero_final))
		"pt":
			return "Dinheiro final: %d" % int(round(dinero_final))
		_:
			return "Dinero final: %d" % int(round(dinero_final))


func _get_money_color() -> Color:
	if dinero_final <= MONEY_BAD_THRESHOLD:
		return MONEY_COLOR_BAD
	if dinero_final >= MONEY_GOOD_THRESHOLD:
		return MONEY_COLOR_GOOD
	return MONEY_COLOR_NORMAL

func _resolve_language() -> void:
	#detectar el idioma del LocaleManager
	var locale_manager := get_node_or_null("/root/LocaleManager")
	if locale_manager:
		if locale_manager.has_method("get_current_language"):
			current_language = str(locale_manager.call("get_current_language"))
		elif locale_manager.get("current_language") != null:
			current_language = str(locale_manager.get("current_language"))

	if current_language not in ["es", "en", "pt"]:
		current_language = "es"

func load_dialog_data() -> void:
	if not FileAccess.file_exists(ENDINGS_JSON_PATH):
		return

	var file := FileAccess.open(ENDINGS_JSON_PATH, FileAccess.READ)
	var content := file.get_as_text()
	var parsed: Dictionary = JSON.parse_string(content)
	
	if parsed.has(tipo_final):
		dialog_data = parsed[tipo_final]

func show_scene(index: int) -> void:
	if index >= dialog_data.size():
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
		return
		
	current_scene_index = index
	var data: Dictionary = dialog_data[index]

	if data.has("background") and FileAccess.file_exists(data["background"]):
		background.texture = load(str(data["background"]))

	var line_text := str(data.get(current_language, data.get("es", "")))
	label.text = line_text
	label.visible_characters = 0

	var btn_key := "btn_" + current_language
	button_label.text = str(data.get(btn_key, "Siguiente"))

	if index == 0 and fade_overlay != null:
		fade_overlay.modulate = Color(0, 0, 0, 1)
		var intro_fade := create_tween()
		intro_fade.tween_property(fade_overlay, "modulate", Color(0, 0, 0, 0), 0.5)

	await get_tree().create_timer(0.5).timeout
	timer.start()

	if tipo_final == "bad" and index == 1:
		if anim_player.has_animation("shake"):
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
		if anim_player.has_animation("fade_transition"):
			anim_player.play("fade_transition")
		
		await get_tree().create_timer(0.5).timeout
		show_scene(current_scene_index + 1)
