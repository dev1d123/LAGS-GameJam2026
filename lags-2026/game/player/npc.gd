extends CharacterBody2D

const BLINK_THRESHOLD = 1.5
var blink_accum := 0.0

signal hovered(data: Dictionary)
signal unhovered

enum TipoNPC {
	ABUELA,
	ABUELO,
	JOVEN,
	NINO,
	MUJER
}

var tipo: TipoNPC
var lugar: String

var npc_nombre:      String = ""
var npc_descripcion: String = ""
var npc_edad:        int    = 0
var current_mission_id: String = ""
var mission_completed: bool = false
var mission_in_progress: bool = false
var lost_count_registered: bool = false

enum Estado {
	ENTRANDO,
	ESPERANDO,
	SALIENDO
}

const ICON_ALERT       = preload("res://assets/sprites/ui/alert.png")
const ICON_BEER        = preload("res://assets/sprites/ui/beerMInigame.png")
const ICON_CANDY       = preload("res://assets/sprites/ui/candyMinigame.png")
const ICON_CYBER       = preload("res://assets/sprites/ui/cyberMinigame.png")
const ICON_PAY  	   = preload("res://assets/sprites/ui/payServicesMInigame.png")
const ICON_INDICATIONS = preload("res://assets/sprites/ui/indicationsMinigame.png")
const ICON_SEARCH      = preload("res://assets/sprites/ui/searchMinigame.png")
const ICON_SHOP        = preload("res://assets/sprites/ui/shopServiceMinigame.png")
const ICON_WAREHOUSE   = preload("res://assets/sprites/ui/warehouseMinigame.png")

@onready var time_bar:       ProgressBar       = $TimeBar
@onready var mission_box:    Sprite2D          = $Sprite2D
@onready var detection_area: Area2D            = $Area2D
@onready var wait_timer:     Timer             = $WaitTimer
@onready var sprite:         AnimatedSprite2D  = $AnimatedSprite2D
@onready var nav_agent:      NavigationAgent2D = $NavigationAgent2D

var mis_animaciones: SpriteFrames
const speed         = 300
const STOP_DISTANCE = 12.0
var estado          = Estado.ENTRANDO

@export var pos:       Node2D
@export var posSalida: Node2D

var last_position:  Vector2
var stuck_timer:    float = 0.0
const STUCK_THRESHOLD = 1.5
const STUCK_MIN_DIST  = 2.0

# Aura
var aura_active: bool  = false
var aura_accum:  float = 0.0
const AURA_SPEED       = 3.0
const AURA_COLOR_NPC   = Color(0.4, 0.8, 1.0, 1.0)


func _on_mouse_entered() -> void:
	emit_signal("hovered", {
		"nombre":      npc_nombre,
		"edad":        npc_edad,
		"descripcion": npc_descripcion,
		"tipo":        TipoNPC.keys()[tipo]
	})

func _on_mouse_exited() -> void:
	emit_signal("unhovered")

func _on_body_entered(body: Node2D) -> void:
	if estado != Estado.ESPERANDO:
		return
	if body.is_in_group("player"):
		set_aura(true)
		body.set_aura(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_aura(false)
		body.set_aura(false)

func set_aura(value: bool) -> void:
	aura_active = value
	aura_accum  = 0.0
	if not value:
		sprite.self_modulate = Color.WHITE


func _ready() -> void:
	detection_area.mouse_entered.connect(_on_mouse_entered)
	detection_area.mouse_exited.connect(_on_mouse_exited)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	detection_area.input_pickable = true

	time_bar.max_value   = wait_timer.wait_time
	time_bar.value       = 0
	time_bar.visible     = false
	mission_box.visible  = false
	sprite.self_modulate = Color.WHITE

	if mis_animaciones:
		sprite.sprite_frames = mis_animaciones
		sprite.play()

	$Timer.timeout.connect(_on_timer_timeout)
	wait_timer.timeout.connect(_on_wait_timer_timeout)

	await get_tree().physics_frame
	make_path()


func asignar_mision() -> void:
	var icon = ICON_ALERT
	var mission_id := ""
	mission_completed = false
	lost_count_registered = false
	match lugar:
		"bar":
			if tipo == TipoNPC.ABUELO:
				icon = ICON_BEER
				mission_id = "bar_beer"
			else:
				icon = ICON_BEER
				mission_id = "bar_beer"
		"cafe":
			if tipo == TipoNPC.NINO:
				icon = ICON_CANDY
				mission_id = "cafe_candy"
			elif tipo == TipoNPC.JOVEN:
				icon = ICON_CYBER
				mission_id = "cafe_cyber"
		"restaurant":
			icon = ICON_PAY
			mission_id = "pay_services"
		"store":
			if tipo == TipoNPC.ABUELA or tipo == TipoNPC.ABUELO:
				icon = ICON_SEARCH
				mission_id = "store_search"
			else:
				icon = ICON_WAREHOUSE
				mission_id = "store_warehouse"
		"shop":
			icon = ICON_SHOP
			mission_id = "shop_service"

	if randf() < 0.2:
		icon = ICON_INDICATIONS
		mission_id = "indications"

	if mission_id == "":
		push_error("NPC sin mission_id asignado. lugar=%s tipo=%s" % [lugar, TipoNPC.keys()[tipo]])

	mission_box.texture = icon
	mission_box.visible = true
	current_mission_id = mission_id
	print("[NPC] mission assigned. lugar=", lugar, " tipo=", TipoNPC.keys()[tipo], " id=", current_mission_id)


func get_current_mission_id() -> String:
	return current_mission_id


func resolve_mission(accepted: bool) -> void:
	mission_in_progress = false
	if not accepted and not lost_count_registered:
		_register_lost_customer()
	mission_completed = accepted or lost_count_registered

	if estado != Estado.ESPERANDO:
		return

	wait_timer.stop()
	time_bar.visible = false
	mission_box.visible = false
	set_aura(false)
	estado = Estado.SALIENDO
	pos = posSalida
	make_path()


func begin_mission() -> void:
	if estado != Estado.ESPERANDO:
		return
	mission_in_progress = true
	wait_timer.stop()
	time_bar.visible = false
	mission_box.visible = false
	set_aura(false)


func finish_mission(success: bool) -> void:
	mission_in_progress = false
	# Aceptada y finalizada (ganada o fallada) no cuenta como cliente perdido.
	mission_completed = true

	if estado != Estado.ESPERANDO:
		return

	wait_timer.stop()
	time_bar.visible = false
	mission_box.visible = false
	set_aura(false)
	estado = Estado.SALIENDO
	pos = posSalida
	make_path()


func _on_wait_timer_timeout() -> void:
	if mission_in_progress:
		return
	if not lost_count_registered:
		_register_lost_customer()
	mission_completed = true
	time_bar.visible    = false
	mission_box.visible = false
	set_aura(false)
	estado = Estado.SALIENDO
	pos    = posSalida
	make_path()


func _register_lost_customer() -> void:
	if lost_count_registered:
		return
	var parent_node := get_parent()
	if parent_node != null and parent_node.has_method("add_lost"):
		parent_node.add_lost(1)
	lost_count_registered = true


func _process(delta: float) -> void:
	if aura_active:
		aura_accum += delta * AURA_SPEED
		var pulse = sin(aura_accum) * 0.5 + 0.5
		sprite.self_modulate = Color.WHITE.lerp(AURA_COLOR_NPC, pulse)

	if estado == Estado.ESPERANDO:
		var progress = wait_timer.wait_time - wait_timer.time_left
		time_bar.value = progress

		if wait_timer.time_left <= BLINK_THRESHOLD:
			blink_accum += delta * 10.0
			time_bar.visible = int(blink_accum) % 2 == 0
		else:
			time_bar.visible = true


func _physics_process(delta: float) -> void:
	z_index = int(global_position.y)
	if pos == null:
		return

	var dist_to_target = global_position.distance_to(pos.global_position)

	if dist_to_target <= STOP_DISTANCE:
		velocity = Vector2.ZERO
		move_and_slide()

		if estado == Estado.SALIENDO:
			queue_free()
			return

		if estado != Estado.ESPERANDO:
			estado = Estado.ESPERANDO
			asignar_mision()
			wait_timer.start(5)
			time_bar.max_value = wait_timer.wait_time
			time_bar.value     = 0
			time_bar.visible   = true
			blink_accum        = 0.0

		if sprite.animation != "idle":
			sprite.play("idle")
		return

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	stuck_timer += delta
	if stuck_timer >= STUCK_THRESHOLD:
		stuck_timer = 0.0
		if global_position.distance_to(last_position) < STUCK_MIN_DIST:
			make_path()
		last_position = global_position

	var next_pos = nav_agent.get_next_path_position()
	var dir      = global_position.direction_to(next_pos)
	velocity     = dir * speed
	move_and_slide()

	if velocity.length() < 1:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		if abs(velocity.x) > abs(velocity.y):
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
