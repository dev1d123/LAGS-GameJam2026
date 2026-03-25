extends Control

@onready var options_overlay = $OptionsOverlay
@onready var options_menu = $OptionsOverlay/Options_Menu
@onready var options_bg = $OptionsOverlay/ColorRect

func _ready() -> void:
	$InteractablesLayer/Btn_Options.pressed.connect(_on_btn_options_pressed)
	options_overlay.hide()
	options_menu.modulate.a = 0.0
	options_bg.color.a = 0.0
	options_menu.menu_closed.connect(_on_options_closed)

func _process(delta: float) -> void:
	pass
	
func _on_btn_options_pressed() -> void:
	options_menu.load_current_settings()
	options_overlay.show()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(options_bg, "color:a", 0.705, 0.1)
	tween.tween_property(options_menu, "modulate:a", 1.0, 0.1)

func _on_options_closed() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(options_bg, "color:a", 0.0, 0.05)
	tween.tween_property(options_menu, "modulate:a", 0.0, 0.05)
	tween.chain().tween_callback(options_overlay.hide)

func _on_btn_exit_pressed() -> void:
	get_tree().quit()
