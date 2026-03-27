extends CharacterBody2D

@export var max_speed: float = 600.0
@export var acceleration: float = 1200.0
@export var step_interval: float = 0.35 

@onready var sprite = $AnimatedSprite2D
@onready var footstep = $AudioStreamPlayer2D

var step_timer: float = 0.0
func _process(delta):
	z_index = int(global_position.y) + 1000
func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	

	
	update_animation()
	update_footsteps(delta)


func update_animation() -> void:
	if velocity.length() < 5:
		if sprite.animation.begins_with("walk"):
			sprite.play(sprite.animation.replace("walk", "idle"))
		return
	
	if abs(velocity.y) > abs(velocity.x):
		if velocity.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")
	else:
		sprite.play("walk_side")
		sprite.flip_h = velocity.x > 0  


func update_footsteps(delta: float) -> void:
	if velocity.length() > 10:
		step_timer -= delta
		
		if step_timer <= 0:
			footstep.pitch_scale = randf_range(0.9, 1.1)
			footstep.play()
			
			step_timer = step_interval
	else:
		step_timer = 0.0
