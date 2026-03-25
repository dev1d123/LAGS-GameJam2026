class_name LocalizedText extends Node

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
		# Asignamos el texto dinámicamente comprobando si este nodo
		# o su nodo padre es de UI y tiene la propiedad "text".
		# Al heredar 'Node', esto se le puede colocar a un Label o a un Button y funciona igual.
		if "text" in self:
			set("text", LocaleManager.get_text(translation_category, translation_key))
