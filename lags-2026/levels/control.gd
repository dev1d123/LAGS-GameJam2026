extends CanvasLayer

func _ready():
	visible = false
	
	if DisplayServer.is_touchscreen_available():
		visible = true
