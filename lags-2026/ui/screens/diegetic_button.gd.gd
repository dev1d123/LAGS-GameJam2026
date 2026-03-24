extends TextureButton

@export_group("Textos y Traducción")
@export var translation_key: String = "" 

@export_group("Resplandor Exterior (Glow)")
@export var glow_hover_color: Color = Color("ffcda2") 
@export var glow_hover_size: float = 3.0 

@export_group("Color Interior (Hover)")
## NUEVO: El color que teñirá el interior de tu pixel art (ej. crema o amarillo suave para un efecto cálido).
@export var tint_hover_color: Color = Color("ffe72f49") 
## Multiplicador de brillo. (1.0 = normal, 1.2 = mezcla un 20% con el tinte y lo ilumina).
@export var brightness_hover: float = 1.05 
## Multiplicador de saturación. (1.0 = normal, 1.2 = 20% más vivo).
@export var saturation_hover: float = 1.25 

@onready var label: Label = $Label
var original_scale: Vector2
var tween: Tween

func _ready() -> void:
	if label and translation_key != "":
		label.text = LocaleManager.get_text(translation_key)
		
	pivot_offset = size / 2.0
	original_scale = scale
	
	if material:
		material = material.duplicate()
		material.set_shader_parameter("glow_color", glow_hover_color)
		# NUEVO: Pasamos el color del inspector al shader al iniciar
		material.set_shader_parameter("tint_color", tint_hover_color)
	
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)
	button_down.connect(_on_press_down)
	button_up.connect(_on_press_up)

# Esta función se mantiene igual, ya animaba brillo y saturación
func _animate(target_scale: Vector2, target_size: float, target_bright: float, target_sat: float, duration: float) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", target_scale, duration)
	
	if material and material is ShaderMaterial:
		tween.tween_property(material, "shader_parameter/glow_size", target_size, duration)
		tween.tween_property(material, "shader_parameter/brightness", target_bright, duration)
		tween.tween_property(material, "shader_parameter/saturation", target_sat, duration)

func _on_hover_in() -> void: 
	_animate(original_scale * 1.05, glow_hover_size, brightness_hover, saturation_hover, 0.2)

func _on_hover_out() -> void: 
	# El brillo y saturación regresan a 1.0 (neutral)
	_animate(original_scale, 0.0, 1.0, 1.0, 0.2)

func _on_press_down() -> void: 
	_animate(original_scale * 0.95, glow_hover_size + 2.0, brightness_hover + 0.2, saturation_hover + 0.2, 0.05)

func _on_press_up() -> void: 
	_animate(original_scale * 1.05, glow_hover_size, brightness_hover, saturation_hover, 0.1)
