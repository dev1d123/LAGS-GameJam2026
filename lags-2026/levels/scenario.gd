extends Node2D

const NPC_SCENE = preload("res://game/player/NPC.tscn")

@export var pos: Node2D
@export var posSalida: Node2D

var sprite_paths: Array[String] = [
	"res://game/enemies/abuela1.tres", "res://game/enemies/abuela2.tres", "res://game/enemies/abuela3.tres",
	"res://game/enemies/abuelo1.tres", "res://game/enemies/abuelo2.tres", "res://game/enemies/abuelo3.tres",
	"res://game/enemies/joven1.tres", "res://game/enemies/joven2.tres", "res://game/enemies/joven3.tres",
	"res://game/enemies/mujer1.tres", "res://game/enemies/mujer2.tres", "res://game/enemies/mujer3.tres",
	"res://game/enemies/niño1.tres", "res://game/enemies/niño2.tres", "res://game/enemies/niño3.tres"
]
func get_random_marker_by_tipo(tipo: int) -> Node2D:
	var lugares = []

	match tipo:
		0: # ABUELA
			lugares = [$restaurant, $shop]
		1: # ABUELO
			lugares = [$bar, $store]
		2: # JOVEN
			lugares = [$cafe, $bar, $store]
		3: # NINO
			lugares = [$cafe]
		4: # MUJER
			lugares = [$shop, $restaurant]

	var markers: Array[Node2D] = []

	for lugar in lugares:
		for child in lugar.get_children():
			if child is Marker2D:
				markers.append(child)

	if markers.is_empty():
		print("No hay markers")
		return null

	return markers.pick_random()
	
	
func get_tipo_from_path(path: String) -> int:
	if path.contains("abuela"):
		return 0
	elif path.contains("abuelo"):
		return 1
	elif path.contains("joven"):
		return 2
	elif path.contains("niño"):
		return 3
	elif path.contains("mujer"):
		return 4
	
	return 2
func _ready() -> void:

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_spawn_npc)
	timer.start()
	_spawn_npc()
#
func _spawn_npc() -> void:
	var npc = NPC_SCENE.instantiate()
	npc.scale = Vector2(1.72, 1.72)
	var random_sprite = sprite_paths.pick_random()
	npc.mis_animaciones = load(random_sprite)

	# 🔴 definir tipo
	var tipo = get_tipo_from_path(random_sprite)
	npc.tipo = tipo

	# 🔴 definir destino según tipo
	var random_marker = get_random_marker_by_tipo(tipo)
	npc.pos = random_marker
	npc.posSalida = posSalida
	# 🔴 guardar nombre del lugar
	if random_marker != null:
		npc.lugar = random_marker.get_parent().name
	print("NPC tipo:", npc.tipo, "-> va a:", npc.lugar)
	add_child(npc)
	move_child(npc, 1)
	npc.global_position = $Marker2DEnter.global_position
