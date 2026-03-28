extends Node

# Variables de tiempo
var time_remaining: float = 60.0
var boxes_collected: int = 0
var is_game_running: bool = true

# Variables de integración
@export var current_day: int = 1
@export var time_decrease_per_day: float = 5.0
@export var base_boxes: int = 5
@export var boxes_increase_per_day: int = 1

# Control de la luz
var light_on: bool = true
var time_since_last_toggle: float = 0.0
var light_toggle_interval: float = 4.0
var light_off_duration: float = 2.0
var light_off_timer: float = 0.0

func _ready() -> void:
	# Cálculo limpio del tiempo inicial
	var day_offset = float(current_day - 1) * time_decrease_per_day
	time_remaining = max(10.0, 60.0 - day_offset)

func _process(delta: float) -> void:
	if not is_game_running:
		return
	
	time_remaining -= delta
	
	if time_remaining <= 0:
		time_remaining = 0
		is_game_running = false
		print("¡SE ACABÓ EL TIEMPO! Game Over")
	
	# Lógica de luz
	if light_on:
		time_since_last_toggle += delta
		if time_since_last_toggle >= light_toggle_interval:
			light_on = false
			light_off_timer = 0.0
			time_since_last_toggle = 0.0
			print("Oscuridad total")
	else:
		light_off_timer += delta
		if light_off_timer >= light_off_duration:
			light_on = true
			time_since_last_toggle = 0.0
			print("¡Luz encendida!")

func collect_box() -> void:
	boxes_collected += 1
	print("Cajas recogidas: ", boxes_collected)

func lose_time(seconds: float) -> void:
	time_remaining = max(0.0, time_remaining - seconds)
	print("Tiempo restante despues del golpe: ", time_remaining)

func get_time_remaining() -> float:
	return time_remaining

func is_light_on() -> bool:
	return light_on
