extends Node2D

signal sumar_peso_continuo(delta)
signal sumar_peso_precision()

@onready var anim = $AnimatedSprite2D

var accion_actual = "ninguna" # Puede ser: "continuo", "precision", o "ninguna"

func _ready():
	anim.stop()
	anim.animation = "inclinar"
	anim.frame = 0
	
	if not anim.animation_finished.is_connected(_al_terminar_animacion):
		anim.animation_finished.connect(_al_terminar_animacion)

func _process(delta):
	var espacio = Input.is_key_pressed(KEY_SPACE)
	var tecla_c = Input.is_key_pressed(KEY_C)

	# 1. SUMAR PESO CONTINUAMENTE
	if anim.animation == "idle_hechando" and accion_actual == "continuo":
		sumar_peso_continuo.emit(delta)

	# 2. SOLTAR ESPACIO (Interrupción en cascada)
	if accion_actual == "continuo":
		if not espacio:
			accion_actual = "ninguna"
			_regresar_secuencia()
			
	# Nota clave: Si la acción es "precision" (C), NO verificamos si soltaste la tecla aquí. 
	# Obligamos al código a terminar el ciclo de ida sí o sí.

	# 3. INICIAR ACCIONES (Solo si el saco está libre o guardándose)
	if accion_actual == "ninguna":
		if espacio:
			accion_actual = "continuo"
			_avanzar_secuencia()
		elif tecla_c:
			accion_actual = "precision"
			_avanzar_secuencia()


# --- RUTAS DE ANIMACIÓN ---

func _avanzar_secuencia():
	var act = anim.animation
	if act == "idle_hechando": return # Ya está al máximo
	
	if act == "inclinar" and anim.frame == 0:
		anim.play("inclinar") # Arranca limpio desde 0
	else:
		anim.play(act) # Si estaba retrocediendo, lo empuja hacia adelante de nuevo

func _regresar_secuencia():
	var act = anim.animation
	if act == "idle_hechando":
		anim.play_backwards("hechar") # Rompe el bucle infinito y empieza el retorno
	else:
		anim.play_backwards(act) # Da reversa inmediata a donde sea que esté


# --- EL ORDEN ESTRICTO DE LA CASCADA ---

func _al_terminar_animacion():
	var act = anim.animation
	
	# Truco Pro: Si una animación termina en un frame mayor a 0, iba hacia adelante.
	# Si termina en el frame 0, significa que terminó de dar reversa.
	var termino_hacia_adelante = (anim.frame > 0) 

	# --- RUTA DE IDA ---
	if termino_hacia_adelante:
		if act == "inclinar":
			anim.play("hechar") # Siguiente paso
			
		elif act == "hechar":
			if accion_actual == "continuo":
				anim.play("idle_hechando") # Entra al chorro infinito
				
			elif accion_actual == "precision":
				# ¡AQUÍ! Solo emite el peso exactamente al terminar de 'hechar'
				sumar_peso_precision.emit() 
				anim.play_backwards("hechar") # Inmediatamente empieza a regresar

	# --- RUTA DE REGRESO ---
	else:
		if act == "hechar":
			# Si estabas manteniendo 'C' presionada, repite el chorrito en bucle
			if accion_actual == "precision" and Input.is_key_pressed(KEY_C):
				anim.play("hechar") 
			else:
				# Si soltaste 'C', o si venías regresando de usar 'Espacio', continúa la cascada
				if accion_actual == "precision":
					accion_actual = "ninguna" # Libera el control
				anim.play_backwards("inclinar") 
		
		elif act == "inclinar":
			# Llegó al frame 0 absoluto. Está en reposo total.
			pass
