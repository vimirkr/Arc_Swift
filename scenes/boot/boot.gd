# res://scenes/boot/boot.gd
extends Node

const SETTINGS_PATH = "user://settings.cfg"
const SUPPORTED_LOCALES = ["en", "ja", "ko"]

func _ready():
	_apply_initial_settings()
	get_tree().change_scene_to_file.call_deferred("res://scenes/boot/splash_screen.tscn")

func _apply_initial_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	# --- Load and Apply Audio Volumes ---
	# This must be done BEFORE other settings if they make sound.
	if err == OK:
		UserSettings.set_master_volume(config.get_value("Audio", "master_volume", 10.0))
		UserSettings.set_music_volume(config.get_value("Audio", "music_volume", 10.0))
		UserSettings.set_sfx_volume(config.get_value("Audio", "sfx_volume", 10.0))
		UserSettings.set_ui_volume(config.get_value("Audio", "ui_volume", 10.0))
	
	if err != OK:
		# No settings file, apply defaults
		TranslationServer.set_locale(_get_initial_locale())
		Input.set_use_accumulated_input(false)
		ProjectSettings.set_setting("application/run/disable_audio_when_unfocused", true)
		return

	# --- Apply Audio Driver Settings ---
	var audio_device = config.get_value("Audio", "output_device", "Default")
	ProjectSettings.set_setting("audio/driver/device", audio_device)
	
	var play_in_background = config.get_value("Audio", "play_in_background", false)
	ProjectSettings.set_setting("application/run/disable_audio_when_unfocused", not play_in_background)

	# [NEW] Load and apply audio buffer size
	var buffer_size = config.get_value("Audio", "buffer_size", 512)
	var mix_rate = ProjectSettings.get_setting("audio/driver/mix_rate")
	var latency_ms = int(round((float(buffer_size) / mix_rate) * 1000.0))
	ProjectSettings.set_setting("audio/driver/output_latency", latency_ms)

	# --- Apply Other Settings ---
	var locale = config.get_value("Settings", "locale", _get_initial_locale())
	TranslationServer.set_locale(locale)
	
	Input.set_use_accumulated_input(false)

func _get_initial_locale():
	var os_locale = OS.get_locale().split("_")[0]
	if os_locale in SUPPORTED_LOCALES:
		return os_locale
	return SUPPORTED_LOCALES[0]
