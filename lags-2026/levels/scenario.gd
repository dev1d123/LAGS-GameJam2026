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
const FINAL_DAY := 4
const SECONDS_PER_INGAME_HOUR := 5
const START_DAY := 28
const START_MONTH := 12
const START_YEAR := 2008
const DAY_TRANSITION_FONT := preload("res://assets/fonts/LazyFox Pixel Font 2.ttf")
const ENDING_SCENE_PATH := "res://scenes/Endings/EscenaFinales.tscn"

const SHOP_MUSIC_ACTIVE_DB := -8.0
const SHOP_MUSIC_MUTED_DB := -40.0
const SHOP_MUSIC_CROSSFADE_SECONDS := 1.0
const SHOP_MUSIC_CHECK_INTERVAL := 0.3

const SHOP_MUSIC_NORMAL = preload("res://assets/audio/game/NormalShop.ogg")
const SHOP_MUSIC_NORMAL_STRESS = preload("res://assets/audio/game/NormalStressShop.ogg")
const SHOP_MUSIC_NORMAL_HIGH_STRESS = preload("res://assets/audio/game/NormalHighStressShop.ogg")
const SHOP_MUSIC_LOW = preload("res://assets/audio/game/LowEnergyShop.ogg")
const SHOP_MUSIC_LOW_STRESS = preload("res://assets/audio/game/LowEnergyStressShop.ogg")
const SHOP_MUSIC_LOW_HIGH_STRESS = preload("res://assets/audio/game/LowEnergyHighStressShop.ogg")
const SHOP_MUSIC_VERY_LOW = preload("res://assets/audio/game/VeryLowEnergyShop.ogg")
const SHOP_MUSIC_VERY_LOW_STRESS = preload("res://assets/audio/game/VeryLowEnergyStressShop.ogg")
const SHOP_MUSIC_VERY_LOW_HIGH_STRESS = preload("res://assets/audio/game/VeryLowEnergyHighStressShop.ogg")

const MAKING_TASK_NORMAL = preload("res://assets/audio/game/MakingTask.ogg")
const MAKING_TASK_STRESS = preload("res://assets/audio/game/MakingTaskStress.ogg")
const MAKING_TASK_HIGH_STRESS = preload("res://assets/audio/game/MakingTaskHighStress.ogg")
const OPTIONS_MENU_SCENE := preload("res://ui/components/options_menu.tscn")
const MINIGAME_SUMMARY_FONT := preload("res://assets/fonts/PixelOperatorMonoHB.ttf")

const MINIGAME_SCENES_BY_MISSION := {
	"bar_beer": "res://minijuego_bar_beer.tscn",
	"cafe_candy": "res://minijuego_cafe_candy.tscn",
	"cafe_cyber": "res://minijuego_cafe_cyber.tscn",
	"pay_services": "res://minijuego_payservices.tscn",
	"store_search": "res://minijuego_store_search.tscn",
	"store_warehouse": "res://minijuegos/escenas/almacen_nivel_01.tscn",
	"shop_service": "res://minijuego_granel.tscn",
	"indications": "res://scenes/minigameIndications/MiniJuego.tscn",
}

const SHOP_MUSIC_STREAMS := {
	"normal_normal": SHOP_MUSIC_NORMAL,
	"normal_stress": SHOP_MUSIC_NORMAL_STRESS,
	"normal_high_stress": SHOP_MUSIC_NORMAL_HIGH_STRESS,
	"low_normal": SHOP_MUSIC_LOW,
	"low_stress": SHOP_MUSIC_LOW_STRESS,
	"low_high_stress": SHOP_MUSIC_LOW_HIGH_STRESS,
	"very_low_normal": SHOP_MUSIC_VERY_LOW,
	"very_low_stress": SHOP_MUSIC_VERY_LOW_STRESS,
	"very_low_high_stress": SHOP_MUSIC_VERY_LOW_HIGH_STRESS,
}

var day_transition_layer: CanvasLayer
var day_transition_root: Control
var day_transition_rect: ColorRect
var day_transition_label: Label
var shop_music_a: AudioStreamPlayer
var shop_music_b: AudioStreamPlayer
var shop_music_using_a: bool = true
var current_shop_music_key: String = ""
var shop_music_check_accum: float = 0.0
var making_task_player: AudioStreamPlayer
var minigame_layer: CanvasLayer
var minigame_host: Control
var active_minigame: Node
var active_minigame_mission_id: String = ""
var pending_mission_npc_ref: Node = null
var is_minigame_playing: bool = false
var pause_layer: CanvasLayer
var pause_overlay: ColorRect
var pause_menu_container: CenterContainer
var pause_options_menu: PanelContainer
var is_pause_menu_open: bool = false
var is_resolving_minigame_finish: bool = false


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
	_setup_shop_music()
	_setup_making_task_player()
	_setup_day_transition_ui()
	_setup_pause_menu_ui()
	_initialize_day_cycle()
	call_deferred("_start_day_transition", current_day)
	


func _exit_tree() -> void:
	if day_transition_layer != null and is_instance_valid(day_transition_layer):
		day_transition_layer.queue_free()


func _process(delta: float) -> void:
	if is_minigame_playing:
		return

	if is_day_transition_playing or frozen:
		return

	shop_music_check_accum += delta
	if shop_music_check_accum >= SHOP_MUSIC_CHECK_INTERVAL:
		shop_music_check_accum = 0.0
		_update_shop_music_state()

	day_time_accum += delta
	while day_time_accum >= SECONDS_PER_INGAME_HOUR:
		day_time_accum -= SECONDS_PER_INGAME_HOUR
		_advance_ingame_hour()
	
	_update_shader_effects()

var smoothed_energy: float = 100.0
var smoothed_stress: float = 0.0

func _update_shader_effects() -> void:
	var tree := get_tree()
	if tree == null:
		return

	if hud == null or screen_fx == null or screen_fx.material == null:
		return

	
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
	if fatigue_factor > 0.3:
		blur = pow((fatigue_factor - 0.3) / 0.7, 2.0) * 7.0
		blur = clamp(blur, 0.0, 3.0)

	screen_fx.material.set_shader_parameter("blur_intensity", blur)

	var stress_curve: float = pow(stress_factor, 3.0)
	screen_fx.material.set_shader_parameter("stress_tunnel", stress_curve)
	
	var player = tree.get_first_node_in_group("Player")
	
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
	if event.is_action_pressed("ui_cancel"):
		if is_pause_menu_open:
			return
		if is_day_transition_playing or is_minigame_playing:
			return
		_open_pause_menu()
		return

	if is_day_transition_playing or is_minigame_playing:
		return

	if event.is_action_pressed("ui_interact"):
		if aura_npc_ref != null and aura_npc_ref.aura_active:
			_toggle_freeze()
		elif frozen:
			_toggle_freeze()


func _setup_pause_menu_ui() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 5000
	pause_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(pause_layer)

	pause_overlay = ColorRect.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.color = Color(0, 0, 0, 0.7)
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_layer.add_child(pause_overlay)

	pause_menu_container = CenterContainer.new()
	pause_menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu_container.visible = false
	pause_menu_container.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_layer.add_child(pause_menu_container)

	pause_options_menu = OPTIONS_MENU_SCENE.instantiate() as PanelContainer
	pause_options_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_menu_container.add_child(pause_options_menu)

	if pause_options_menu != null and pause_options_menu.has_signal("menu_closed"):
		pause_options_menu.menu_closed.connect(_close_pause_menu)


func _open_pause_menu() -> void:
	if is_pause_menu_open:
		return
	is_pause_menu_open = true

	if pause_options_menu != null and pause_options_menu.has_method("load_current_settings"):
		pause_options_menu.load_current_settings()

	pause_overlay.visible = true
	pause_menu_container.visible = true
	get_tree().paused = true


func _close_pause_menu() -> void:
	if not is_pause_menu_open:
		return

	is_pause_menu_open = false
	pause_menu_container.visible = false
	pause_overlay.visible = false
	get_tree().paused = false


func _toggle_freeze() -> void:
	frozen = not frozen
	print("[Scenario] toggle freeze -> ", frozen)
	if frozen:
		selected_npc_ref = aura_npc_ref
		if spawner != null and spawner.has_method("show_npc_toast"):
			spawner.show_npc_toast(selected_npc_ref)
		_populate_npc_description(selected_npc_ref)
	else:
		if spawner != null and spawner.has_method("hide_npc_toast"):
			spawner.hide_npc_toast()
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
	var accepted_mission_id: String = ""
	var npc_to_resolve: Node = selected_npc_ref

	if accepted and selected_npc_ref != null and selected_npc_ref.has_method("get_current_mission_id"):
		var mission_id: String = selected_npc_ref.get_current_mission_id()
		accepted_mission_id = mission_id
		if hud != null and hud.has_method("consumir_energia_mision"):
			hud.consumir_energia_mision(20.0)

	if accepted_mission_id != "":
		pending_mission_npc_ref = npc_to_resolve
		if npc_to_resolve != null:
			if npc_to_resolve.has_method("begin_mission"):
				npc_to_resolve.begin_mission()
			elif npc_to_resolve.has_method("resolve_mission"):
				npc_to_resolve.resolve_mission(true)
	elif npc_to_resolve != null and npc_to_resolve.has_method("resolve_mission"):
		npc_to_resolve.resolve_mission(false)

	if frozen:
		_toggle_freeze()

	if accepted_mission_id != "":
		_start_minigame_for_mission(accepted_mission_id)


func _initialize_day_cycle() -> void:
	day_time_accum = 0.0
	current_hour = DAY_START_HOUR
	if hud != null and hud.has_method("set_dia"):
		hud.set_dia(current_day)
	if hud != null and hud.has_method("set_hora"):
		hud.set_hora(current_hour)
	if spawner != null and spawner.has_method("apply_day_settings"):
		spawner.apply_day_settings(current_day)


func _advance_ingame_hour() -> void:
	current_hour += 1
	if hud != null and hud.has_method("set_hora"):
		hud.set_hora(current_hour)

	if current_hour >= DAY_END_HOUR:
		if current_day >= FINAL_DAY:
			_trigger_final_ending()
			return

		current_day += 1
		current_hour = DAY_START_HOUR
		if hud != null and hud.has_method("set_dia"):
			hud.set_dia(current_day)
		if hud != null and hud.has_method("set_hora"):
			hud.set_hora(current_hour)
		_start_day_transition(current_day)


func _trigger_final_ending() -> void:
	_set_world_paused(true)
	is_day_transition_playing = true
	if day_transition_layer != null:
		day_transition_layer.visible = true
	if day_transition_label != null:
		day_transition_label.visible = false
	if day_transition_rect != null:
		day_transition_rect.color = Color(0, 0, 0, 0)
		var fade_tween := create_tween()
		fade_tween.tween_property(day_transition_rect, "color", Color(0, 0, 0, 1), 0.5)
		await fade_tween.finished

	var final_money: int = 0
	var final_stress: float = 0.0

	if hud != null:
		final_money = int(hud.get("dinero"))
		if hud.has_method("get_stress_percent"):
			final_stress = float(hud.get_stress_percent())

	if GameManager != null and GameManager.has_method("set_final_stats"):
		GameManager.set_final_stats(final_stress, final_money, current_day)

	get_tree().change_scene_to_file(ENDING_SCENE_PATH)


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
	if spawner != null and spawner.has_method("on_day_changed"):
		spawner.on_day_changed(current_day)
	if hud != null and hud.has_method("iniciar_dia_stats"):
		hud.iniciar_dia_stats()
	_set_world_paused(false)
	_update_shop_music_state(true)


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
	var date_text := _get_day_transition_date_text(day_number)
	match LocaleManager.current_language:
		"en":
			return "Day %d - %s" % [day_number, date_text]
		"pt":
			return "Dia %d - %s" % [day_number, date_text]
		_:
			return "Dia %d - %s" % [day_number, date_text]


func _get_day_transition_date_text(day_number: int) -> String:
	var offset_days: int = max(0, day_number - 1)
	var y: int = START_YEAR
	var m: int = START_MONTH
	var d: int = START_DAY

	while offset_days > 0:
		d += 1
		var days_in_month: int = _days_in_month(m, y)
		if d > days_in_month:
			d = 1
			m += 1
			if m > 12:
				m = 1
				y += 1
		offset_days -= 1

	return "%02d/%02d/%04d" % [d, m, y]


func _days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			if _is_leap_year(year):
				return 29
			return 28
		_:
			return 30


func _is_leap_year(year: int) -> bool:
	if year % 400 == 0:
		return true
	if year % 100 == 0:
		return false
	return year % 4 == 0


func _setup_shop_music() -> void:
	shop_music_a = AudioStreamPlayer.new()
	shop_music_a.name = "ShopMusicA"
	shop_music_a.bus = &"Music"
	shop_music_a.volume_db = SHOP_MUSIC_MUTED_DB
	shop_music_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shop_music_a)

	shop_music_b = AudioStreamPlayer.new()
	shop_music_b.name = "ShopMusicB"
	shop_music_b.bus = &"Music"
	shop_music_b.volume_db = SHOP_MUSIC_MUTED_DB
	shop_music_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shop_music_b)


func _update_shop_music_state(force: bool = false) -> void:
	if hud == null:
		return

	var target_key: String = _get_target_shop_music_key()
	if target_key == "":
		return

	if not force and target_key == current_shop_music_key:
		return

	_crossfade_shop_music(target_key)


func _get_target_shop_music_key() -> String:
	var energy_percent: float = 100.0
	var stress_percent: float = 0.0

	if hud.has_method("get_energy_percent"):
		energy_percent = float(hud.get_energy_percent())
	if hud.has_method("get_stress_percent"):
		stress_percent = float(hud.get_stress_percent())

	var energy_band := "normal"
	if energy_percent <= 33.0:
		energy_band = "very_low"
	elif energy_percent <= 66.0:
		energy_band = "low"

	var stress_band := "normal"
	if stress_percent >= 66.0:
		stress_band = "high_stress"
	elif stress_percent >= 33.0:
		stress_band = "stress"

	return "%s_%s" % [energy_band, stress_band]


func _crossfade_shop_music(target_key: String) -> void:
	if not SHOP_MUSIC_STREAMS.has(target_key):
		return

	var from_player: AudioStreamPlayer = shop_music_a if shop_music_using_a else shop_music_b
	var to_player: AudioStreamPlayer = shop_music_b if shop_music_using_a else shop_music_a
	var target_stream: AudioStream = SHOP_MUSIC_STREAMS[target_key]

	if to_player.stream != target_stream:
		to_player.stream = target_stream

	to_player.volume_db = SHOP_MUSIC_MUTED_DB
	if not to_player.playing:
		to_player.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(to_player, "volume_db", SHOP_MUSIC_ACTIVE_DB, SHOP_MUSIC_CROSSFADE_SECONDS)
	tween.tween_property(from_player, "volume_db", SHOP_MUSIC_MUTED_DB, SHOP_MUSIC_CROSSFADE_SECONDS)
	tween.finished.connect(func():
		if from_player.playing:
			from_player.stop()
	)

	shop_music_using_a = not shop_music_using_a
	current_shop_music_key = target_key


func _setup_making_task_player() -> void:
	making_task_player = AudioStreamPlayer.new()
	making_task_player.name = "MakingTaskPlayer"
	making_task_player.bus = &"Music"
	making_task_player.volume_db = SHOP_MUSIC_ACTIVE_DB
	making_task_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(making_task_player)


func _start_minigame_for_mission(mission_id: String) -> void:
	if not MINIGAME_SCENES_BY_MISSION.has(mission_id):
		push_warning("No hay escena de minijuego para mission_id='%s'" % mission_id)
		return

	var scene_path: String = MINIGAME_SCENES_BY_MISSION[mission_id]
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("No se pudo cargar minijuego en '%s'" % scene_path)
		return

	if is_minigame_playing:
		return

	active_minigame_mission_id = mission_id
	is_minigame_playing = true
	_set_world_paused(true)
	_pause_shop_music_for_minigame()
	_play_making_task_for_current_stress()

	minigame_layer = CanvasLayer.new()
	minigame_layer.layer = 3072
	minigame_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(minigame_layer)

	minigame_host = Control.new()
	minigame_host.name = "MinigameHost"
	minigame_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	minigame_layer.add_child(minigame_host)

	active_minigame = packed_scene.instantiate()
	var money_range: Vector2i = _get_mission_money_range(mission_id)
	var stress_difficulty: float = 0.0
	if hud != null and hud.has_method("get_stress_percent"):
		stress_difficulty = clampf(float(hud.get_stress_percent()), 0.0, 100.0)
	_set_if_has_property(active_minigame, "mission_money_min", money_range.x)
	_set_if_has_property(active_minigame, "mission_money_max", money_range.y)
	_set_if_has_property(active_minigame, "stress_difficulty", stress_difficulty)
	minigame_host.add_child(active_minigame)

	if active_minigame is Control:
		var minigame_control := active_minigame as Control
		minigame_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif active_minigame is Node2D:
		var minigame_node2d := active_minigame as Node2D
		minigame_node2d.position = get_viewport_rect().size * 0.5

	if active_minigame.has_signal("minigame_finished"):
		active_minigame.minigame_finished.connect(_on_minigame_finished_standard.bind(active_minigame, mission_id), CONNECT_ONE_SHOT)

	var warehouse_manager: Node = active_minigame.get_node_or_null("GameManager")
	if warehouse_manager != null:
		_set_if_has_property(warehouse_manager, "mission_money_min", money_range.x)
		_set_if_has_property(warehouse_manager, "mission_money_max", money_range.y)
		_set_if_has_property(warehouse_manager, "stress_difficulty", stress_difficulty)
	if warehouse_manager != null and warehouse_manager.has_signal("minigame_finished"):
		warehouse_manager.minigame_finished.connect(_on_minigame_finished_warehouse.bind(warehouse_manager, mission_id), CONNECT_ONE_SHOT)

	active_minigame.tree_exited.connect(_on_active_minigame_tree_exited, CONNECT_ONE_SHOT)


func _on_minigame_finished_standard(_a = null, _b = null, _c = null, source_node: Node = null, mission_id: String = "") -> void:
	_handle_minigame_finished(_a, _b, _c, source_node, mission_id)


func _on_minigame_finished_warehouse(_a = null, source_node: Node = null, mission_id: String = "") -> void:
	_handle_minigame_finished(_a, null, null, source_node, mission_id)


func _handle_minigame_finished(_a = null, _b = null, _c = null, source_node: Node = null, mission_id: String = "") -> void:
	if is_resolving_minigame_finish:
		return
	is_resolving_minigame_finish = true
	var minigame_success: bool = _a if _a is bool else false

	var resolved_mission_id: String = mission_id if mission_id != "" else active_minigame_mission_id
	if resolved_mission_id != "":
		var metrics := _build_minigame_metrics(resolved_mission_id, _a, _b, _c, source_node)
		_apply_minigame_outcome(resolved_mission_id, metrics, source_node)
		await _show_minigame_summary_modal(metrics)

	_resolve_pending_mission_after_minigame(minigame_success)

	is_resolving_minigame_finish = false
	_end_active_minigame()


func _build_minigame_metrics(mission_id: String, result_a: Variant, result_b: Variant, result_c: Variant, source_node: Node) -> Dictionary:
	var success: bool = result_a if result_a is bool else false
	var eficiencia: float = 0.0
	var desempeno: float = 100.0

	if mission_id == "indications" and source_node != null:
		var puntos: float = float(source_node.get("puntos"))
		var puntos_victoria: float = max(1.0, float(source_node.get("puntos_victoria")))
		var errores: float = float(source_node.get("errores"))
		var limite_errores: float = max(1.0, float(source_node.get("limite_errores")))
		eficiencia = clamp((puntos / puntos_victoria) * 100.0, 0.0, 100.0)
		desempeno = clamp((errores / limite_errores) * 100.0, 0.0, 100.0)
	elif mission_id == "store_warehouse" and source_node != null:
		var boxes_collected: float = float(source_node.get("boxes_collected"))
		var target_boxes: float = max(1.0, float(source_node.get("target_boxes")))
		var hits_taken: float = float(source_node.get("hits_taken"))
		var max_hits: float = max(1.0, float(source_node.get("max_hits")))
		eficiencia = clamp((boxes_collected / target_boxes) * 100.0, 0.0, 100.0)
		desempeno = clamp((hits_taken / max_hits) * 100.0, 0.0, 100.0)
	else:
		var score: float = float(result_b) if result_b is int or result_b is float else (1.0 if success else 0.0)
		var total_rounds: float = float(result_c) if result_c is int or result_c is float else 1.0
		total_rounds = max(1.0, total_rounds)
		eficiencia = clamp((score / total_rounds) * 100.0, 0.0, 100.0)
		desempeno = clamp(100.0 - eficiencia, 0.0, 100.0)

	var estres: float = lerpf(1.0, 8.0, desempeno / 100.0)
	var money_range: Vector2i = _get_mission_money_range(mission_id)
	var recompensa_total: int = int(round(lerpf(float(money_range.x), float(money_range.y), eficiencia / 100.0)))

	return {
		"eficiencia": eficiencia,
		"desempeno": desempeno,
		"estres": estres,
		"recompensa_total": recompensa_total,
	}


func _get_mission_money_range(mission_id: String) -> Vector2i:
	if not mission_data_by_id.has(mission_id):
		return Vector2i(0, 0)
	var mission: Dictionary = mission_data_by_id[mission_id]
	var money: Dictionary = mission.get("money", {})
	var min_money: int = int(money.get("min", 0))
	var max_money: int = int(money.get("max", min_money))
	if max_money < min_money:
		max_money = min_money
	return Vector2i(min_money, max_money)


func _apply_minigame_outcome(mission_id: String, metrics: Dictionary, source_node: Node) -> void:
	var recompensa_total: int = max(0, int(metrics.get("recompensa_total", 0)))
	var estres: float = float(metrics.get("estres", 0.0))

	var money_applied: bool = false
	if hud != null and hud.has_method("actualizar_dinero"):
		hud.actualizar_dinero(recompensa_total)
		money_applied = true
	elif spawner != null and spawner.has_method("add_money"):
		spawner.add_money(recompensa_total)
		money_applied = true
	if hud != null and hud.has_method("actualizar_stress"):
		hud.actualizar_stress(estres)

	if source_node != null:
		_set_if_has_property(source_node, "eficiencia", float(metrics.get("eficiencia", 0.0)))
		_set_if_has_property(source_node, "desempeno", float(metrics.get("desempeno", 0.0)))
		_set_if_has_property(source_node, "recompensa_total", recompensa_total)
		_set_if_has_property(source_node, "estres", estres)

	if active_minigame != null and active_minigame != source_node:
		_set_if_has_property(active_minigame, "eficiencia", float(metrics.get("eficiencia", 0.0)))
		_set_if_has_property(active_minigame, "desempeno", float(metrics.get("desempeno", 0.0)))
		_set_if_has_property(active_minigame, "recompensa_total", recompensa_total)
		_set_if_has_property(active_minigame, "estres", estres)

	print("[Scenario] minigame=", mission_id, " eficiencia=", int(round(float(metrics.get("eficiencia", 0.0)))), "% desempeno=", int(round(float(metrics.get("desempeno", 0.0)))), "% estres=", int(round(estres)), " recompensa=", recompensa_total, " money_applied=", money_applied)


func _set_if_has_property(node: Object, prop_name: String, value: Variant) -> void:
	for prop in node.get_property_list():
		if String(prop.get("name", "")) == prop_name:
			node.set(prop_name, value)
			return


func _show_minigame_summary_modal(metrics: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4200
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 340)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_top = -170
	panel.offset_right = 310
	panel.offset_bottom = 170
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 24
	content.offset_top = 24
	content.offset_right = -24
	content.offset_bottom = -24
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", MINIGAME_SUMMARY_FONT)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.687779, 0.643646, 0.632612, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.189829, 0.0827736, 0.0013467, 1.0))
	title.add_theme_constant_override("outline_size", 7)
	title.text = _get_summary_title_text()
	content.add_child(title)

	var reward_value: int = int(metrics.get("recompensa_total", 0))
	var stress_accum: int = 0
	if hud != null and hud.has_method("get_stress_percent"):
		stress_accum = int(round(float(hud.get_stress_percent())))

	var body := Label.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", MINIGAME_SUMMARY_FONT)
	body.add_theme_font_size_override("font_size", 28)
	body.add_theme_color_override("font_color", Color(0.687779, 0.643646, 0.632612, 1.0))
	body.add_theme_color_override("font_outline_color", Color(0.189829, 0.0827736, 0.0013467, 1.0))
	body.add_theme_constant_override("outline_size", 5)
	body.text = _get_summary_body_text(reward_value, stress_accum)
	content.add_child(body)

	var continue_button := Button.new()
	continue_button.custom_minimum_size = Vector2(0, 56)
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.text = _get_summary_continue_text()
	continue_button.add_theme_font_override("font", MINIGAME_SUMMARY_FONT)
	continue_button.add_theme_font_size_override("font_size", 30)
	continue_button.add_theme_color_override("font_color", Color(0.687779, 0.643646, 0.632612, 1.0))
	continue_button.add_theme_color_override("font_outline_color", Color(0.189829, 0.0827736, 0.0013467, 1.0))
	continue_button.add_theme_constant_override("outline_size", 4)
	content.add_child(continue_button)
	continue_button.grab_focus()

	await continue_button.pressed
	if is_instance_valid(layer):
		layer.queue_free()


func _get_summary_title_text() -> String:
	match LocaleManager.current_language:
		"en":
			return "Task Summary"
		"pt":
			return "Resumo da Tarefa"
		_:
			return "Resumen del Minijuego"


func _get_summary_body_text(reward_value: int, stress_accum: int) -> String:
	match LocaleManager.current_language:
		"en":
			return "Total reward: $%d\nAccumulated stress: %d%%" % [reward_value, stress_accum]
		"pt":
			return "Recompensa total: $%d\nEstresse acumulado: %d%%" % [reward_value, stress_accum]
		_:
			return "Recompensa total: $%d\nEstres acumulado: %d%%" % [reward_value, stress_accum]


func _get_summary_continue_text() -> String:
	match LocaleManager.current_language:
		"en":
			return "Continue"
		"pt":
			return "Continuar"
		_:
			return "Continuar"


func _on_active_minigame_tree_exited() -> void:
	if is_resolving_minigame_finish:
		return
	_resolve_pending_mission_after_minigame(false)
	_end_active_minigame()


func _end_active_minigame() -> void:
	if not is_minigame_playing:
		return

	is_minigame_playing = false

	if making_task_player != null and making_task_player.playing:
		making_task_player.stop()

	if minigame_layer != null and is_instance_valid(minigame_layer):
		minigame_layer.queue_free()

	active_minigame = null
	active_minigame_mission_id = ""
	pending_mission_npc_ref = null
	minigame_host = null
	minigame_layer = null

	_set_world_paused(false)
	_update_shop_music_state(true)


func _pause_shop_music_for_minigame() -> void:
	if shop_music_a != null and shop_music_a.playing:
		shop_music_a.stop()
	if shop_music_b != null and shop_music_b.playing:
		shop_music_b.stop()


func _play_making_task_for_current_stress() -> void:
	if making_task_player == null:
		return

	var stress_percent: float = 0.0
	if hud != null and hud.has_method("get_stress_percent"):
		stress_percent = float(hud.get_stress_percent())

	var stream: AudioStream = MAKING_TASK_NORMAL
	if stress_percent >= 66.0:
		stream = MAKING_TASK_HIGH_STRESS
	elif stress_percent >= 33.0:
		stream = MAKING_TASK_STRESS

	if making_task_player.stream != stream:
		making_task_player.stream = stream

	if not making_task_player.playing:
		making_task_player.play()


func _resolve_pending_mission_after_minigame(success: bool) -> void:
	if pending_mission_npc_ref == null:
		return
	if pending_mission_npc_ref.has_method("finish_mission"):
		pending_mission_npc_ref.finish_mission(success)
	elif pending_mission_npc_ref.has_method("resolve_mission"):
		pending_mission_npc_ref.resolve_mission(success)
