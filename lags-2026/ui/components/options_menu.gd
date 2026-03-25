extends PanelContainer

signal menu_closed

# Config locale temporary caches
var _temp_lang: String = "es"
var _temp_music: int = 7
var _temp_sfx: int = 7

var _langs = ["es", "pt", "en"]

@onready var lang_center = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Idioma/MarginContainer/HBoxContainer/HBoxContainer2/Button_4"
@onready var music_center = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Volumen de Musica/MarginContainer/HBoxContainer/HBoxContainer2/Button_1"
@onready var sfx_center = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Volumen de Efectos/MarginContainer/HBoxContainer/HBoxContainer2/Button_1"

func _ready() -> void:
	var lang_left = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Idioma/MarginContainer/HBoxContainer/HBoxContainer2/Button_<"
	var lang_right = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Idioma/MarginContainer/HBoxContainer/HBoxContainer2/Button_>"
	
	var mus_left = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Volumen de Musica/MarginContainer/HBoxContainer/HBoxContainer2/Button_<"
	var mus_right = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Volumen de Musica/MarginContainer/HBoxContainer/HBoxContainer2/Button_>"
	
	var sfx_left = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Volumen de Efectos/MarginContainer/HBoxContainer/HBoxContainer2/Button_<"
	var sfx_right = $"MarginContainer/VBoxContainer/Opciones/VBoxContainer/Volumen de Efectos/MarginContainer/HBoxContainer/HBoxContainer2/Button_>"
	
	var btn_save = $"MarginContainer/VBoxContainer/Botones/Guardar"
	var btn_cancel = $"MarginContainer/VBoxContainer/Botones/Cancelar"
	
	# Connect signals map
	lang_left.pressed.connect(_on_lang_left)
	lang_right.pressed.connect(_on_lang_right)
	
	mus_left.pressed.connect(_on_mus_left)
	mus_right.pressed.connect(_on_mus_right)
	
	sfx_left.pressed.connect(_on_sfx_left)
	sfx_right.pressed.connect(_on_sfx_right)
	
	btn_save.pressed.connect(_on_save_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)
	# Actualiza labels locales cuando cambie el idioma si abren repetidamente
	add_to_group("translatable")

func update_translation() -> void:
	if is_inside_tree() and has_node("MarginContainer/VBoxContainer/Opciones"):
		_update_ui()

func load_current_settings() -> void:
	_temp_lang = ConfigManager.language
	_temp_music = ConfigManager.music_volume
	_temp_sfx = ConfigManager.sfx_volume
			
	_update_ui()

func _update_ui() -> void:
	var lang_key = "lang_" + _temp_lang
	if lang_center:
		lang_center.text = LocaleManager.get_text("options_menu", lang_key)
	if music_center:
		music_center.text = str(_temp_music)
	if sfx_center:
		sfx_center.text = str(_temp_sfx)

func _on_lang_left() -> void:
	var idx = _langs.find(_temp_lang)
	idx = posmod(idx - 1, _langs.size())
	_temp_lang = _langs[idx]
	_update_ui()

func _on_lang_right() -> void:
	var idx = _langs.find(_temp_lang)
	idx = posmod(idx + 1, _langs.size())
	_temp_lang = _langs[idx]
	_update_ui()

func _on_mus_left() -> void:
	_temp_music = max(0, _temp_music - 1)
	_update_ui()

func _on_mus_right() -> void:
	_temp_music = min(10, _temp_music + 1)
	_update_ui()

func _on_sfx_left() -> void:
	_temp_sfx = max(0, _temp_sfx - 1)
	_update_ui()

func _on_sfx_right() -> void:
	_temp_sfx = min(10, _temp_sfx + 1)
	_update_ui()

func _on_save_pressed() -> void:
	ConfigManager.save_config(_temp_lang, _temp_music, _temp_sfx)
	# NO se hace hide() aquí porque el main_menu.gd se encarga de ocultarlo todo.
	menu_closed.emit()

func _on_cancel_pressed() -> void:
	menu_closed.emit()
