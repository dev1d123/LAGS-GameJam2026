extends CharacterBody2D

@export var max_speed: float = 600.0
@export var acceleration: float = 1200.0
@export var step_interval: float = 0.35
@export var min_speed_factor_at_zero_energy: float = 0.45
@export var energy_speed_curve_exp: float = 1.2
@export var corner_nudge_pixels: float = 20

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
	_resolve_hud_ref()


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
	var input_vector := _get_movement_input_vector()
	velocity = input_vector * max_speed * _get_energy_speed_factor() * _get_inventory_speed_factor()
	move_and_slide()
	_apply_corner_nudge(input_vector)
	update_animation()
	update_footsteps(delta)


func _get_movement_input_vector() -> Vector2:
	# Accept both project-defined WASD actions and default ui_* actions.
	var right := maxf(Input.get_action_strength("ui_right"), Input.get_action_strength("derecha"))
	var left := maxf(Input.get_action_strength("ui_left"), Input.get_action_strength("izquierda"))
	var down := maxf(Input.get_action_strength("ui_down"), Input.get_action_strength("abajo"))
	var up := maxf(Input.get_action_strength("ui_up"), Input.get_action_strength("arriba"))
	return Vector2(right - left, down - up).normalized()


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
		_resolve_hud_ref()

	if hud_ref == null:
		return 1.0

	if not hud_ref.has_method("get_energy_percent"):
		return 1.0

	var energy_percent: float = clampf(float(hud_ref.get_energy_percent()), 0.0, 100.0)
	var t: float = energy_percent / 100.0
	var curved_t: float = pow(t, energy_speed_curve_exp)
	return lerpf(min_speed_factor_at_zero_energy, 1.0, curved_t)


func _resolve_hud_ref() -> void:
	var tree := get_tree()
	if tree == null:
		return
	hud_ref = tree.get_first_node_in_group("hud")
	if hud_ref != null:
		return
	var current_scene := tree.current_scene
	if current_scene != null:
		hud_ref = current_scene.find_child("Hud", true, false)


func _get_inventory_speed_factor() -> float:
	if hud_ref == null or not hud_ref.has_method("get_speed_multiplier"):
		return 1.0
	return float(hud_ref.get_speed_multiplier())


func _apply_corner_nudge(input_vector: Vector2) -> void:
	if absf(input_vector.x) < 0.1 or absf(input_vector.y) < 0.1:
		return

	# Only nudge when the body is practically stuck after colliding.
	if get_real_velocity().length() > max_speed * 0.12:
		return

	var blocked_up := false
	var blocked_down := false
	var blocked_left := false
	var blocked_right := false

	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c == null:
			continue
		var n: Vector2 = c.get_normal()
		if n.y > 0.5:
			blocked_up = true
		elif n.y < -0.5:
			blocked_down = true
		if n.x > 0.5:
			blocked_left = true
		elif n.x < -0.5:
			blocked_right = true

	# Corner combinations requested:
	# up+left -> right, up+right -> left,
	# down+left -> right, down+right -> left.
	if input_vector.x < -0.1 and input_vector.y < -0.1 and blocked_up and blocked_left:
		global_position.x += corner_nudge_pixels
	elif input_vector.x > 0.1 and input_vector.y < -0.1 and blocked_up and blocked_right:
		global_position.x -= corner_nudge_pixels
	elif input_vector.x < -0.1 and input_vector.y > 0.1 and blocked_down and blocked_left:
		global_position.x += corner_nudge_pixels
	elif input_vector.x > 0.1 and input_vector.y > 0.1 and blocked_down and blocked_right:
		global_position.x -= corner_nudge_pixels
