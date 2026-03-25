class_name LocalizedLabel extends Label

@export_group("Textos y Traducción")
## Escribe el nombre del archivo JSON (ej. 'options_menu')
@export var translation_category: String = "options_menu"
## La clave dentro de ese archivo JSON
@export var translation_key: String = "":
	set(val):
		translation_key = val
		if is_inside_tree():
			update_translation()

func _ready() -> void:
	add_to_group("translatable")
	update_translation()

func update_translation() -> void:
	if translation_key != "":
		text = LocaleManager.get_text(translation_category, translation_key)
