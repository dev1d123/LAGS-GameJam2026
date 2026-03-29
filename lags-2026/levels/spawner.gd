extends Node2D

const NPC_SCENE = preload("res://game/player/NPC.tscn")

@export var pos:          Node2D
@export var posSalida:    Node2D
@export var player_scene: Node2D

var occupied_markers: Dictionary = {}
var npc_data:         Dictionary = {}
var active_types:     Dictionary = {}
var active_names:     Dictionary = {}

var sprite_paths: Dictionary = {
	"abuela": [
		"res://game/enemies/abuela1.tres",
		"res://game/enemies/abuela2.tres",
		"res://game/enemies/abuela3.tres"
	],
	"abuelo": [
		"res://game/enemies/abuelo1.tres",
		"res://game/enemies/abuelo2.tres",
		"res://game/enemies/abuelo3.tres"
	],
	"joven": [
		"res://game/enemies/joven1.tres",
		"res://game/enemies/joven2.tres",
		"res://game/enemies/joven3.tres"
	],
	"niño": [
		"res://game/enemies/niño1.tres",
		"res://game/enemies/niño2.tres",
		"res://game/enemies/niño3.tres"
	],
	"mujer": [
		"res://game/enemies/mujer1.tres",
		"res://game/enemies/mujer2.tres",
		"res://game/enemies/mujer3.tres"
	]
}

const TIPO_MAP = {
	"abuela": 0,
	"abuelo": 1,
	"joven":  2,
	"niño":   3,
	"mujer":  4
}

const LUGARES_POR_TIPO = {
	0: ["restaurant", "shop"],
	1: ["bar", "store"],
	2: ["cafe", "bar", "store"],
	3: ["cafe"],
	4: ["shop", "restaurant"]
}

@onready var toast:      Node2D           = $Node2DLayer/Node2D
@onready var box_sprite: AnimatedSprite2D = $Node2DLayer/Node2D/box
@onready var name_label: Label            = $Node2DLayer/Node2D/name
@onready var age_label:  Label            = $Node2DLayer/Node2D/age
@onready var desc_label: Label            = $Node2DLayer/Node2D/desc
@onready var hud: Node                    = $HUDLayer/Hud

var toast_origin: Vector2

var scenario_ref: Node = null

func register_scenario(scenario: Node) -> void:
	scenario_ref = scenario


func add_money(cantidad: int) -> void:
	if hud != null and hud.has_method("actualizar_dinero"):
		hud.actualizar_dinero(cantidad)


func add_lost(cantidad: int) -> void:
	if hud != null and hud.has_method("actualizar_perdidos"):
		hud.actualizar_perdidos(cantidad)


func _ready() -> void:
	_load_npc_data()
	toast_origin  = toast.position
	toast.visible = false

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.timeout.connect(_spawn_npc)
	timer.start()
	_spawn_npc()


func _load_npc_data() -> void:
	var file = FileAccess.open("res://data/localization/npc_data.json", FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir npc_data.json")
		return
	var json   = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()
	if result != OK:
		push_error("Error al parsear npc_data.json")
		return
	npc_data = json.get_data().get("npc", {})


func _get_random_npc_entry(tipo_key: String) -> Dictionary:
	var lista: Array = npc_data.get(tipo_key, [])
	if lista.is_empty():
		return {}
	return lista.pick_random()


func _get_unique_entry_for_tipo(tipo_key: String, lang: String) -> Dictionary:
	var lista: Array = npc_data.get(tipo_key, [])
	if lista.is_empty():
		return {}

	var candidates: Array = []
	for entry in lista:
		if not (entry is Dictionary):
			continue
		var nombre_dict: Dictionary = entry.get("nombre", {})
		var npc_name := str(nombre_dict.get(lang, nombre_dict.get("es", "")))
		if npc_name == "":
			continue
		if not active_names.has(npc_name):
			candidates.append(entry)

	if candidates.is_empty():
		return {}

	return candidates.pick_random()


func get_random_marker_by_tipo(tipo: int) -> Node2D:
	var lugar_names: Array = LUGARES_POR_TIPO.get(tipo, [])
	var markers: Array[Node2D] = []

	for nombre in lugar_names:
		var lugar_node = get_node_or_null(nombre)
		if lugar_node == null:
			continue
		for child in lugar_node.get_children():
			if child is Marker2D and not occupied_markers.has(child):
				markers.append(child)

	if markers.is_empty():
		return null
	return markers.pick_random()


func _spawn_npc() -> void:
	var tipos_keys: Array = []
	for key in TIPO_MAP.keys():
		var tipo_id: int = TIPO_MAP[key]
		if not active_types.has(tipo_id):
			tipos_keys.append(key)
	tipos_keys.shuffle()

	if tipos_keys.is_empty():
		return

	var lang = LocaleManager.current_language

	var tipo_key: String = ""
	var marker:   Node2D = null
	var entry:    Dictionary = {}

	for key in tipos_keys:
		var tipo_int  = TIPO_MAP[key]
		var selected_entry: Dictionary = _get_unique_entry_for_tipo(key, lang)
		if selected_entry.is_empty():
			continue
		var candidate = get_random_marker_by_tipo(tipo_int)
		if candidate != null:
			tipo_key = key
			marker   = candidate
			entry    = selected_entry
			break

	if tipo_key == "" or marker == null:
		print("No hay combinaciones disponibles (tipo/marker/nombre único)")
		return

	var tipo_int = TIPO_MAP[tipo_key]

	var sprites_tipo: Array  = sprite_paths.get(tipo_key, [])
	var sprite_path:  String = ""
	var variacion:    int    = entry.get("variacion", 1) - 1
	if variacion >= 0 and variacion < sprites_tipo.size():
		sprite_path = sprites_tipo[variacion]
	else:
		sprite_path = sprites_tipo.pick_random()

	var npc = NPC_SCENE.instantiate()
	npc.hovered.connect(_on_npc_hovered)
	npc.unhovered.connect(_on_npc_unhovered)
	npc.scale           = Vector2(1.72, 1.72)
	npc.mis_animaciones = load(sprite_path)
	npc.tipo            = tipo_int
	npc.pos             = marker
	npc.posSalida       = posSalida
	npc.lugar           = marker.get_parent().name

	var nombre_dict     = entry.get("nombre", {})
	var desc_dict       = entry.get("descripcion", {})
	npc.npc_nombre      = nombre_dict.get(lang, nombre_dict.get("es", "???"))
	npc.npc_descripcion = desc_dict.get(lang, desc_dict.get("es", ""))
	npc.npc_edad        = entry.get("edad", 0)

	print("Spawning NPC [%s] %s (edad %d) -> %s" % [tipo_key, npc.npc_nombre, npc.npc_edad, npc.lugar])

	occupied_markers[marker] = npc
	active_types[tipo_int] = true
	active_names[npc.npc_nombre] = true
	add_child(npc)
	npc.global_position = $Marker2DEnter.global_position

	npc.detection_area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player") and npc.estado == npc.Estado.ESPERANDO:
			scenario_ref.set_aura_npc(npc)
	)
	npc.detection_area.body_exited.connect(func(body: Node2D):
		if body.is_in_group("player"):
			scenario_ref.clear_aura_npc(npc)
	)

	npc.tree_exited.connect(func():
		if npc.estado == npc.Estado.SALIENDO and not npc.mission_completed:
			add_lost(1)
		occupied_markers.erase(marker)
		active_types.erase(tipo_int)
		active_names.erase(npc.npc_nombre)
		scenario_ref.clear_aura_npc(npc)
	)


func _on_npc_hovered(data: Dictionary) -> void:
	name_label.text = data.get("nombre", "")
	age_label.text  = str(data.get("edad", ""))
	desc_label.text = data.get("descripcion", "")
	toast.visible   = true
	toast.position  = toast_origin + Vector2(0, 20)

	var tween = create_tween()
	tween.tween_property(toast, "position", toast_origin, 0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_npc_unhovered() -> void:
	var tween = create_tween()
	tween.tween_property(toast, "position", toast_origin + Vector2(0, 20), 0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		toast.visible = false
	)
