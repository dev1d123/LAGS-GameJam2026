extends Area2D

signal se_paso

@export var tex_arriba: Texture2D
@export var tex_abajo: Texture2D
@export var tex_izquierda: Texture2D
@export var tex_derecha: Texture2D

var direccion = ""
var velocidad = 300.0
var tiene_parpadeo = false
var es_falsa = false

@onready var sprite = $Sprite2D

func _ready():
	match direccion:
		"arriba": sprite.texture = tex_arriba
		"abajo": sprite.texture = tex_abajo
		"izquierda": sprite.texture = tex_izquierda
		"derecha": sprite.texture = tex_derecha
	
	if es_falsa:
		modulate = Color(1, 0.3, 0.3)

	modulate.a = 1.0
	
	if tiene_parpadeo:
		iniciar_parpadeo()

func _process(delta):
	position.y += velocidad * delta
	if position.y > 560:
		if !es_falsa:
			se_paso.emit()
		queue_free()

func iniciar_parpadeo():
	# Se conserva el metodo por compatibilidad, pero sin variar alpha.
	return
