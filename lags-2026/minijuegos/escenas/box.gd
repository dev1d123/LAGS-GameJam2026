extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Play" or body.name == "Player":
		var game_manager = get_tree().current_scene.find_child("GameManager", true, false)
		if game_manager:
			game_manager.collect_box()
			queue_free()
