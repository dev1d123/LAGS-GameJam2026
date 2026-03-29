extends Node2D

@onready var spawner:         Node2D = $Spawner
@onready var hud: Node                = $Spawner/Node/HUDLayer/Hud
@onready var npc_description: Node2D = $NpcDescriptionLayer/NpcDescription
@onready var title_label: Label       = $NpcDescriptionLayer/NpcDescription/TitleLabel
@onready var objectives_label: Label  = $NpcDescriptionLayer/NpcDescription/ObjetivesLabel
@onready var description_label: Label = $NpcDescriptionLayer/NpcDescription/DescriptionLabel
@onready var rewards_label: Label     = $NpcDescriptionLayer/NpcDescription/RewardsLabel
@onready var money_label: Label       = $NpcDescriptionLayer/NpcDescription/MoneyLabel
@onready var cancel_button: Button    = $NpcDescriptionLayer/NpcDescription/CancelButton
@onready var accept_button: Button    = $NpcDescriptionLayer/NpcDescription/AcceptButton
@onready var screen_fx: ColorRect = $Spawner/Node/ShaderLayer/ColorRect

#Son Labels Hijo de npc
#$TitleLabel, $ObjetivesLabel, $DescriptionLabel, $RewardsLabel, $MoneyLabel
var frozen:       bool = false
var aura_npc_ref: Node = null
var selected_npc_ref: Node = null
var mission_data_by_id: Dictionary = {}
var current_day: int = 1
var current_hour: int = 6
var day_time_accum: float = 0.0
var is_day_transition_playing: bool = false

const DAY_START_HOUR := 6
const DAY_END_HOUR := 18
const SECONDS_PER_INGAME_HOUR := 7
const DAY_TRANSITION_FONT := preload("res://assets/fonts/LazyFox Pixel Font 2.ttf")

var day_transition_layer: CanvasLayer
var day_transition_root: Control
var day_transition_rect: ColorRect
var day_transition_label: Label


func _ready() -> void:
	_load_mission_data()
	print("[Scenario] mission_data loaded: ", mission_data_by_id.size())
	npc_description.visible = false
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	if accept_button == null:
		accept_button = $NpcDescriptionLayer/NpcDescription.get_node_or_null("CheckButtonA") as Button
	if accept_button == null:
		push_error("No se encontro el boton de aceptar en NpcDescriptionLayer/NpcDescription")
	else:
		accept_button.pressed.connect(_on_accept_button_pressed)
	spawner.register_scenario(self)
	_setup_day_transition_ui()
	_initialize_day_cycle()
	call_deferred("_start_day_transition", current_day)
	
	if hud != null:
		smoothed_energy = hud.energy_bar.value
		smoothed_stress = hud.stress_bar.value
	_update_shader_effects()


func _exit_tree() -> void:
	if day_transition_layer != null and is_instance_valid(day_transition_layer):
		day_transition_layer.queue_free()


func _process(delta: float) -> void:
	if is_day_transition_playing or frozen:
		return

	day_time_accum += delta
	while day_time_accum >= SECONDS_PER_INGAME_HOUR:
		day_time_accum -= SECONDS_PER_INGAME_HOUR
		_advance_ingame_hour()
	
	_update_shader_effects()

var smoothed_energy: float = 100.0
var smoothed_stress: float = 0.0

func _update_shader_effects() -> void:

	
	var delta: float = get_process_delta_time()
	
	var target_energy: float = hud.energy_bar.value
	var target_stress: float = hud.stress_bar.value

	smoothed_energy = lerp(smoothed_energy, target_energy, 1.5 * delta)
	smoothed_stress = lerp(smoothed_stress, target_stress, 1.5 * delta)

	var fatigue_factor: float = 1.0 - clamp(smoothed_energy / 70.0, 0.0, 1.0)
	var stress_factor: float = clamp(smoothed_stress / 100.0, 0.0, 1.0)

	var saturation: float = 1.0 - (pow(fatigue_factor, 1.5) * 0.9)
	screen_fx.material.set_shader_parameter("saturation_amount", saturation)

	var blur: float = 0.0
	if fatigue_factor > 0.7:
		blur = pow((fatigue_factor - 0.7) / 0.3, 2.0) * 3.0
	screen_fx.material.set_shader_parameter("blur_intensity", blur)

	var stress_curve: float = pow(stress_factor, 3.0)
	screen_fx.material.set_shader_parameter("stress_tunnel", stress_curve)
	
	var player = get_tree().get_first_node_in_group("Player")
	
	if is_instance_valid(player):
		var player_canvas_pos = player.get_global_transform_with_canvas().origin
		var viewport_size = get_viewport_rect().size
		
		if viewport_size.x > 0 and viewport_size.y > 0:
			var player_uv = player_canvas_pos / viewport_size
			screen_fx.material.set_shader_parameter("player_screen_uv", player_uv)
			
		var combined_malaise: float = clamp(pow(fatigue_factor, 2.0) + pow(stress_factor, 2.0), 0.0, 1.0)
		
		var player_sprite = player.get_node_or_null("AnimatedSprite2D")
		
		if player_sprite != null and player_sprite.material != null:
			player_sprite.material.set_shader_parameter("malaise_amount", combined_malaise)
	


func _input(event: InputEvent) -> void:
	if is_day_transition_playing:
		return

	if event.is_action_pressed("ui_interact"):
		if aura_npc_ref != null and aura_npc_ref.aura_active:
			_toggle_freeze()
		elif frozen:
			_toggle_freeze()


func _toggle_freeze() -> void:
	frozen = not frozen
	print("[Scenario] toggle freeze -> ", frozen)
	if frozen:
		selected_npc_ref = aura_npc_ref
		_populate_npc_description(selected_npc_ref)
	else:
		selected_npc_ref = null

	var mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	spawner.process_mode = mode
	for child in spawner.get_children():
		child.process_mode = mode
	npc_description.visible = frozen


func set_aura_npc(npc: Node) -> void:
	aura_npc_ref = npc
	var mission_id := ""
	if aura_npc_ref.has_method("get_current_mission_id"):
		mission_id = aura_npc_ref.get_current_mission_id()
	print("[Scenario] aura npc set. mission_id=", mission_id)


func clear_aura_npc(npc: Node) -> void:
	if frozen:
		return
	if aura_npc_ref == npc:
		aura_npc_ref = null


func _load_mission_data() -> void:
	var file = FileAccess.open("res://data/localization/mission_data.json", FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir mission_data.json")
		return

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()

	if result != OK:
		push_error("Error al parsear mission_data.json")
		return

	var jobs: Array = json.get_data().get("jobs", [])
	for job in jobs:
		if job is Dictionary and job.has("id"):
			mission_data_by_id[job["id"]] = job


func _get_localized_text(value: Variant, lang: String, fallback: String = "") -> String:
	if value is Dictionary:
		return value.get(lang, value.get("es", fallback))
	return fallback


func _populate_npc_description(npc_ref: Node = null) -> void:
	var target_npc: Node = npc_ref if npc_ref != null else aura_npc_ref

	if target_npc == null:
		title_label.text = ""
		objectives_label.text = ""
		description_label.text = ""
		rewards_label.text = ""
		money_label.text = ""
		print("[Scenario] populate aborted: aura_npc_ref is null")
		return

	var mission_id := ""
	if target_npc.has_method("get_current_mission_id"):
		mission_id = target_npc.get_current_mission_id()

	if not mission_data_by_id.has(mission_id):
		title_label.text = ""
		objectives_label.text = ""
		description_label.text = ""
		rewards_label.text = ""
		money_label.text = ""
		push_error("Mision no encontrada para mission_id='%s'" % mission_id)
		return

	var lang = LocaleManager.current_language
	var mission: Dictionary = mission_data_by_id[mission_id]

	title_label.text = _get_localized_text(mission.get("title", {}), lang)
	objectives_label.text = _get_localized_text(mission.get("objectives_label", {}), lang)
	description_label.text = _get_localized_text(mission.get("description", {}), lang)
	rewards_label.text = _get_localized_text(mission.get("rewards_label", {}), lang)

	var money: Dictionary = mission.get("money", {})
	var min_money = money.get("min", 0)
	var max_money = money.get("max", 0)
	money_label.text = "%s - %s" % [str(min_money), str(max_money)]
	print("[Scenario] populated mission UI. id=", mission_id, " title=", title_label.text)


func _on_cancel_button_pressed() -> void:
	_resolve_selected_mission(false)


func _on_accept_button_pressed() -> void:
	_resolve_selected_mission(true)


func _resolve_selected_mission(accepted: bool) -> void:
	if accepted and selected_npc_ref != null and selected_npc_ref.has_method("get_current_mission_id"):
		var mission_id: String = selected_npc_ref.get_current_mission_id()
		if mission_data_by_id.has(mission_id):
			var mission: Dictionary = mission_data_by_id[mission_id]
			var money: Dictionary = mission.get("money", {})
			var min_money: int = int(money.get("min", 0))
			var max_money: int = int(money.get("max", min_money))
			if max_money < min_money:
				max_money = min_money
			var reward_amount: int = randi_range(min_money, max_money)
			#PONER LOGICA DE MINIGAMES AQUI
			if spawner != null and spawner.has_method("add_money"):
				spawner.add_money(reward_amount)
			if hud != null and hud.has_method("consumir_energia_mision"):
				hud.consumir_energia_mision(20.0)

	if selected_npc_ref != null and selected_npc_ref.has_method("resolve_mission"):
		selected_npc_ref.resolve_mission(accepted)

	if frozen:
		_toggle_freeze()


func _initialize_day_cycle() -> void:
	day_time_accum = 0.0
	current_hour = DAY_START_HOUR
	if hud != null and hud.has_method("set_dia"):
		hud.set_dia(current_day)
	if hud != null and hud.has_method("set_hora"):
		hud.set_hora(current_hour)


func _advance_ingame_hour() -> void:
	current_hour += 1
	if hud != null and hud.has_method("set_hora"):
		hud.set_hora(current_hour)

	if current_hour >= DAY_END_HOUR:
		current_day += 1
		current_hour = DAY_START_HOUR
		if hud != null and hud.has_method("set_dia"):
			hud.set_dia(current_day)
		if hud != null and hud.has_method("set_hora"):
			hud.set_hora(current_hour)
		_start_day_transition(current_day)


func _setup_day_transition_ui() -> void:
	day_transition_layer = CanvasLayer.new()
	day_transition_layer.layer = 4096
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else self
	host.add_child(day_transition_layer)

	day_transition_root = Control.new()
	day_transition_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_transition_layer.add_child(day_transition_root)

	day_transition_rect = ColorRect.new()
	day_transition_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_transition_rect.color = Color(0, 0, 0, 1)
	day_transition_rect.visible = true
	day_transition_root.add_child(day_transition_rect)

	day_transition_label = Label.new()
	day_transition_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_transition_label.add_theme_font_override("font", DAY_TRANSITION_FONT)
	day_transition_label.add_theme_font_size_override("font_size", 64)
	day_transition_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	day_transition_label.visible = true
	day_transition_root.add_child(day_transition_label)
	day_transition_layer.visible = false

	_refresh_day_transition_layout()
	get_viewport().size_changed.connect(_refresh_day_transition_layout)


func _start_day_transition(day_number: int) -> void:
	is_day_transition_playing = true
	day_transition_layer.visible = true
	_refresh_day_transition_layout()
	day_transition_label.text = _get_day_transition_text(day_number)
	_set_world_paused(true)

	day_transition_rect.color = Color(0, 0, 0, 1)
	day_transition_label.modulate = Color(1, 1, 1, 1)

	await get_tree().process_frame

	await get_tree().create_timer(1.2).timeout
	day_transition_label.modulate = Color(1, 1, 1, 0)
	await get_tree().create_timer(0.15).timeout
	day_transition_rect.color = Color(0, 0, 0, 0)
	await get_tree().create_timer(0.05).timeout
	_on_day_transition_finished()


func _on_day_transition_finished() -> void:
	if not is_day_transition_playing:
		return
	day_transition_layer.visible = false
	is_day_transition_playing = false
	if hud != null and hud.has_method("iniciar_dia_stats"):
		hud.iniciar_dia_stats()
	_set_world_paused(false)


func _refresh_day_transition_layout() -> void:
	if day_transition_root == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	day_transition_root.size = viewport_size
	day_transition_rect.size = viewport_size
	day_transition_label.size = viewport_size


func _set_world_paused(value: bool) -> void:
	var mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	spawner.process_mode = mode
	for child in spawner.get_children():
		child.process_mode = mode


func _get_day_transition_text(day_number: int) -> String:
	match LocaleManager.current_language:
		"en":
			return "Day %d" % day_number
		"pt":
			return "Dia %d" % day_number
		_:
			return "Dia %d" % day_number
