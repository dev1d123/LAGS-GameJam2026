extends Node2D

const NPC_SCENE = preload("res://game/player/NPC.tscn")
@export var player: Node2D
var sprite_paths: Array[String] = [
	"res://game/enemies/abuela1.tres", "res://game/enemies/abuela2.tres", "res://game/enemies/abuela3.tres",
	"res://game/enemies/abuelo1.tres", "res://game/enemies/abuelo2.tres", "res://game/enemies/abuelo3.tres",
	"res://game/enemies/joven1.tres", "res://game/enemies/joven2.tres", "res://game/enemies/joven3.tres",
	"res://game/enemies/mujer1.tres", "res://game/enemies/mujer2.tres", "res://game/enemies/mujer3.tres",
	"res://game/enemies/niño1.tres", "res://game/enemies/niño2.tres", "res://game/enemies/niño3.tres"
]

var npc_data: Dictionary = {}

func _ready() -> void:

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.timeout.connect(_spawn_npc)
	timer.start()
	_spawn_npc()
#
func _spawn_npc() -> void:
	var npc = NPC_SCENE.instantiate()
	npc.scale = Vector2(1.72, 1.72)
	var random_sprite = sprite_paths.pick_random()
	npc.mis_animaciones = load(random_sprite)
	npc.player = player 
	add_child(npc)

	npc.global_position = $Marker2DEnter.global_position
