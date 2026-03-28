extends ColorRect

func _process(_delta):
	# Buscamos al GameManager en la escena
	var gm = get_tree().current_scene.find_child("GameManager", true, false)
	
	if gm:
		# Si la luz está encendida, hacemos el cuadro invisible
		if gm.is_light_on():
			self.visible = false
		else:
			# Si se apaga la luz, lo mostramos
			self.visible = true
