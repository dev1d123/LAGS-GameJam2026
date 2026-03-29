extends CharacterBody2D

@export var max_speed: float = 600.0
@export var acceleration: float = 1200.0
@export var step_interval: float = 0.35
@export var min_speed_factor_at_zero_energy: float = 0.45
@export var energy_speed_curve_exp: float = 1.2

@onready var sprite = $AnimatedSprite2D
@onready var footstep = $AudioStreamPlayer2D

var step_timer: float = 0.0
var hud_ref: Node = null

# Aura
var aura_active: bool  = false
var aura_accum:  float = 0.0
const AURA_SPEED               = 3.0
const AURA_COLOR_PLAYER        = Color(1.0, 0.85, 0.3, 1.0)  # dorado


func _ready() -> void:
	add_to_group("player")
	sprite.self_modulate = Color.WHITE
	hud_ref = get_node_or_null("../Hud")


func set_aura(value: bool) -> void:
	aura_active = value
	aura_accum  = 0.0
	if not value:
		sprite.self_modulate = Color.WHITE


func _process(delta: float) -> void:


	if aura_active:
		aura_accum += delta * AURA_SPEED
		var pulse = sin(aura_accum) * 0.5 + 0.5
		sprite.self_modulate = Color.WHITE.lerp(AURA_COLOR_PLAYER, pulse)


func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	velocity = input_vector * max_speed * _get_energy_speed_factor()

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


func _get_energy_speed_factor() -> float:
	if hud_ref == null:
		return 1.0

	if not hud_ref.has_method("get_energy_percent"):
		return 1.0

	var energy_percent: float = clampf(float(hud_ref.get_energy_percent()), 0.0, 100.0)
	var t: float = energy_percent / 100.0
	var curved_t: float = pow(t, energy_speed_curve_exp)
	return lerpf(min_speed_factor_at_zero_energy, 1.0, curved_t)
