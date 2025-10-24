extends Control

# --- UI Element References ---
@onready var screen_mode_button = $MarginContainer/VBoxContainer/ScreenModeContainer/ScreenModeButton
@onready var resolution_button = $MarginContainer/VBoxContainer/ResolutionContainer/ResolutionButton
@onready var frame_limit_button = $MarginContainer/VBoxContainer/FrameLimitContainer/FrameLimitButton
@onready var language_button = $MarginContainer/VBoxContainer/LanguageContainer/LanguageButton
@onready var color_mode_button = $MarginContainer/VBoxContainer/ColorModeContainer/ColorModeButton
@onready var anti_aliasing_button = $MarginContainer/VBoxContainer/AntiAliasingContainer/AntiAliasingButton
@onready var low_spec_button = $MarginContainer/VBoxContainer/LowSpecContainer/LowSpecButton
@onready var audio_buffer_button = $MarginContainer/VBoxContainer/AudioBufferContainer/AudioBufferButton
@onready var audio_device_button = $MarginContainer/VBoxContainer/AudioDeviceContainer/AudioDeviceButton
@onready var background_audio_button = $MarginContainer/VBoxContainer/BackgroundAudioContainer/BackgroundAudioButton
@onready var master_volume_slider = $MarginContainer/VBoxContainer/VolumeGridContainer/MasterVolumeSlider
@onready var music_volume_slider = $MarginContainer/VBoxContainer/VolumeGridContainer/MusicVolumeSlider
@onready var sfx_volume_slider = $MarginContainer/VBoxContainer/VolumeGridContainer/SFXVolumeSlider
@onready var ui_volume_slider = $MarginContainer/VBoxContainer/VolumeGridContainer/UIVolumeSlider
@onready var master_volume_label = $MarginContainer/VBoxContainer/VolumeGridContainer/MasterVolumeLabel
@onready var music_volume_label = $MarginContainer/VBoxContainer/VolumeGridContainer/MusicVolumeLabel
@onready var sfx_volume_label = $MarginContainer/VBoxContainer/VolumeGridContainer/SFXVolumeLabel
@onready var ui_volume_label = $MarginContainer/VBoxContainer/VolumeGridContainer/UIVolumeLabel
@onready var compressor_check_button = $MarginContainer/VBoxContainer/CompressorContainer/CompressorCheckButton
@onready var tutorial_button = $MarginContainer/VBoxContainer/TutorialButton # NEW
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var restart_notice_label = $MarginContainer/VBoxContainer/RestartNoticeLabel

# --- Container References ---
@onready var screen_mode_container = $MarginContainer/VBoxContainer/ScreenModeContainer
@onready var resolution_container = $MarginContainer/VBoxContainer/ResolutionContainer
@onready var frame_limit_container = $MarginContainer/VBoxContainer/FrameLimitContainer
@onready var language_container = $MarginContainer/VBoxContainer/LanguageContainer
@onready var color_mode_container = $MarginContainer/VBoxContainer/ColorModeContainer
@onready var anti_aliasing_container = $MarginContainer/VBoxContainer/AntiAliasingContainer
@onready var low_spec_container = $MarginContainer/VBoxContainer/LowSpecContainer
@onready var audio_buffer_container = $MarginContainer/VBoxContainer/AudioBufferContainer
@onready var audio_device_container = $MarginContainer/VBoxContainer/AudioDeviceContainer
@onready var background_audio_container = $MarginContainer/VBoxContainer/BackgroundAudioContainer
@onready var volume_grid_container = $MarginContainer/VBoxContainer/VolumeGridContainer
@onready var compressor_container = $MarginContainer/VBoxContainer/CompressorContainer

# --- Constants & Variables ---
const locales = ["en", "ja", "ko"]
const SETTINGS_PATH = "user://settings.cfg"
var available_resolutions = []
var pending_restart = false

# --- Godot Built-in Functions ---
func _ready():
	restart_notice_label.hide()
	_setup_options()
	_load_settings()
	_update_ui_text()

# --- Setup & Load Functions ---

func _setup_options():
	# Language, Platform, Graphics, other Audio options...
	language_button.add_item("English", 0); language_button.add_item("日本語", 1); language_button.add_item("한국어", 2)
	var os_name = OS.get_name()
	if os_name in ["Windows", "macOS", "Linux", "BSD"]: _setup_pc_options()
	else: _setup_mobile_options()
	color_mode_button.add_item("Off", UserSettings.ColorMode.DEFAULT); color_mode_button.add_item("Protanopia/Deuteranopia", UserSettings.ColorMode.DEUTERANOPIA); color_mode_button.add_item("Tritanopia", UserSettings.ColorMode.TRITANOPIA)
	anti_aliasing_button.add_item("Off", Viewport.MSAA_DISABLED); anti_aliasing_button.add_item("MSAA 2x", Viewport.MSAA_2X); anti_aliasing_button.add_item("MSAA 4x", Viewport.MSAA_4X); anti_aliasing_button.add_item("MSAA 8x", Viewport.MSAA_8X)
	low_spec_button.add_item("Off", 0); low_spec_button.add_item("On", 1)
	var sample_rate = ProjectSettings.get_setting("audio/driver/mix_rate")
	var buffer_sizes = [32, 64, 128, 192, 256, 320, 384, 448, 512]
	for buffer_size in buffer_sizes: audio_buffer_button.add_item("%d (%.1fms)" % [buffer_size, float(buffer_size) / sample_rate * 1000.0], buffer_size)
	for slider in [master_volume_slider, music_volume_slider, sfx_volume_slider, ui_volume_slider]: slider.min_value = 0; slider.max_value = 10; slider.step = 1

func _setup_pc_options():
	# Screen Mode, Resolution, Frame Limit, Audio Device...
	screen_mode_button.add_item("temp", DisplayServer.WINDOW_MODE_FULLSCREEN); screen_mode_button.add_item("temp", DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN); screen_mode_button.add_item("temp", DisplayServer.WINDOW_MODE_WINDOWED)
	resolution_button.clear(); available_resolutions.clear()
	var native_size = DisplayServer.screen_get_size(); available_resolutions.append(native_size); resolution_button.add_item("%d x %d (Native)" % [native_size.x, native_size.y], 0)
	var predefined_resolutions = [Vector2i(3840, 2160), Vector2i(2560, 1440), Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1280, 720)]
	for res in predefined_resolutions:
		if res.x < native_size.x and not res in available_resolutions: available_resolutions.append(res); resolution_button.add_item("%d x %d" % [res.x, res.y], available_resolutions.size() - 1)
	frame_limit_button.add_item("temp", -1)
	var frame_rates = [60, 75, 90, 120, 144, 240, 360, 400];
	for fps in frame_rates: frame_limit_button.add_item("%d FPS" % fps, fps)
	frame_limit_button.add_item("Unlimited", 0)
	audio_device_button.clear()
	var device_list = AudioServer.get_output_device_list()
	for i in device_list.size(): audio_device_button.add_item(device_list[i], i)
	background_audio_button.add_item("Off", 0); background_audio_button.add_item("On", 1)

func _setup_mobile_options():
	screen_mode_container.hide(); resolution_container.hide()
	audio_buffer_container.hide(); audio_device_container.hide()
	background_audio_container.hide(); compressor_container.hide()
	volume_grid_container.hide()
	frame_limit_button.add_item("60 FPS", 60); frame_limit_button.add_item("30 FPS", 30)

func _load_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK: return

	# Load common, graphics, and PC-specific settings...
	var locale = config.get_value("Settings", "locale", "en"); TranslationServer.set_locale(locale); language_button.select(locales.find(locale))
	var color_mode = config.get_value("Graphics", "color_mode", UserSettings.ColorMode.DEFAULT); UserSettings.set_color_mode(color_mode); _select_item_by_id(color_mode_button, color_mode)
	var aa_mode = config.get_value("Graphics", "anti_aliasing", Viewport.MSAA_DISABLED); get_viewport().msaa_2d = aa_mode; _select_item_by_id(anti_aliasing_button, aa_mode)
	var low_spec_on = config.get_value("Graphics", "low_spec_mode", false); UserSettings.set_low_spec_mode(low_spec_on); _select_item_by_id(low_spec_button, 1 if low_spec_on else 0)
	if screen_mode_container.visible:
		var screen_mode = config.get_value("Graphics", "screen_mode", DisplayServer.WINDOW_MODE_FULLSCREEN); DisplayServer.window_set_mode(screen_mode); _select_item_by_id(screen_mode_button, screen_mode)
		var saved_res = config.get_value("Graphics", "resolution", DisplayServer.screen_get_size()); var res_idx = available_resolutions.find(saved_res); resolution_button.select(res_idx if res_idx != -1 else 0)
		var frame_limit = config.get_value("Graphics", "frame_limit", -1)
		if frame_limit == -1: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED); Engine.max_fps = 0
		else: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps = frame_limit
		_select_item_by_id(frame_limit_button, frame_limit)

	# Load Audio Settings...
	if audio_buffer_container.visible: _select_item_by_id(audio_buffer_button, config.get_value("Audio", "buffer_size", 512))
	if audio_device_container.visible:
		var device_list = AudioServer.get_output_device_list(); var device_idx = device_list.find(AudioServer.get_output_device())
		if device_idx != -1: audio_device_button.select(device_idx)
	if background_audio_container.visible: _select_item_by_id(background_audio_button, 1 if config.get_value("Audio", "play_in_background", false) else 0)
	master_volume_slider.value = UserSettings.master_volume; master_volume_label.text = str(int(UserSettings.master_volume))
	music_volume_slider.value = UserSettings.music_volume; music_volume_label.text = str(int(UserSettings.music_volume))
	sfx_volume_slider.value = UserSettings.sfx_volume; sfx_volume_label.text = str(int(UserSettings.sfx_volume))
	ui_volume_slider.value = UserSettings.ui_volume; ui_volume_label.text = str(int(UserSettings.ui_volume))
	if compressor_container.visible:
		var compressor_on = config.get_value("Audio", "compressor_on", false)
		# [MODIFIED] Target Music bus instead of Master
		var music_bus_idx = AudioServer.get_bus_index("Music")
		if music_bus_idx != -1:
			var effect_idx = 0 # Assuming compressor is the first effect on the Music bus
			AudioServer.set_bus_effect_enabled(music_bus_idx, effect_idx, compressor_on)
		compressor_check_button.button_pressed = compressor_on

func _select_item_by_id(button: OptionButton, id):
	for i in button.get_item_count():
		if button.get_item_id(i) == id: button.select(i); return

func _update_ui_text():
	# Labels...
	restart_notice_label.text = tr("OPTIONS_RESTART_REQUIRED")
	screen_mode_container.get_node("Label").text = tr("OPTIONS_SCREEN_MODE"); resolution_container.get_node("Label").text = tr("OPTIONS_RESOLUTION"); frame_limit_container.get_node("Label").text = tr("OPTIONS_FRAME_LIMIT"); language_container.get_node("Label").text = tr("OPTIONS_LANGUAGE"); color_mode_container.get_node("Label").text = tr("OPTIONS_COLOR_MODE"); anti_aliasing_container.get_node("Label").text = tr("OPTIONS_ANTIALIASING"); low_spec_container.get_node("Label").text = tr("OPTIONS_LOW_SPEC"); audio_buffer_container.get_node("Label").text = tr("OPTIONS_AUDIO_BUFFER"); audio_device_container.get_node("Label").text = tr("OPTIONS_AUDIO_DEVICE"); background_audio_container.get_node("Label").text = tr("OPTIONS_BACKGROUND_AUDIO");
	volume_grid_container.get_node("MasterVolumeLabel").text = tr("OPTIONS_MASTER_VOLUME"); volume_grid_container.get_node("MusicVolumeLabel").text = tr("OPTIONS_MUSIC_VOLUME"); volume_grid_container.get_node("SFXVolumeLabel").text = tr("OPTIONS_SFX_VOLUME"); volume_grid_container.get_node("UIVolumeLabel").text = tr("OPTIONS_UI_VOLUME");
	compressor_container.get_node("Label").text = tr("OPTIONS_COMPRESSOR")
	back_button.text = tr("UI_BACK")
	tutorial_button.text = tr("OPTIONS_TUTORIAL") # NEW
	
	# OptionButton Items...
	if screen_mode_container.visible: screen_mode_button.set_item_text(0, tr("OPTIONS_BORDERLESS_FULLSCREEN")); screen_mode_button.set_item_text(1, tr("OPTIONS_EXCLUSIVE_FULLSCREEN")); screen_mode_button.set_item_text(2, tr("OPTIONS_WINDOWED"))
	if frame_limit_container.visible and not OS.get_name() in ["Android", "iOS"]: frame_limit_button.set_item_text(0, tr("OPTIONS_VSYNC"))
	low_spec_button.set_item_text(0, tr("UI_OFF")); low_spec_button.set_item_text(1, tr("UI_ON"))
	if background_audio_container.visible: background_audio_button.set_item_text(0, tr("UI_OFF")); background_audio_button.set_item_text(1, tr("UI_ON"))


# --- Signal Callbacks ---
func _on_language_button_item_selected(index): var selected_locale = locales[index]; TranslationServer.set_locale(selected_locale); _update_ui_text(); _save_setting("Settings", "locale", selected_locale)
func _on_color_mode_button_item_selected(index): var selected_mode = color_mode_button.get_item_id(index); UserSettings.set_color_mode(selected_mode); _save_setting("Graphics", "color_mode", selected_mode)
func _on_anti_aliasing_button_item_selected(index): var selected_aa = anti_aliasing_button.get_item_id(index); get_viewport().msaa_2d = selected_aa; _save_setting("Graphics", "anti_aliasing", selected_aa)
func _on_screen_mode_button_item_selected(index):
	var selected_mode = screen_mode_button.get_item_id(index); DisplayServer.window_set_mode(selected_mode)
	if selected_mode != DisplayServer.WINDOW_MODE_WINDOWED: var native_resolution = DisplayServer.screen_get_size(); DisplayServer.window_set_size(native_resolution); resolution_button.select(0); _save_setting("Graphics", "resolution", native_resolution)
	_save_setting("Graphics", "screen_mode", selected_mode)
func _on_resolution_button_item_selected(index):
	var selected_resolution = available_resolutions[index]
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED: DisplayServer.window_set_size(selected_resolution); DisplayServer.window_set_position(DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() - DisplayServer.window_get_size()) / 2)
	_save_setting("Graphics", "resolution", selected_resolution)
func _on_frame_limit_button_item_selected(index):
	var selected_limit = frame_limit_button.get_item_id(index)
	if selected_limit == -1: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED); Engine.max_fps = 0
	else: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps = selected_limit
	_save_setting("Graphics", "frame_limit", selected_limit)
func _on_low_spec_button_item_selected(index): var is_on = (low_spec_button.get_item_id(index) == 1); UserSettings.set_low_spec_mode(is_on); _save_setting("Graphics", "low_spec_mode", is_on)
func _on_audio_buffer_button_item_selected(index): var selected_buffer_size = audio_buffer_button.get_item_id(index); _save_setting("Audio", "buffer_size", selected_buffer_size); _show_restart_notice()
func _on_audio_device_button_item_selected(index): var device_name = audio_device_button.get_item_text(index); _save_setting("Audio", "output_device", device_name); _show_restart_notice()
func _on_background_audio_button_item_selected(index): var play_in_background = (background_audio_button.get_item_id(index) == 1); _save_setting("Audio", "play_in_background", play_in_background); _show_restart_notice()
func _on_master_volume_slider_value_changed(value: float): var int_value = int(round(value)); UserSettings.set_master_volume(int_value); master_volume_label.text = str(int_value); _save_setting("Audio", "master_volume", int_value)
func _on_music_volume_slider_value_changed(value: float): var int_value = int(round(value)); UserSettings.set_music_volume(int_value); music_volume_label.text = str(int_value); _save_setting("Audio", "music_volume", int_value)
func _on_sfx_volume_slider_value_changed(value: float): var int_value = int(round(value)); UserSettings.set_sfx_volume(int_value); sfx_volume_label.text = str(int_value); _save_setting("Audio", "sfx_volume", int_value)
func _on_ui_volume_slider_value_changed(value: float): var int_value = int(round(value)); UserSettings.set_ui_volume(int_value); ui_volume_label.text = str(int_value); _save_setting("Audio", "ui_volume", int_value)

func _on_compressor_check_button_toggled(button_pressed: bool):
	# [MODIFIED] Target the Music bus instead of the Master bus.
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx != -1:
		var effect_idx = 0 # Assuming the compressor is the first effect on the Music bus.
		AudioServer.set_bus_effect_enabled(music_bus_idx, effect_idx, button_pressed)
		_save_setting("Audio", "compressor_on", button_pressed)

func _on_tutorial_button_pressed(): # NEW
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# --- Helper & Save Functions ---
func _show_restart_notice(): pending_restart = true; restart_notice_label.show()
func _save_setting(section, key, value): var config = ConfigFile.new(); config.load(SETTINGS_PATH); config.set_value(section, key, value); config.save(SETTINGS_PATH)
