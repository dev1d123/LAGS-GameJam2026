extends Node

signal minigame_finished(success: bool)

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

var light_on: bool = true
var time_since_last_toggle: float = 0.0
var light_off_timer: float = 0.0

func _ready() -> void:
	randomize()
	_randomize_playfield_positions()
	target_boxes = boxes_root.get_child_count()
	var day_offset := float(current_day - 1) * time_decrease_per_day
	time_remaining = max(min_time, base_time - day_offset)
	is_game_running = true
	result_panel.visible = false
	retry_button.pressed.connect(_on_retry_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	_update_hud()


func _process(delta: float) -> void:
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
	if boxes_collected >= target_boxes:
		_finish_game(true, "ALMACEN ORDENADO")
		return
	_update_hud()


func hit_spike(penalty: float = spike_time_penalty) -> void:
	if not is_game_running:
		return

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
	time_label.text = "TIEMPO: %d" % int(ceil(time_remaining))
	boxes_label.text = "CAJAS: %d/%d" % [boxes_collected, target_boxes]
	hits_label.text = "GOLPES: %d/%d" % [hits_taken, max_hits]
	light_label.text = "LUZ: %s" % ("ENCENDIDA" if light_on else "APAGADA")
	objective_label.text = "OBJETIVO: RECOGE %d CAJAS, EVITA LOS SPIKES Y SOBREVIVE A LOS APAGONES." % target_boxes


func _finish_game(success: bool, title: String) -> void:
	is_game_running = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	result_panel.visible = true
	result_label.text = title
	summary_label.text = "CAJAS: %d/%d   |   GOLPES: %d/%d   |   TIEMPO: %d" % [
		boxes_collected,
		target_boxes,
		hits_taken,
		max_hits,
		int(ceil(time_remaining))
	]
	emit_signal("minigame_finished", success)


func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_continue_button_pressed() -> void:
	# Si el minijuego esta embebido en una escena mayor, esto permite cerrarlo limpio.
	var root := get_parent()
	if root != null:
		root.queue_free()


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
