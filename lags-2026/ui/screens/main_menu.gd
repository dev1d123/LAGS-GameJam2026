extends Control

const INTRO_SCENE_PATH := "res://scenes/Intro/IntroCinematic.tscn"

const CREDITS_COPY := {
	"es": {
		"title": "CREDITOS",
		"close": "CERRAR",
		"roles": [
			"Programador y Tester",
			"Diseñador 2D",
			"Diseñador de Juego y Diseñador 2D",
			"Programador y Diseñador 2D",
			"Compositor y Programador",
		],
	},
	"en": {
		"title": "CREDITS",
		"close": "CLOSE",
		"roles": [
			"Programmer and Tester",
			"2D Designer",
			"Game Designer and 2D Designer",
			"Programmer and 2D Designer",
			"Composer and Programmer",
		],
	},
	"pt": {
		"title": "CREDITOS",
		"close": "FECHAR",
		"roles": [
			"Programador e Testador",
			"Designer 2D",
			"Game Designer e Designer 2D",
			"Programador e Designer 2D",
			"Compositor e Programador",
		],
	},
}

const CREDIT_NAMES := [
	"Marco Quispe",
	"Wilson Carlos",
	"Julio Chura",
	"Rafael Nina",
	"David Huamani",
]

@onready var options_overlay = $OptionsOverlay
@onready var options_menu = $OptionsOverlay/Options_Menu
@onready var options_bg = $OptionsOverlay/ColorRect
@onready var credits_overlay = $CreditsOverlay
@onready var credits_panel = $CreditsOverlay/CreditsPanel
@onready var credits_bg = $CreditsOverlay/ColorRect
@onready var credits_title: Button = $CreditsOverlay/CreditsPanel/Margin/VBox/Header/Title_1
@onready var btn_credits_close = $CreditsOverlay/CreditsPanel/Margin/VBox/CloseRow/BtnClose
@onready var credits_name_labels: Array[Label] = [
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row1/Columns/Name,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row2/Columns/Name,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row3/Columns/Name,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row4/Columns/Name,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row5/Columns/Name,
]
@onready var credits_role_labels: Array[Label] = [
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row1/Columns/Role,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row2/Columns/Role,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row3/Columns/Role,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row4/Columns/Role,
	$CreditsOverlay/CreditsPanel/Margin/VBox/Row5/Columns/Role,
]

func _ready() -> void:
	add_to_group("translatable")
	$InteractablesLayer/Btn_Start.pressed.connect(_on_btn_start_pressed)
	$InteractablesLayer/Btn_Options.pressed.connect(_on_btn_options_pressed)
	$InteractablesLayer/Btn_Credits.pressed.connect(_on_btn_credits_pressed)
	btn_credits_close.pressed.connect(_on_btn_credits_close_pressed)
	options_overlay.hide()
	options_menu.modulate.a = 0.0
	options_bg.color.a = 0.0
	options_menu.menu_closed.connect(_on_options_closed)
	credits_overlay.hide()
	credits_panel.modulate.a = 0.0
	credits_bg.color.a = 0.0
	update_translation()

func _process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if credits_overlay.visible and event.is_action_pressed("ui_cancel"):
		_hide_credits()
		get_viewport().set_input_as_handled()


func _on_btn_start_pressed() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE_PATH)
	
func _on_btn_options_pressed() -> void:
	options_menu.load_current_settings()
	options_overlay.show()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(options_bg, "color:a", 0.705, 0.1)
	tween.tween_property(options_menu, "modulate:a", 1.0, 0.1)

func _on_options_closed() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(options_bg, "color:a", 0.0, 0.05)
	tween.tween_property(options_menu, "modulate:a", 0.0, 0.05)
	tween.chain().tween_callback(options_overlay.hide)


func _on_btn_credits_pressed() -> void:
	credits_overlay.show()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(credits_bg, "color:a", 0.705, 0.1)
	tween.tween_property(credits_panel, "modulate:a", 1.0, 0.1)


func _on_btn_credits_close_pressed() -> void:
	_hide_credits()


func _hide_credits() -> void:
	if not credits_overlay.visible:
		return
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(credits_bg, "color:a", 0.0, 0.08)
	tween.tween_property(credits_panel, "modulate:a", 0.0, 0.08)
	tween.chain().tween_callback(credits_overlay.hide)


func update_translation() -> void:
	var lang: String = "es"
	if LocaleManager != null:
		lang = str(LocaleManager.current_language)
	if not CREDITS_COPY.has(lang):
		lang = "es"
	var data: Dictionary = CREDITS_COPY[lang]
	var roles: Array = data.get("roles", [])

	credits_title.text = str(data.get("title", "CREDITOS"))
	btn_credits_close.text = str(data.get("close", "CERRAR"))

	for i in range(credits_name_labels.size()):
		credits_name_labels[i].text = CREDIT_NAMES[i]
		if i < roles.size():
			credits_role_labels[i].text = str(roles[i])

func _on_btn_exit_pressed() -> void:
	get_tree().quit()
