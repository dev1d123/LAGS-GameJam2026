class_name LocalizationSystem extends Node

var current_language: String = "es"
# { "category_name": { "key": { "es": "text" } } }
var _translations: Dictionary = {}

func _ready() -> void:
	_load_all_translations()

func _load_all_translations() -> void:
	var path = "res://data/localization/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and not dir.current_is_dir():
				_load_json_file(path + file_name, file_name.get_basename())
			file_name = dir.get_next()
	else:
		printerr("Error accessing localization directory: ", path)

func _load_json_file(file_path: String, category: String) -> void:
	if not FileAccess.file_exists(file_path): return
	var file := FileAccess.open(file_path, FileAccess.READ)
	var content := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(content)
	
	if error == OK:
		_translations[category] = json.data
	else:
		printerr("JSON Error in ", file_path, ": ", json.get_error_message())

func get_text(category: String, key: String) -> String:
	if _translations.has(category):
		if _translations[category].has(key):
			if _translations[category][key].has(current_language):
				return _translations[category][key][current_language]
	return key # Retorna la clave cruda si hay error

func change_language(lang: String) -> void:
	if current_language != lang:
		current_language = lang
		get_tree().call_group("translatable", "update_translation")
