extends Node2D

signal sumar_peso_continuo(delta)
signal sumar_peso_precision()

@onready var anim = $AnimatedSprite2D

var accion_actual = "ninguna"
var bloqueado: bool = false
var base_y: float = 0.0

var audio_1: AudioStreamPlayer
var audio_2: AudioStreamPlayer
var tween_volumen: Tween
var _is_pouring_audio: bool = false

func _ready():
	base_y = anim.position.y
	
	# TRUCO DEFINITIVO PARA MP3: "PARALLEL OFFSET MASKING"
	# Creamos dos audios, y desfasamos el 2do a exactamente 
	# el 50% de la pista. Así, ¡jamás se quedarán callados al mismo tiempo!
	var snd = load("res://assets/audio/minigame-granel/arroz_cayendo.mp3")
	if snd is AudioStreamMP3:
		snd.loop = true
	
	audio_1 = AudioStreamPlayer.new()
	audio_2 = AudioStreamPlayer.new()
	for p in [audio_1, audio_2]:
		p.stream = snd
		p.bus = &"SFX"
		p.volume_db = -80.0
		add_child(p)
		p.play()
		
	# ¡La magia del desfase!
	audio_2.seek(snd.get_length() / 2.0)
	
	anim.stop()
	anim.animation = "inclinar"
	anim.frame = 0
	
	if not anim.animation_finished.is_connected(_al_terminar_animacion):
		anim.animation_finished.connect(_al_terminar_animacion)

func _process(delta):
	var espacio = Input.is_key_pressed(KEY_SPACE) and not bloqueado
	var tecla_c = Input.is_key_pressed(KEY_C) and not bloqueado

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
			
	# --- EFECTO VISUAL SACUDIDA AL VERTER ---
	var esta_vertiendo = anim.animation in ["hechar", "idle_hechando"]
	
	if esta_vertiendo:
		# Temblor rítmico basado en una onda seno sobre el tiempo de la máquina
		anim.position.y = base_y + sin(Time.get_ticks_msec() * 0.025) * 5.0
	else:
		# Regresar a la posición de descanso suavemente al terminar (Interpolación)
		anim.position.y = lerpf(anim.position.y, base_y, 15.0 * delta)
		
	# --- FADE DE AUDIO IMPENETRABLE ---
	if esta_vertiendo != _is_pouring_audio:
		_is_pouring_audio = esta_vertiendo
		# Utilizamos un volumen ligeramente reducido (-5dB) ya que se escucharán dos pistas sumadas a la vez
		var target_db = -11.0 if esta_vertiendo else -80.0
		
		if tween_volumen and tween_volumen.is_valid():
			tween_volumen.kill()
		tween_volumen = create_tween().set_parallel(true)
		
		tween_volumen.tween_property(audio_1, "volume_db", target_db, 0.15)
		tween_volumen.tween_property(audio_2, "volume_db", target_db, 0.15)


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
