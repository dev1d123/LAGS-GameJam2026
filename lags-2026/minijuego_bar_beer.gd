extends Control

signal minigame_finished(success: bool, score: int, total_rounds: int)

const I18N_CATEGORY := "minigame_bar_beer"
const BEER_JAR_TEXTURE := preload("res://assets/sprites/beer_jar.png")
const SFX_SUCCESS_STREAM := preload("res://scenes/minigameIndications/success.ogg")
const SFX_ERROR_STREAM := preload("res://scenes/minigameIndications/error.ogg")
const ALPHA_THRESHOLD := 0.02

@export var total_rounds: int = 5
@export var hit_tolerance: float = 0.07

@onready var title_label: Button = $MainPanel/Margin/VBox/TitleSlot/Title
@onready var guide_title_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/GuideTitle/GuideTitleLabel
@onready var guide1_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide1/Guide1Label
@onready var guide2_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide2/Guide2Label
@onready var guide3_label: Label = $MainPanel/Margin/VBox/Content/LeftPanel/Guide3/Guide3Label
@onready var objectives_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesTitle/ObjectivesTitleLabel
@onready var rounds_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Rounds
@onready var instruction_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ObjectivesBody/ObjectivesVBox/Instruction
@onready var results_title_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsTitle/ResultsTitleLabel
@onready var request_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/ClientRequest
@onready var timer_label: Label = $MainPanel/Margin/VBox/Content/CenterPanel/Timer
@onready var glass_fill: ColorRect = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass/GlassBody/FillRect
@onready var target_line: ColorRect = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass/GlassBody/TargetLine
@onready var handle_button: Button = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass/HandleButton
@onready var glass_root: Control = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass
@onready var glass_body: Control = $MainPanel/Margin/VBox/Content/CenterPanel/BeerContainer/PlayArea/Glass/GlassBody
@onready var round_result_label: Label = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/Result
@onready var finish_button: Button = $MainPanel/Margin/VBox/Content/RightPanel/ResultsBody/ResultsVBox/FinishButton

var current_round: int = 0
var score: int = 0
var pending_next_round: float = -1.0

var target_fill: float = 0.5
var fill_level: float = 0.0
var fill_speed: float = 0.2

var is_round_locked: bool = false
var is_auto_filling: bool = false
var sfx_success_player: AudioStreamPlayer
var sfx_error_player: AudioStreamPlayer
var jar_opaque_uv_rect: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)


func _ready() -> void:
	randomize()
	_compute_jar_opaque_uv_rect()
	_setup_feedback_sfx()
	_setup_liquid_controls()
	_setup_beer_jar_overlay()
	_position_stop_button()
	handle_button.pressed.connect(_on_handle_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	_update_static_texts()
	call_deferred("_start_round")


func _process(delta: float) -> void:
	if current_round <= 0:
		return

	if not is_round_locked:
		if is_auto_filling:
			fill_level = clampf(fill_level + fill_speed * delta, 0.0, 1.0)
			_update_glass_visual()
			if fill_level >= 1.0:
				_resolve_round(false, "overfill")
				return

	if pending_next_round >= 0.0:
		pending_next_round -= delta
		if pending_next_round <= 0.0:
			pending_next_round = -1.0
			_start_round()


func _update_static_texts() -> void:
	title_label.text = _t("title")
	guide_title_label.text = _t("quick_guide")
	guide1_label.text = _t("guide_1")
	guide2_label.text = _t("guide_2")
	guide3_label.text = _t("guide_3")
	objectives_title_label.text = _t("objectives")
	results_title_label.text = _t("results")
	instruction_label.text = _t("instruction")
	handle_button.text = _get_stop_button_text()
	finish_button.text = _t("finish")
	rounds_label.text = _t("rounds") % [0, total_rounds]
	timer_label.visible = false
	request_label.text = ""
	round_result_label.text = ""
	round_result_label.visible = false
	finish_button.visible = false


func _start_round() -> void:
	if current_round >= total_rounds:
		_finish_minigame()
		return

	current_round += 1
	is_round_locked = false
	is_auto_filling = true
	round_result_label.visible = false
	handle_button.disabled = false

	fill_level = 0.0
	target_fill = randf_range(0.35, 0.9)

	var expected_seconds: float = randf_range(3.0, 10.0)
	fill_speed = 1.0 / expected_seconds

	request_label.text = _t("client_request") % [int(round(target_fill * 100.0))]
	rounds_label.text = _t("rounds") % [current_round, total_rounds]
	_update_glass_visual()


func _update_glass_visual() -> void:
	var liquid_rect: Rect2 = _get_liquid_draw_rect()
	glass_fill.offset_left = liquid_rect.position.x
	glass_fill.offset_right = liquid_rect.position.x + liquid_rect.size.x - glass_body.size.x
	glass_fill.offset_bottom = liquid_rect.position.y + liquid_rect.size.y - glass_body.size.y

	var fill_h: float = liquid_rect.size.y * fill_level
	glass_fill.offset_top = liquid_rect.position.y + (liquid_rect.size.y - fill_h)

	var target_y: float = liquid_rect.position.y + liquid_rect.size.y * (1.0 - target_fill)
	target_line.offset_top = target_y - 1.0
	target_line.offset_bottom = target_y + 1.0
	target_line.offset_left = liquid_rect.position.x
	target_line.offset_right = liquid_rect.position.x + liquid_rect.size.x


func _on_handle_button_pressed() -> void:
	if is_round_locked:
		return
	if not is_auto_filling:
		return

	is_auto_filling = false
	var diff: float = absf(fill_level - target_fill)
	var success: bool = diff <= hit_tolerance
	_resolve_round(success, "released")


func _resolve_round(success: bool, reason: String) -> void:
	if is_round_locked:
		return

	is_round_locked = true
	is_auto_filling = false
	handle_button.disabled = true

	if success:
		score += 1
		if sfx_success_player != null:
			sfx_success_player.pitch_scale = randf_range(0.9, 1.1)
			sfx_success_player.play()
		round_result_label.text = _t("correct")
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		if sfx_error_player != null:
			sfx_error_player.play()
		if reason == "timeout":
			round_result_label.text = _t("timeout")
		elif reason == "overfill":
			round_result_label.text = _t("overfill")
		else:
			round_result_label.text = _t("incorrect")
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	pending_next_round = 0.9


func _finish_minigame() -> void:
	is_round_locked = true
	is_auto_filling = false
	handle_button.disabled = true

	var success: bool = score >= int(ceil(float(total_rounds) * 0.6))
	if success:
		round_result_label.text = _t("final_success") % [score, total_rounds]
		round_result_label.modulate = Color(0.55, 1.0, 0.55, 1.0)
	else:
		round_result_label.text = _t("final_fail") % [score, total_rounds]
		round_result_label.modulate = Color(1.0, 0.55, 0.55, 1.0)

	round_result_label.visible = true
	finish_button.visible = true
	emit_signal("minigame_finished", success, score, total_rounds)


func _on_finish_button_pressed() -> void:
	queue_free()


func _setup_feedback_sfx() -> void:
	sfx_success_player = AudioStreamPlayer.new()
	sfx_success_player.stream = SFX_SUCCESS_STREAM
	sfx_success_player.bus = &"SFX"
	add_child(sfx_success_player)

	sfx_error_player = AudioStreamPlayer.new()
	sfx_error_player.stream = SFX_ERROR_STREAM
	sfx_error_player.bus = &"SFX"
	add_child(sfx_error_player)


func _setup_beer_jar_overlay() -> void:
	if glass_body == null:
		return

	var jar_overlay := TextureRect.new()
	jar_overlay.name = "BeerJarFront"
	jar_overlay.texture = BEER_JAR_TEXTURE
	jar_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	jar_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jar_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	jar_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jar_overlay.z_index = 3
	glass_body.add_child(jar_overlay)
	glass_body.move_child(jar_overlay, glass_body.get_child_count() - 1)


func _setup_liquid_controls() -> void:
	glass_body.clip_contents = true
	glass_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target_line.anchor_left = 0.0
	target_line.anchor_top = 0.0
	target_line.anchor_right = 0.0
	target_line.anchor_bottom = 0.0
	glass_fill.z_index = 1
	target_line.z_index = 4
	target_line.visible = true


func _position_stop_button() -> void:
	handle_button.offset_left += 72.0
	handle_button.offset_right += 72.0


func _get_liquid_draw_rect() -> Rect2:
	var body_size: Vector2 = glass_body.size
	var tex_size: Vector2 = BEER_JAR_TEXTURE.get_size()
	if body_size.x <= 0.0 or body_size.y <= 0.0 or tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(0.0, 0.0, body_size.x, body_size.y)

	var body_aspect: float = body_size.x / body_size.y
	var tex_aspect: float = tex_size.x / tex_size.y

	var draw_w: float
	var draw_h: float
	if tex_aspect > body_aspect:
		draw_w = body_size.x
		draw_h = draw_w / tex_aspect
	else:
		draw_h = body_size.y
		draw_w = draw_h * tex_aspect

	var draw_x: float = (body_size.x - draw_w) * 0.5
	var draw_y: float = (body_size.y - draw_h) * 0.5

	var opaque_x: float = draw_x + draw_w * jar_opaque_uv_rect.position.x
	var opaque_y: float = draw_y + draw_h * jar_opaque_uv_rect.position.y
	var opaque_w: float = draw_w * jar_opaque_uv_rect.size.x
	var opaque_h: float = draw_h * jar_opaque_uv_rect.size.y
	return Rect2(opaque_x, opaque_y, opaque_w, opaque_h)


func _compute_jar_opaque_uv_rect() -> void:
	jar_opaque_uv_rect = Rect2(0.0, 0.0, 1.0, 1.0)
	var image: Image = BEER_JAR_TEXTURE.get_image()
	if image == null or image.is_empty():
		return

	var w: int = image.get_width()
	var h: int = image.get_height()
	if w <= 0 or h <= 0:
		return

	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1

	for y in range(h):
		for x in range(w):
			if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
				if x < min_x:
					min_x = x
				if y < min_y:
					min_y = y
				if x > max_x:
					max_x = x
				if y > max_y:
					max_y = y

	if max_x < min_x or max_y < min_y:
		return

	var uv_x: float = float(min_x) / float(w)
	var uv_y: float = float(min_y) / float(h)
	var uv_w: float = float(max_x - min_x + 1) / float(w)
	var uv_h: float = float(max_y - min_y + 1) / float(h)
	jar_opaque_uv_rect = Rect2(uv_x, uv_y, uv_w, uv_h)


func _get_stop_button_text() -> String:
	match LocaleManager.current_language:
		"en":
			return "STOP"
		"pt":
			return "PARAR"
		_:
			return "DETENER"


func _t(key: String) -> String:
	return LocaleManager.get_text(I18N_CATEGORY, key)
