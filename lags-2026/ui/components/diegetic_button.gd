class_name DiegeticButton extends TextureButton

@export var translation_key: String = ""
@export var hover_scale_factor: float = 1.05 # Cuánto crece al pasar el ratón
@export var click_scale_factor: float = 0.95 # Cuánto se hunde al hacer clic

@onready var label: Label = $Label
var original_scale: Vector2 = Vector2.ONE
var _tween: Tween

func _ready() -> void:
	# Añadimos este botón al grupo para que reaccione al cambio de idioma
	add_to_group("translatable")
	update_translation()
	
	# Guardamos su escala original por si el artista lo reescaló en el editor
	original_scale = scale
	# Ajustamos el pivote al centro para que crezca desde el medio
	pivot_offset = size / 2.0
	
	# Inicializamos shader apagado
	if material:
		material = material.duplicate()
		material.set_shader_parameter("width", 0.0)
		
	# Conexiones nativas
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	button_down.connect(_on_click_down)
	button_up.connect(_on_click_up)

func update_translation() -> void:
	if label and translation_key != "":
		label.text = LocaleManager.get_text(translation_key)

func _animate_scale(target_scale: Vector2, duration: float) -> void:
	# Matamos el tween anterior si existe para evitar conflictos
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", target_scale, duration)

func _on_hover_enter() -> void:
	_animate_scale(original_scale * hover_scale_factor, 0.2)
	if material:
		material.set_shader_parameter("width", 1.0) # Prende shader

func _on_hover_exit() -> void:
	_animate_scale(original_scale, 0.2)
	if material:
		material.set_shader_parameter("width", 0.0) # Apaga shader

func _on_click_down() -> void:
	# Se "hunde" rápido al hacer clic
	_animate_scale(original_scale * click_scale_factor, 0.05)

func _on_click_up() -> void:
	# Rebota al tamaño de hover al soltar
	_animate_scale(original_scale * hover_scale_factor, 0.1)