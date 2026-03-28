extends ColorRect

func _process(_delta: float) -> void:
	# Buscamos al GameManager en toda la escena actual, sin importar la ruta
	var gm = get_tree().current_scene.find_child("GameManager", true, false)
	
	if gm:
		if gm.is_light_on():
			# LUZ ENCENDIDA: Invisible (Alpha 0)
			self.color.a = 0.0
		else:
			# OSCURIDAD TOTAL: Visible (Alpha 0.9)
			self.color.a = 0.9
			# print("DEBUG: Poniendo pantalla negra") # Descomenta esto para probar
	else:
		# Si no hay GM, que no estorbe
		self.color.a = 0.0
