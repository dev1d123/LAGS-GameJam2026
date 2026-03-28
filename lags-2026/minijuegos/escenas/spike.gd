extends Area2D

@export var time_penalty: float = 10.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Play" or body.name == "Player":
		var game_manager = get_tree().current_scene.find_child("GameManager", true, false)
		if game_manager:
			game_manager.lose_time(time_penalty)
			print("¡AUCH! Menos tiempo.")
