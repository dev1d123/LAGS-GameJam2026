class_name LocalizationSystem extends Node

var current_language: String = "es"
var _translations: Dictionary = {}

func _ready() -> void:
	_load_translations()

func _load_translations() -> void:
	var file_path: String = "res://data/localization/menu_texts.json"
	if not FileAccess.file_exists(file_path):
		printerr("Error: Archivo de traducción no encontrado en ", file_path)
		return
		
	var file := FileAccess.open(file_path, FileAccess.READ)
	var content := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(content)
	
	if error == OK:
		_translations = json.data
	else:
		printerr("Error parseando JSON: ", json.get_error_message())

# Esta es la función que usarán nuestros botones
func get_text(key: String) -> String:
	if _translations.has(key) and _translations[key].has(current_language):
		return _translations[key][current_language]
	return key # Retorna la clave cruda si hay error

func change_language(lang: String) -> void:
	current_language = lang
	# Usamos el EventBus (o el árbol) para avisar a toda la UI que se actualice
	get_tree().call_group("translatable", "update_translation")
