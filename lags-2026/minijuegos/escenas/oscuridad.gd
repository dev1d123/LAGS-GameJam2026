extends ColorRect

var flicker_time: float = 0.0


func _process(delta: float) -> void:
	var gm = get_tree().current_scene.find_child("GameManager", true, false)
	if gm == null:
		return

	flicker_time += delta
	var stress_norm := clampf(gm.stress_difficulty / 100.0, 0.0, 1.0)
	var base_dark := lerpf(0.55, 0.88, pow(stress_norm, 0.85))
	var flicker := (sin(flicker_time * 16.0) * 0.06 + sin(flicker_time * 31.0) * 0.035) * (0.35 + stress_norm)
	var target_alpha: float = 0.0 if gm.is_light_on() else clampf(base_dark + flicker, 0.45, 0.96)
	color.a = lerpf(color.a, target_alpha, min(1.0, delta * 7.0))
	visible = color.a > 0.01
