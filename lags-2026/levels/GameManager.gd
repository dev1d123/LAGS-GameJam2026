extends Node

var frozen:       bool = false
var aura_npc_ref: Node = null
var spawner_ref:  Node = null
var final_stress_percent: float = 0.0
var final_money: int = 0
var final_day_reached: int = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_interact"):
		if aura_npc_ref != null and aura_npc_ref.aura_active:
			_toggle_freeze()
		elif frozen:
			_toggle_freeze()

func _toggle_freeze() -> void:
	frozen = not frozen
	if spawner_ref != null:
		var mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
		spawner_ref.process_mode = mode
		for child in spawner_ref.get_children():
			child.process_mode = mode

func set_aura_npc(npc: Node) -> void:
	aura_npc_ref = npc

func clear_aura_npc(npc: Node) -> void:
	if aura_npc_ref == npc:
		aura_npc_ref = null

func register_spawner(spawner: Node) -> void:
	spawner_ref = spawner


func set_final_stats(stress_percent: float, money_amount: int, day_reached: int) -> void:
	final_stress_percent = clamp(stress_percent, 0.0, 100.0)
	final_money = max(money_amount, 0)
	final_day_reached = day_reached


func reset_final_stats() -> void:
	final_stress_percent = 0.0
	final_money = 0
	final_day_reached = 0
