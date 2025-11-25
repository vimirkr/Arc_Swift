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
	# Note: audio_device 설정은 런타임에 변경할 수 없으므로 AudioServer API 사용
	var audio_device = config.get_value("Audio", "output_device", "")
	if audio_device != "" and audio_device != "Default":
		# 유효한 장치인지 확인
		var device_list = AudioServer.get_output_device_list()
		if audio_device in device_list:
			AudioServer.output_device = audio_device
		else:
			print("[WARNING] Audio device '%s' not found. Using default." % audio_device)
	
	var play_in_background = config.get_value("Audio", "play_in_background", false)
	# 이 설정은 project.godot에서만 작동하므로 런타임 변경 불가
	# ProjectSettings.set_setting("application/run/disable_audio_when_unfocused", not play_in_background)

	# --- Apply Other Settings ---
	var locale = config.get_value("Settings", "locale", _get_initial_locale())
	TranslationServer.set_locale(locale)
	
	# --- Load Gameplay Settings ---
	UserSettings.scroll_speed = config.get_value("Gameplay", "scroll_speed", 5.0)
	UserSettings.gameplay_effect = config.get_value("Gameplay", "gameplay_effect", UserSettings.GameplayEffect.NONE)
	UserSettings.judgement_display_mode = config.get_value("Gameplay", "judgement_display_mode", UserSettings.JudgementDisplayMode.ALL_EXCEPT_ULTIMATE)
	UserSettings.audio_offset_ms = config.get_value("Gameplay", "audio_offset_ms", 0)
	UserSettings.is_sudden_death_on = config.get_value("Gameplay", "is_sudden_death_on", false)
	UserSettings.sudden_death_limit = config.get_value("Gameplay", "sudden_death_limit", 10)
	UserSettings.center_display_type = config.get_value("Gameplay", "center_display_type", UserSettings.CenterDisplayType.COMBO)
	UserSettings.note_fx_brightness = config.get_value("Gameplay", "note_fx_brightness", 1.0)
	
	Input.set_use_accumulated_input(false)

func _get_initial_locale():
	var os_locale = OS.get_locale().split("_")[0]
	if os_locale in SUPPORTED_LOCALES:
		return os_locale
	return SUPPORTED_LOCALES[0]
