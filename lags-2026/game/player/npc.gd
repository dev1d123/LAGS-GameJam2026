# NPC.gd
extends CharacterBody2D
enum TipoNPC {
	ABUELA,
	ABUELO,
	JOVEN,
	NINO,
	MUJER
}
var tipo: TipoNPC
var lugar: String 

var mis_animaciones: SpriteFrames
const speed = 300
const STOP_DISTANCE = 12.0
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
	if pos == null:
		return

	var dist_to_target = global_position.distance_to(pos.global_position)

	if dist_to_target <= STOP_DISTANCE:
		velocity = Vector2.ZERO
		move_and_slide()

		if sprite.animation != "idle":
			sprite.play("idle")
		return
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

	if velocity.length() < 1:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		if(abs(velocity.x) > abs(velocity.y)):
			if sprite.animation != "walk_side":
				sprite.play("walk_side")
			sprite.flip_h = velocity.x > 0
		else:
			if velocity.y < 0:
				if sprite.animation != "walk_up":
					sprite.play("walk_up")
			else:
				if sprite.animation != "walk_side":
					sprite.play("walk_side")


func make_path() -> void:
	if pos == null:
		return
	nav_agent.target_position = pos.global_position

func _on_timer_timeout() -> void:
	make_path()
