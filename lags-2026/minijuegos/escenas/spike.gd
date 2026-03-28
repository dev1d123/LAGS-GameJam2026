extends Area2D

@export var time_penalty: float = 10.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		var game_manager = get_tree().current_scene.find_child("GameManager", true, false)
		if game_manager:
			game_manager.hit_spike(time_penalty)
