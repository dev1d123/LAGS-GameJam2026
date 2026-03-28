extends Node2D

@onready var spawner:         Node2D = $Spawner
@onready var npc_description: Node2D = $NpcDescription

#Son Labels Hijo de npc
#$TitleLabel, $ObjetivesLabel, $DescriptionLabel, $RewardsLabel, $MoneyLabel
var frozen:       bool = false
var aura_npc_ref: Node = null


func _ready() -> void:
	npc_description.visible = false
	spawner.register_scenario(self)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_interact"):
		if aura_npc_ref != null and aura_npc_ref.aura_active:
			_toggle_freeze()
		elif frozen:
			_toggle_freeze()


func _toggle_freeze() -> void:
	frozen = not frozen
	var mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	spawner.process_mode = mode
	for child in spawner.get_children():
		child.process_mode = mode
	npc_description.visible = frozen


func set_aura_npc(npc: Node) -> void:
	aura_npc_ref = npc


func clear_aura_npc(npc: Node) -> void:
	if aura_npc_ref == npc:
		aura_npc_ref = null
