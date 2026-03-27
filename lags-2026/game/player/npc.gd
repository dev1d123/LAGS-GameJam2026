# NPC.gd
extends CharacterBody2D

var mis_animaciones: SpriteFrames
const speed = 100

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@export var pos: Node2D

func _ready() -> void:
	if mis_animaciones:
		sprite.sprite_frames = mis_animaciones
		sprite.play()
	$Timer.timeout.connect(_on_timer_timeout)

	# Esperar un frame para que el mapa de navegación esté listo
	await get_tree().physics_frame
	make_path()





var last_position: Vector2
var stuck_timer: float = 0.0
const STUCK_THRESHOLD = 1.5  # segundos parado
const STUCK_MIN_DIST = 2.0   # píxeles mínimos para considerar que se movió

func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Stuck detection
	stuck_timer += delta
	if stuck_timer >= STUCK_THRESHOLD:
		stuck_timer = 0.0
		if global_position.distance_to(last_position) < STUCK_MIN_DIST:
			make_path()  # Forzar recálculo
		last_position = global_position

	var next_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_pos)
	velocity = dir * speed
	move_and_slide()

func make_path() -> void:
	if pos == null:
		print("ERROR: player no asignado")
		return
	nav_agent.target_position = pos.global_position

func _on_timer_timeout() -> void:
	make_path()
