extends Area2D

var flecha_actual = null

func _on_area_entered(area):
	if area.is_in_group("flechas"):
		flecha_actual = area

func _on_area_exited(area):
	if flecha_actual == area:
		flecha_actual = null
