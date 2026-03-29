extends Node

signal minigame_finished(success: bool)

const SFX_SUCCESS_STREAM := preload("res://scenes/minigameIndications/success.ogg")
const SFX_ERROR_STREAM := preload("res://scenes/minigameIndications/error.ogg")
const STRESS_SHADER := preload("res://assets/shaders/stress_warehouse.gdshader")

@export var current_day: int = 1
@export var base_time: float = 60.0
@export var min_time: float = 20.0
@export var time_decrease_per_day: float = 5.0
@export var spike_time_penalty: float = 8.0
@export var max_hits: int = 3
@export var light_toggle_interval: float = 4.0
@export var light_off_duration: float = 2.0

@onready var boxes_root: Node = get_parent().get_node("Boxes")
@onready var spikes_root: Node = get_parent().get_node("Spikes")
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var time_label: Label = get_parent().get_node("GameUI/UIRoot/HUDPanel/Margin/VBox/StatsRow/TimeCard/TimeLabel")
@onready var boxes_label: Label = get_parent().get_node("GameUI/UIRoot/HUDPanel/Margin/VBox/StatsRow/BoxesCard/BoxesLabel")
@onready var hits_label: Label = get_parent().get_node("GameUI/UIRoot/HUDPanel/Margin/VBox/StatsRow/HitsCard/HitsLabel")
@onready var light_card: PanelContainer = get_parent().get_node("GameUI/UIRoot/HUDPanel/Margin/VBox/StatsRow/LightCard")
@onready var light_label: Label = get_parent().get_node("GameUI/UIRoot/HUDPanel/Margin/VBox/StatsRow/LightCard/LightLabel")
@onready var objective_label: Label = get_parent().get_node("GameUI/UIRoot/HUDPanel/Margin/VBox/ObjectiveCard/ObjectiveLabel")
@onready var result_panel: PanelContainer = get_parent().get_node("GameUI/UIRoot/ResultPanel")
@onready var result_label: Label = get_parent().get_node("GameUI/UIRoot/ResultPanel/ResultMargin/ResultVBox/ResultLabel")
@onready var summary_label: Label = get_parent().get_node("GameUI/UIRoot/ResultPanel/ResultMargin/ResultVBox/SummaryLabel")
@onready var retry_button: Button = get_parent().get_node("GameUI/UIRoot/ResultPanel/ResultMargin/ResultVBox/ButtonsRow/RetryButton")
@onready var continue_button: Button = get_parent().get_node("GameUI/UIRoot/ResultPanel/ResultMargin/ResultVBox/ButtonsRow/ContinueButton")

var time_remaining: float = 60.0
var boxes_collected: int = 0
var target_boxes: int = 0
var hits_taken: int = 0
var is_game_running: bool = false
var desempeno: float = 0.0
var eficiencia: float = 0.0
var recompensa_total: int = 0
var estres: float = 0.0
var stress_difficulty: float = 0.0
var mission_money_min: int = 0
var mission_money_max: int = 0

var light_on: bool = true
var time_since_last_toggle: float = 0.0
var light_off_timer: float = 0.0
var sfx_success_player: AudioStreamPlayer
var sfx_error_player: AudioStreamPlayer
var stress_fx_overlay: ColorRect
var stress_fx_material: ShaderMaterial
var stress_fx_time: float = 0.0

func _ready() -> void:
	randomize()
	_setup_stress_shader()
	_setup_feedback_sfx()
	_randomize_playfield_positions()
	target_boxes = boxes_root.get_child_count()
	var day_offset := float(current_day - 1) * time_decrease_per_day
	time_remaining = max(min_time, base_time - day_offset)
	is_game_running = true
	if light_card != null:
		light_card.visible = false
	result_panel.visible = false
	if retry_button != null and is_instance_valid(retry_button):
		retry_button.visible = false
		retry_button.disabled = true
		retry_button.queue_free()
	continue_button.pressed.connect(_on_continue_button_pressed)
	_update_hud()


func _setup_feedback_sfx() -> void:
	sfx_success_player = AudioStreamPlayer.new()
	sfx_success_player.stream = SFX_SUCCESS_STREAM
	sfx_success_player.bus = &"SFX"
	sfx_success_player.volume_db = -8.0
	add_child(sfx_success_player)

	sfx_error_player = AudioStreamPlayer.new()
	sfx_error_player.stream = SFX_ERROR_STREAM
	sfx_error_player.bus = &"SFX"
	sfx_error_player.volume_db = -8.0
	add_child(sfx_error_player)


func _process(delta: float) -> void:
	_update_stress_shader(delta)
	if not is_game_running:
		return

	time_remaining = max(0.0, time_remaining - delta)
	if time_remaining <= 0.0:
		_finish_game(false, "SE ACABO EL TIEMPO")
		return

	# Ciclo de luz: alterna entre luz total y oscuridad para tensionar la ruta.
	if light_on:
		time_since_last_toggle += delta
		if time_since_last_toggle >= light_toggle_interval:
			light_on = false
			light_off_timer = 0.0
			time_since_last_toggle = 0.0
	else:
		light_off_timer += delta
		if light_off_timer >= light_off_duration:
			light_on = true
			time_since_last_toggle = 0.0

	_update_hud()


func collect_box() -> void:
	if not is_game_running:
		return
	boxes_collected += 1
	if sfx_success_player != null:
		sfx_success_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_success_player.play()
	if boxes_collected >= target_boxes:
		_finish_game(true, "ALMACEN ORDENADO")
		return
	_update_hud()


func hit_spike(penalty: float = spike_time_penalty) -> void:
	if not is_game_running:
		return
	if sfx_error_player != null:
		sfx_error_player.play()

	hits_taken += 1
	time_remaining = max(0.0, time_remaining - penalty)

	if hits_taken >= max_hits:
		_finish_game(false, "DEMASIADOS GOLPES")
		return

	if time_remaining <= 0.0:
		_finish_game(false, "SE ACABO EL TIEMPO")
		return

	_update_hud()


func lose_time(seconds: float) -> void:
	hit_spike(seconds)


func get_time_remaining() -> float:
	return time_remaining


func get_time_left() -> float:
	return time_remaining


func get_boxes_collected() -> int:
	return boxes_collected


func is_light_on() -> bool:
	return light_on


func _update_hud() -> void:
	time_label.text = "TIEMPO: %s" % _format_time_mm_ss(time_remaining)
	boxes_label.text = "CAJAS: %d/%d" % [boxes_collected, target_boxes]
	hits_label.text = "GOLPES: %d/%d" % [hits_taken, max_hits]
	objective_label.text = "OBJETIVO: RECOGE %d CAJAS, EVITA LOS SPIKES Y SOBREVIVE A LOS APAGONES." % target_boxes


func _format_time_mm_ss(seconds: float) -> String:
	var total_seconds: int = int(ceil(maxf(0.0, seconds)))
	var minutes: int = total_seconds / 60
	var secs: int = total_seconds % 60
	return "%02d:%02d" % [minutes, secs]


func _finish_game(success: bool, title: String) -> void:
	is_game_running = false
	eficiencia = clamp((float(boxes_collected) / max(1.0, float(target_boxes))) * 100.0, 0.0, 100.0)
	desempeno = clamp((float(hits_taken) / max(1.0, float(max_hits))) * 100.0, 0.0, 100.0)
	estres = lerpf(2.0, 22.0, desempeno / 100.0)
	recompensa_total = _calc_recompensa_from_eficiencia()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	result_panel.visible = true
	if success:
		if sfx_success_player != null:
			sfx_success_player.pitch_scale = 1.0
			sfx_success_player.play()
	else:
		if sfx_error_player != null:
			sfx_error_player.play()
	result_label.text = title
	summary_label.text = "CAJAS: %d/%d   |   GOLPES: %d/%d   |   TIEMPO: %s" % [
		boxes_collected,
		target_boxes,
		hits_taken,
		max_hits,
		_format_time_mm_ss(time_remaining)
	]
	emit_signal("minigame_finished", success)


func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_continue_button_pressed() -> void:
	# Si el minijuego esta embebido en una escena mayor, esto permite cerrarlo limpio.
	var root := get_parent()
	if root != null:
		root.queue_free()


func _calc_recompensa_from_eficiencia() -> int:
	var min_money: int = mission_money_min
	var max_money: int = max(mission_money_min, mission_money_max)
	return int(round(lerpf(float(min_money), float(max_money), clamp(eficiencia / 100.0, 0.0, 1.0))))


func _randomize_playfield_positions() -> void:
	var box_nodes: Array[Node2D] = []
	for child in boxes_root.get_children():
		if child is Node2D:
			box_nodes.append(child)

	var spike_nodes: Array[Node2D] = []
	for child in spikes_root.get_children():
		if child is Node2D and child.name.begins_with("Spike"):
			spike_nodes.append(child)

	var all_positions: Array[Vector2] = []
	for node in box_nodes:
		all_positions.append(node.position)
	for node in spike_nodes:
		all_positions.append(node.position)

	if all_positions.size() < box_nodes.size() + spike_nodes.size():
		return

	all_positions.shuffle()
	var idx := 0
	for node in box_nodes:
		node.position = all_positions[idx]
		idx += 1
	for node in spike_nodes:
		node.position = all_positions[idx]
		idx += 1


func _setup_stress_shader() -> void:
	var world_host: CanvasItem = get_parent() as CanvasItem
	if world_host == null:
		return
	var root_node: Node = world_host as Node
	stress_fx_overlay = ColorRect.new()
	stress_fx_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stress_fx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stress_fx_overlay.color = Color(1, 1, 1, 0)
	stress_fx_overlay.z_index = 100
	stress_fx_material = ShaderMaterial.new()
	stress_fx_material.shader = STRESS_SHADER
	stress_fx_overlay.material = stress_fx_material
	world_host.add_child(stress_fx_overlay)
	if root_node != null:
		var ui_node := root_node.get_node_or_null("GameUI")
		if ui_node != null:
			root_node.move_child(stress_fx_overlay, max(0, ui_node.get_index() - 1))
	stress_fx_material.set_shader_parameter("intensity", _stress_to_power())


func _update_stress_shader(delta: float) -> void:
	if stress_fx_material == null:
		return
	stress_fx_time += delta
	stress_fx_material.set_shader_parameter("time_sec", stress_fx_time)
	stress_fx_material.set_shader_parameter("intensity", _stress_to_power())


func _stress_to_power() -> float:
	var normalized := clampf(stress_difficulty / 100.0, 0.0, 1.0)
	return clampf(pow(normalized, 0.82) * 2.0, 0.0, 2.0)
