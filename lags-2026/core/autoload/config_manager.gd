extends Node

const CONFIG_FILE_PATH = "user://settings.cfg"
var _config: ConfigFile = ConfigFile.new()

var language: String = "es"
var music_volume: int = 7
var sfx_volume: int = 7

func _ready() -> void:
    _load_config()

func _load_config() -> void:
    if _config.load(CONFIG_FILE_PATH) == OK:
        language = _config.get_value("Settings", "language", "es")
        music_volume = _config.get_value("Settings", "music_volume", 7)
        sfx_volume = _config.get_value("Settings", "sfx_volume", 7)
    
    # Aplicar la configuración recién cargada
    apply_settings(language, music_volume, sfx_volume)

func save_config(new_lang: String, new_music: int, new_sfx: int) -> void:
    # Actualizar estado interno
    language = new_lang
    music_volume = new_music
    sfx_volume = new_sfx
    
    # Escribir en archivo
    _config.set_value("Settings", "language", language)
    _config.set_value("Settings", "music_volume", music_volume)
    _config.set_value("Settings", "sfx_volume", sfx_volume)
    _config.save(CONFIG_FILE_PATH)
    
    # Aplicar los cambios en el juego
    apply_settings(language, music_volume, sfx_volume)

func apply_settings(lang: String, music: int, sfx: int) -> void:
    # Aplicar Idioma Global (LocaleManager)
    if LocaleManager.current_language != lang:
        LocaleManager.change_language(lang)
        
    # Aplicar Volumen Global (AudioServer)
    # Encontrar Buses o crearlos si el usuario no los hizo en el editor
    var music_bus = AudioServer.get_bus_index("Music")
    if music_bus < 0:
        AudioServer.add_bus()
        music_bus = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(music_bus, "Music")
        
    var sfx_bus = AudioServer.get_bus_index("SFX")
    if sfx_bus < 0:
        AudioServer.add_bus()
        sfx_bus = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(sfx_bus, "SFX")
        
    # Convertimos volumen lineal 0-10 a decibelios
    AudioServer.set_bus_volume_db(music_bus, linear_to_db(music / 10.0))
    AudioServer.set_bus_mute(music_bus, music == 0)
    
    AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx / 10.0))
    AudioServer.set_bus_mute(sfx_bus, sfx == 0)
