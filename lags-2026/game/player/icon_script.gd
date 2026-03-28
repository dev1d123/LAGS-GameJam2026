extends Sprite2D

func _ready() -> void:
	animar()


func animar() -> void:
	var tween = create_tween()
	tween.set_loops()

	tween.tween_property(self, "position:y", position.y - 4, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position:y", position.y, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
