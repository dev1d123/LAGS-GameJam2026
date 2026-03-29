extends CanvasLayer

func _ready():
	var so = OS.get_name()
	
	if so == "Android" or so == "iOS":
		visible = true
	else:
		visible = false
