extends Control

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.animation_finished.connect(_on_anim_finished)
	anim.play("fade")

func _on_anim_finished(_anim_name: String) -> void:
	# En Godot 4, así se cambia de escena de forma segura
	get_tree().change_scene_to_file("res://ui/screens/main_menu.tscn")
