extends Area2D

var flecha_actual = null
var flechas_en_zona: Array[Area2D] = []

func _on_area_entered(area):
	if area.is_in_group("flechas"):
		if not flechas_en_zona.has(area):
			flechas_en_zona.append(area)
		_refrescar_flecha_actual()

func _on_area_exited(area):
	flechas_en_zona.erase(area)
	_refrescar_flecha_actual()


func _refrescar_flecha_actual() -> void:
	var mejor: Area2D = null
	for flecha in flechas_en_zona:
		if not is_instance_valid(flecha):
			continue
		if mejor == null or flecha.global_position.y > mejor.global_position.y:
			mejor = flecha

	flecha_actual = mejor
