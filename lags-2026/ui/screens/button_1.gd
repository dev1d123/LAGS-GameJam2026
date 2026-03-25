extends Button

var tween: Tween
var original_scale: Vector2 = Vector2(1.0, 1.0)

func _ready() -> void:
	# Nos aseguramos de que el pivote de escala sea el centro del botón
	# Conectamos la señal "resized" por si el botón crece debido a un texto muy largo
	resized.connect(_on_resized)
	_on_resized() 
	
	# Conectamos las señales nativas del botón
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)
	button_down.connect(_on_press_down)
	button_up.connect(_on_press_up)

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
	_animate(original_scale * 0.98, 0.05) # Se hunde un 5% rápido

func _on_press_up() -> void: 
	_animate(original_scale * 1.02, 0.1) # Rebota al tamaño de hover
