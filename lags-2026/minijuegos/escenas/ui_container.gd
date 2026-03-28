extends Control

# Referencias a las etiquetas (Labels)
@onready var time_label = $TimeLabel
@onready var boxes_label = $BoxesLabel

func _process(_delta):
	# Buscamos al GameManager para pedirle la info
	var gm = get_tree().current_scene.find_child("GameMana", true, false)
	
	if gm:
		# Actualizamos el texto del tiempo (quitando los decimales feos)
		time_label.text = "TIEMPO: " + str(int(gm.get_time_left()))
		
		# Actualizamos las cajas
		boxes_label.text = "CAJAS: " + str(gm.get_boxes_collected())
