@tool
extends Button

@export_group("Textos y Traducción")
## Nombre del json (ej 'options_menu')
@export var translation_category: String = "options_menu"
## Clave de traducción dentro del JSON 
@export var translation_key: String = ""

@export_group("Color del Botón")
## Activa esto para elegir de qué color se pintará tu botón.
@export var use_custom_color: bool = false:
	set(value):
		use_custom_color = value
		_update_colors()

## El color que tendrá el botón. Creará automáticamente tonos exactos para sus animaciones.
@export var base_color: Color = Color.WHITE:
	set(value):
		base_color = value
		_update_colors()

var tween: Tween
var original_scale: Vector2 = Vector2(1.0, 1.0)
var _styles_duplicated: bool = false
@onready var click_sound: AudioStreamPlayer = $ClickSound

func _ready() -> void:
	# Unir a grupo de traducciones central
	add_to_group("translatable")
	update_translation()

	# Nos aseguramos de que el pivote de escala sea el centro del botón
	# Conectamos la señal "resized" por si el botón crece debido a un texto muy largo
	resized.connect(_on_resized)
	_on_resized() 
	
	# Conectamos las señales nativas del botón
	if not Engine.is_editor_hint():
		mouse_entered.connect(_on_hover_in)
		mouse_exited.connect(_on_hover_out)
		button_down.connect(_on_press_down)
		button_up.connect(_on_press_up)
	
	_update_colors()

func update_translation() -> void:
	if translation_key != "":
		text = LocaleManager.get_text(translation_category, translation_key)

func _update_colors() -> void:
	if not is_inside_tree(): return
	
	# Aseguramos que cada botón instanciado tenga copias únicas para aplicar sus propios colores
	if not _styles_duplicated:
		add_theme_stylebox_override("normal", get_theme_stylebox("normal").duplicate())
		add_theme_stylebox_override("hover", get_theme_stylebox("hover").duplicate())
		add_theme_stylebox_override("pressed", get_theme_stylebox("pressed").duplicate())
		_styles_duplicated = true
		
	var style_normal = get_theme_stylebox("normal") as StyleBoxTexture
	var style_hover = get_theme_stylebox("hover") as StyleBoxTexture
	var style_pressed = get_theme_stylebox("pressed") as StyleBoxTexture
	
	if style_normal and style_hover and style_pressed:
		if use_custom_color:
			# Aplicamos tu proporción original EXACTA de oscurecimiento y shift de color
			style_normal.modulate_color = base_color
			style_hover.modulate_color = base_color * Color(0.76, 0.68, 0.74, 1.0)
			style_pressed.modulate_color = base_color * Color(0.59, 0.49, 0.56, 1.0)
		else:
			# Si se desactiva, restauramos tus colores manuales originales del .tscn
			style_normal.modulate_color = Color.WHITE
			style_hover.modulate_color = Color(0.76, 0.68, 0.74, 1.0)
			style_pressed.modulate_color = Color(0.59, 0.49, 0.56, 1.0)

# Calcula el centro matemático exacto cada vez que el botón cambia de tamaño
func _on_resized() -> void:
	pivot_offset = size / 2.0

func _animate(target_scale: Vector2, duration: float) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, duration)

func _on_hover_in() -> void: 
	_animate(original_scale * 1.02, 0.1) # Crece un 2%

func _on_hover_out() -> void: 
	_animate(original_scale, 0.2) # Vuelve a la normalidad

func _on_press_down() -> void: 
	if click_sound:
		click_sound.play()
	_animate(original_scale * 0.98, 0.05) # Se hunde un 5% rápido

func _on_press_up() -> void: 
	_animate(original_scale * 1.02, 0.1) # Rebota al tamaño de hover
