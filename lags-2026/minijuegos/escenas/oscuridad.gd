extends ColorRect

func _process(delta: float) -> void:
	var gm = get_tree().current_scene.find_child("GameManager", true, false)
	if gm == null:
		return

	var target_alpha: float = 0.0 if gm.is_light_on() else 0.78
	color.a = lerpf(color.a, target_alpha, min(1.0, delta * 7.0))
	visible = color.a > 0.01
