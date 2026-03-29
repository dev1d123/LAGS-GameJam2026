extends Node2D

signal minigame_finished(success: bool, score: int, total_rounds: int)

@export var flecha_scene: PackedScene
@export var puntos_victoria: int = 10
@export var limite_errores: int = 10

const UI_PANEL_TEXTURE := preload("res://assets/textures/opciones-campo-fondo.png")
const UI_BG_TEXTURE := preload("res://assets/textures/opciones-fondo.png")
const UI_BUTTON_TEXTURE := preload("res://assets/textures/button_2.png")
const UI_FONT := preload("res://assets/fonts/PixelOperatorMonoHB.ttf")
const ICON_SUCCESS := preload("res://scenes/minigameIndications/FlechaDerecha.png")
const ICON_FAIL := preload("res://scenes/minigameIndications/FlechaBajo.png")
const STRESS_SHADER := preload("res://assets/shaders/stress_indications.gdshader")

var direcciones = ["arriba", "abajo", "izquierda", "derecha"]
var puntos = 0
var errores = 0
var estres_actual = 0.0
var current_language = "es"
var juego_activo = false
var is_finishing = false
var results_overlay: ColorRect = null
var results_won: bool = false
var results_closing: bool = false
var desempeno: float = 0.0
var eficiencia: float = 0.0
var recompensa_total: int = 0
var estres: float = 0.0
var stress_difficulty: float = 0.0
var mission_money_min: int = 0
var mission_money_max: int = 0
var results_summary_label: Label = null
var stress_fx_overlay: ColorRect = null
var stress_fx_material: ShaderMaterial = null
var stress_fx_time: float = 0.0

@onready var sprite_cabeza = $CanvasLayer/MainPanel/Margin/VBox/Content/CenterPanel/PlayField/GameArea/FondoModal/HitZone/SpriteCabeza

@onready var spawn_timer = $SpawnTimer
@onready var canvas_layer = $CanvasLayer
@onready var game_area: Control = $CanvasLayer/MainPanel/Margin/VBox/Content/CenterPanel/PlayField/GameArea
@onready var fondo_modal = $CanvasLayer/MainPanel/Margin/VBox/Content/CenterPanel/PlayField/GameArea/FondoModal
@onready var label_pregunta = $CanvasLayer/MainPanel/Margin/VBox/Content/CenterPanel/QuestionPanel/LabelPregunta
@onready var barra_progreso = $CanvasLayer/MainPanel/Margin/VBox/Content/CenterPanel/ProgressPanel/BarraProgreso
@onready var flash_rojo = $CanvasLayer/MainPanel/Margin/VBox/Content/CenterPanel/PlayField/GameArea/FlashRojo
@onready var score_label = $CanvasLayer/MainPanel/Margin/VBox/Content/RightPanel/StatePanel/StateVBox/ScoreLabel
@onready var errors_label = $CanvasLayer/MainPanel/Margin/VBox/Content/RightPanel/StatePanel/StateVBox/ErrorsLabel
@onready var stress_label = $CanvasLayer/MainPanel/Margin/VBox/Content/RightPanel/StatePanel/StateVBox/StressLabel
@onready var speed_label = $CanvasLayer/MainPanel/Margin/VBox/Content/RightPanel/StatePanel/StateVBox/SpeedLabel

@onready var sfx_open = $SfxOpen
@onready var sfx_close = $SfxClose
@onready var sfx_success = $SfxSuccess
@onready var sfx_error = $SfxError

var lista_preguntas = []

func _ready():
	estres_actual = 50
	_setup_stress_shader()
	current_language = LocaleManager.current_language
	_apply_ui_font_overrides()
	if speed_label != null:
		speed_label.visible = false
	
	if barra_progreso:
		barra_progreso.max_value = puntos_victoria
		barra_progreso.value = 0
	_update_status_panel()
	
	load_questions()
	await iniciar_secuencia_entrada()


func _process(delta: float) -> void:
	_update_stress_shader(delta)

func iniciar_secuencia_entrada():
	if sfx_open: sfx_open.play()
	mostrar_instruccion_principal()
	await get_tree().create_timer(1.2).timeout
	juego_activo = true
	spawn_timer.start()

func load_questions():
	var file_path = "res://scenes/minigameIndications/preguntas_indicaciones.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var json = JSON.parse_string(json_text)
		if json and json.has("preguntas"):
			lista_preguntas = json["preguntas"]

func mostrar_instruccion_principal() -> void:
	var text := ""
	match current_language:
		"en":
			text = "Press the matching arrow when it enters the zone. Red arrows are fake: ignore them."
		"pt":
			text = "Aperte a seta correspondente quando entrar na zona. Setas vermelhas sao falsas: ignore."
		_:
			text = "Presiona la flecha correcta cuando entre en la zona. Las flechas rojas son falsas: ignoralas."

	label_pregunta.text = text
	label_pregunta.visible_ratio = 0
	var tween = create_tween()
	tween.tween_property(label_pregunta, "visible_ratio", 1.0, 0.4)

func _on_spawn_timer_timeout():
	if !juego_activo: return 

	var nuevo_wait = 1.0
	if estres_actual <= 20: nuevo_wait = 1.0
	elif estres_actual <= 40: nuevo_wait = 0.8
	elif estres_actual <= 60: nuevo_wait = 0.5
	else: nuevo_wait = 0.4
	
	spawn_timer.wait_time = nuevo_wait
	_update_status_panel()
	crear_flecha()


func _setup_stress_shader() -> void:
	var shader_host: Control = game_area if game_area != null else null
	if shader_host == null:
		return
	stress_fx_overlay = ColorRect.new()
	stress_fx_overlay.name = "StressFXOverlay"
	stress_fx_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stress_fx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stress_fx_overlay.color = Color(1, 1, 1, 0)
	stress_fx_overlay.z_index = 300
	stress_fx_material = ShaderMaterial.new()
	stress_fx_material.shader = STRESS_SHADER
	stress_fx_overlay.material = stress_fx_material
	shader_host.add_child(stress_fx_overlay)
	shader_host.move_child(stress_fx_overlay, shader_host.get_child_count() - 1)
	stress_fx_material.set_shader_parameter("intensity", _stress_to_power())


func _update_stress_shader(delta: float) -> void:
	if stress_fx_material == null:
		return
	stress_fx_time += delta
	stress_fx_material.set_shader_parameter("time_sec", stress_fx_time)


func _stress_to_power() -> float:
	var normalized := clampf(stress_difficulty / 100.0, 0.0, 1.0)
	return clampf(pow(normalized, 0.82) * 2.0, 0.0, 2.0)

func crear_flecha():
	var nueva_flecha = flecha_scene.instantiate()
	var dir = direcciones.pick_random()
	nueva_flecha.direccion = dir

	var v_min = 300.0; var v_max = 300.0
	var prob_falsa = 0.15

	if estres_actual > 20 and estres_actual <= 40:
		v_min = 250.0; v_max = 450.0; prob_falsa = 0.2
	elif estres_actual > 40:
		v_min = 200.0; v_max = 550.0; prob_falsa = 0.25

	nueva_flecha.velocidad = randf_range(v_min, v_max)
	nueva_flecha.tiene_parpadeo = false
	if randf() < prob_falsa:
		nueva_flecha.es_falsa = true

	nueva_flecha.se_paso.connect(_on_flecha_pasada)

	fondo_modal.add_child(nueva_flecha)
	configurar_posicion_flecha(nueva_flecha, nueva_flecha.direccion)

func _on_flecha_pasada():
	if juego_activo:
		registrar_error()

func configurar_posicion_flecha(f, d):
	var spawn_point = fondo_modal.get_node("SpawnPoint")
	var pos_inicial = spawn_point.position
	var separacion = 60

	match d:
		"izquierda": f.position = Vector2(pos_inicial.x - (separacion * 1.5), pos_inicial.y)
		"arriba": f.position = Vector2(pos_inicial.x - (separacion * 0.5), pos_inicial.y)
		"abajo": f.position = Vector2(pos_inicial.x + (separacion * 0.5), pos_inicial.y)
		"derecha": f.position = Vector2(pos_inicial.x + (separacion * 1.5), pos_inicial.y)

func _input(event):
	if results_overlay != null:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_interact"):
			_on_results_continue_pressed()
			return

	for dir in direcciones:
		if event.is_action_pressed(dir):
			validar_hit(dir)

func validar_hit(dir_presionada):
	if !juego_activo: return
	
	var zona = fondo_modal.get_node("HitZone")
	if zona and zona.flecha_actual:
		if zona.flecha_actual.direccion == dir_presionada and !zona.flecha_actual.es_falsa:
			animar_cabeza_acierto()
			
			if sfx_success:
				sfx_success.pitch_scale = randf_range(0.9, 1.1)
				sfx_success.play()
				
			zona.flecha_actual.queue_free()
			zona.flecha_actual = null
			puntos += 1
			estres_actual = clampf(estres_actual - 4.0, 0.0, 100.0)
			actualizar_barra()
			_update_status_panel()
			verificar_victoria()
		else:
			registrar_error()
			animar_cabeza_error()
			zona.flecha_actual.queue_free()
			zona.flecha_actual = null
	else:
		_show_quick_feedback_no_arrow()


func _show_quick_feedback_no_arrow() -> void:
	var old_modulate: Color = label_pregunta.modulate
	label_pregunta.modulate = Color(1.0, 0.85, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(label_pregunta, "modulate", old_modulate, 0.2)

func animar_cabeza_acierto():
	var tween = create_tween()
	tween.tween_property(sprite_cabeza, "scale", Vector2(1.2, 0.8), 0.05)
	tween.tween_property(sprite_cabeza, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_ELASTIC)

func animar_cabeza_error():
	var tween = create_tween()
	sprite_cabeza.modulate = Color(1, 0, 0)
	tween.tween_property(sprite_cabeza, "modulate", Color(1, 1, 1), 0.2)

func registrar_error():
	if !juego_activo: return
	
	if sfx_error: sfx_error.play()
	errores += 1
	estres_actual = clampf(estres_actual + 6.0, 0.0, 100.0)
	_update_status_panel()
	
	if flash_rojo:
		var tween = create_tween()
		flash_rojo.modulate.a = 0.4 
		tween.tween_property(flash_rojo, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	if errores >= limite_errores:
		perder_juego()

func actualizar_barra():
	if barra_progreso:
		var tween = create_tween()
		tween.tween_property(barra_progreso, "value", puntos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func verificar_victoria():
	if puntos >= puntos_victoria:
		finalizar_partida(true)

func perder_juego():
	finalizar_partida(false)

func finalizar_partida(ganado: bool):
	if is_finishing:
		return
	is_finishing = true
	eficiencia = clamp((float(puntos) / max(1.0, float(puntos_victoria))) * 100.0, 0.0, 100.0)
	desempeno = clamp((float(errores) / max(1.0, float(limite_errores))) * 100.0, 0.0, 100.0)
	estres = lerpf(2.0, 22.0, desempeno / 100.0)
	recompensa_total = _calc_recompensa_from_eficiencia()

	juego_activo = false 
	spawn_timer.stop()

	for f in fondo_modal.get_children():
		if f.is_in_group("flechas"): 
			f.queue_free()
	
	if sfx_close and sfx_close.stream != null:
		sfx_close.play()
	
	if ganado: print("¡Victoria!")
	else: print("Derrota...")

	if sfx_close and sfx_close.playing:
		await sfx_close.finished
	_on_results_continue_pressed()


func _show_results_modal(ganado: bool) -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_results_overlay_gui_input)
	canvas_layer.add_child(overlay)
	results_overlay = overlay
	results_won = ganado

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 320)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_top = -160
	panel.offset_right = 280
	panel.offset_bottom = 160
	panel.add_theme_stylebox_override("panel", _make_ui_box(UI_BG_TEXTURE, Color(1, 1, 1, 1)))
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 24
	content.offset_top = 20
	content.offset_right = -24
	content.offset_bottom = -20
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title_card := PanelContainer.new()
	title_card.add_theme_stylebox_override("panel", _make_ui_box(UI_PANEL_TEXTURE, Color(2.0, 1.8, 1.2, 1.0)))
	content.add_child(title_card)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	title_card.add_child(title_row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(38, 38)
	icon.texture = ICON_SUCCESS if ganado else ICON_FAIL
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_row.add_child(icon)

	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_color_override("font_color", Color(0.69, 0.64, 0.63, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.19, 0.08, 0.0, 1.0))
	title.add_theme_constant_override("outline_size", 7)
	title.text = _results_title_text(ganado)
	title_row.add_child(title)

	var body_card := PanelContainer.new()
	body_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_card.add_theme_stylebox_override("panel", _make_ui_box(UI_PANEL_TEXTURE, Color(1, 1, 1, 1)))
	content.add_child(body_card)

	var summary := Label.new()
	summary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	summary.offset_left = 14
	summary.offset_top = 14
	summary.offset_right = -14
	summary.offset_bottom = -14
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.add_theme_font_size_override("font_size", 24)
	summary.add_theme_font_override("font", UI_FONT)
	summary.add_theme_color_override("font_color", Color(0.69, 0.64, 0.63, 1.0))
	summary.add_theme_color_override("font_outline_color", Color(0.19, 0.08, 0.0, 1.0))
	summary.add_theme_constant_override("outline_size", 5)
	summary.text = _results_body_text()
	body_card.add_child(summary)
	results_summary_label = summary

	var continue_button := Button.new()
	continue_button.text = _continue_text()
	continue_button.custom_minimum_size = Vector2(0, 56)
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.add_theme_font_override("font", UI_FONT)
	continue_button.add_theme_font_size_override("font_size", 30)
	continue_button.add_theme_color_override("font_color", Color(0.69, 0.64, 0.63, 1.0))
	continue_button.add_theme_color_override("font_hover_color", Color(0.69, 0.64, 0.63, 1.0))
	continue_button.add_theme_color_override("font_pressed_color", Color(0.69, 0.64, 0.63, 1.0))
	continue_button.add_theme_stylebox_override("normal", _make_button_box(Color(1, 1, 1, 1)))
	continue_button.add_theme_stylebox_override("hover", _make_button_box(Color(0.8, 0.72, 0.78, 1)))
	continue_button.add_theme_stylebox_override("pressed", _make_button_box(Color(0.6, 0.5, 0.56, 1)))
	continue_button.pressed.connect(_on_results_continue_pressed)
	content.add_child(continue_button)
	continue_button.grab_focus()


func _on_results_overlay_gui_input(event: InputEvent) -> void:
	if results_overlay == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_results_continue_pressed()


func _make_ui_box(texture: Texture2D, modulate_color: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = 30
	box.texture_margin_top = 20
	box.texture_margin_right = 30
	box.texture_margin_bottom = 20
	box.modulate_color = modulate_color
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return box


func _make_button_box(modulate_color: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = UI_BUTTON_TEXTURE
	box.texture_margin_left = 30
	box.texture_margin_top = 20
	box.texture_margin_right = 30
	box.texture_margin_bottom = 25
	box.modulate_color = modulate_color
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return box


func _results_title_text(ganado: bool) -> String:
	match current_language:
		"en":
			return "Success" if ganado else "Failed"
		"pt":
			return "Sucesso" if ganado else "Falhou"
		_:
			return "Exito" if ganado else "Fallaste"


func _results_body_text() -> String:
	match current_language:
		"en":
			return "Score: %d/%d\nMistakes: %d/%d\nFinal stress: %d%%" % [puntos, puntos_victoria, errores, limite_errores, int(round(estres_actual))]
		"pt":
			return "Pontos: %d/%d\nErros: %d/%d\nEstresse final: %d%%" % [puntos, puntos_victoria, errores, limite_errores, int(round(estres_actual))]
		_:
			return "Puntos: %d/%d\nErrores: %d/%d\nEstres final: %d%%" % [puntos, puntos_victoria, errores, limite_errores, int(round(estres_actual))]


func _continue_text() -> String:
	match current_language:
		"en":
			return "Continue"
		"pt":
			return "Continuar"
		_:
			return "Continuar"


func _on_results_continue_pressed() -> void:
	if results_closing:
		return
	results_closing = true

	if results_overlay != null and is_instance_valid(results_overlay):
		results_overlay.queue_free()
	results_overlay = null
	results_summary_label = null
	emit_signal("minigame_finished", results_won, puntos, puntos_victoria)
	queue_free()


func _calc_recompensa_from_eficiencia() -> int:
	var min_money: int = mission_money_min
	var max_money: int = max(mission_money_min, mission_money_max)
	return int(round(lerpf(float(min_money), float(max_money), clamp(eficiencia / 100.0, 0.0, 1.0))))


func _apply_ui_font_overrides() -> void:
	for label in [score_label, errors_label, stress_label, speed_label]:
		if label != null:
			label.add_theme_font_override("font", UI_FONT)
			label.add_theme_font_size_override("font_size", 26)
			label.add_theme_color_override("font_color", Color(0.687779, 0.643646, 0.632612, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.189829, 0.0827736, 0.0013467, 1.0))
			label.add_theme_constant_override("outline_size", 6)

	if label_pregunta != null:
		label_pregunta.add_theme_font_override("normal_font", UI_FONT)
		label_pregunta.add_theme_font_override("bold_font", UI_FONT)
		label_pregunta.add_theme_font_override("bold_italics_font", UI_FONT)
		label_pregunta.add_theme_font_override("italics_font", UI_FONT)
		label_pregunta.add_theme_font_override("mono_font", UI_FONT)


func _update_status_panel() -> void:
	score_label.text = "PUNTOS: %d/%d" % [puntos, puntos_victoria]
	errors_label.text = "ERRORES: %d/%d" % [errores, limite_errores]
	stress_label.text = "ESTRES: %d%%" % int(round(estres_actual))
	if speed_label != null:
		speed_label.text = ""
