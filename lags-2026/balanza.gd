extends Node2D

# Referencias a los nuevos nodos
@onready var sprite_arroz = $MontonArroz
@onready var label_pantalla = $PantallaDigital
@onready var timer_retraso = $TimerRetraso

var peso_real: float = 0.0

# Tus 9 estados (frames 0 al 8). Ajusta estos números a tu gusto para la dificultad.
@export var umbrales_frames: Array[float] = [0.0, 0.1, 0.3, 0.6, 1.0, 1.5, 2.0, 2.5, 2.75, 3]

func _ready():
	timer_retraso.wait_time = 0.5
	timer_retraso.timeout.connect(_actualizar_pantalla_digital)
	timer_retraso.start()

# Esta es la función que el Controlador Principal llamará
func set_peso(nuevo_peso: float):
	peso_real = max(0.0, nuevo_peso) 
	_actualizar_visual_arroz()

func _actualizar_visual_arroz():
	var frame_calculado = 0
	
	# Comparamos el peso con nuestros umbrales
	for i in range(umbrales_frames.size()):
		if peso_real >= umbrales_frames[i]:
			frame_calculado = i
			
	# Solo cambiamos el frame del montoncito de arroz
	sprite_arroz.frame = frame_calculado

func _actualizar_pantalla_digital():
	label_pantalla.text = str("%.2f" % peso_real) + " kg"
