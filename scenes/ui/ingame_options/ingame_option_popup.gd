# res://scenes/ui/ingame_options/ingame_option_popup.gd
extends CanvasLayer

# --- UI Node References ---
@onready var scroll_speed_slider = $RootControl/MarginContainer/VBoxContainer/ScrollSpeedContainer/ScrollSpeedSlider
@onready var scroll_speed_spinbox = $RootControl/MarginContainer/VBoxContainer/ScrollSpeedContainer/ScrollSpeedSpinBox
@onready var effect_button = $RootControl/MarginContainer/VBoxContainer/EffectContainer/EffectButton
@onready var judgement_display_button = $RootControl/MarginContainer/VBoxContainer/JudgementDisplayContainer/JudgementDisplayButton
@onready var audio_offset_spinbox = $RootControl/MarginContainer/VBoxContainer/AudioOffsetContainer/AudioOffsetSpinBox
@onready var sudden_death_check = $RootControl/MarginContainer/VBoxContainer/SuddenDeathContainer/SuddenDeathCheck
@onready var sudden_death_limit_button = $RootControl/MarginContainer/VBoxContainer/SuddenDeathLimitContainer/SuddenDeathLimitButton
@onready var center_display_button = $RootControl/MarginContainer/VBoxContainer/CenterDisplayContainer/CenterDisplayButton
@onready var note_fx_slider = $RootControl/MarginContainer/VBoxContainer/NoteFXContainer/NoteFXSlider
@onready var close_button = $RootControl/MarginContainer/VBoxContainer/CloseButton

const SETTINGS_PATH = "user://settings.cfg"

func _ready():
	_setup_controls()
	_load_settings()
	_connect_signals()
	_update_sudden_death_ui()

func _setup_controls():
	# Scroll Speed Slider & SpinBox
	scroll_speed_slider.min_value = 1.0
	scroll_speed_slider.max_value = 10.0
	scroll_speed_slider.step = 0.1
	scroll_speed_spinbox.min_value = 1.0
	scroll_speed_spinbox.max_value = 10.0
	scroll_speed_spinbox.step = 0.1
	
	# Effect OptionButton
	effect_button.clear()
	effect_button.add_item(tr("EFFECT_NONE"), UserSettings.GameplayEffect.NONE)
	effect_button.add_item(tr("EFFECT_MIRROR"), UserSettings.GameplayEffect.MIRROR)
	effect_button.add_item(tr("EFFECT_FADE_IN"), UserSettings.GameplayEffect.FADE_IN)
	effect_button.add_item(tr("EFFECT_FADE_OUT"), UserSettings.GameplayEffect.FADE_OUT)
	
	# Judgement Display Mode OptionButton
	judgement_display_button.clear()
	judgement_display_button.add_item(tr("JUDGEMENT_ALL_EXCEPT_ULTIMATE"), UserSettings.JudgementDisplayMode.ALL_EXCEPT_ULTIMATE)
	judgement_display_button.add_item(tr("JUDGEMENT_BELOW_PERFECT"), UserSettings.JudgementDisplayMode.BELOW_PERFECT)
	judgement_display_button.add_item(tr("JUDGEMENT_HIDE"), UserSettings.JudgementDisplayMode.HIDE)
	judgement_display_button.add_item(tr("JUDGEMENT_OFF"), UserSettings.JudgementDisplayMode.OFF)
	
	# Audio Offset SpinBox
	audio_offset_spinbox.min_value = -500
	audio_offset_spinbox.max_value = 500
	audio_offset_spinbox.step = 1
	audio_offset_spinbox.suffix = "ms"
	
	# Sudden Death Limit OptionButton (1, 10, 100만 허용)
	sudden_death_limit_button.clear()
	sudden_death_limit_button.add_item("1", 0)
	sudden_death_limit_button.add_item("10", 1)
	sudden_death_limit_button.add_item("100", 2)
	
	# Center Display Type OptionButton
	center_display_button.clear()
	center_display_button.add_item(tr("CENTER_DISPLAY_SCORE"), UserSettings.CenterDisplayType.SCORE)
	center_display_button.add_item(tr("CENTER_DISPLAY_COMBO"), UserSettings.CenterDisplayType.COMBO)
	center_display_button.add_item(tr("CENTER_DISPLAY_SUDDEN_COUNT"), UserSettings.CenterDisplayType.SUDDEN_COUNT)
	center_display_button.add_item(tr("CENTER_DISPLAY_OFF"), UserSettings.CenterDisplayType.OFF)
	
	# Note FX Brightness Slider
	note_fx_slider.min_value = 0.0
	note_fx_slider.max_value = 1.0
	note_fx_slider.step = 0.1

func _load_settings():
	# Load from UserSettings
	scroll_speed_slider.value = UserSettings.scroll_speed
	scroll_speed_spinbox.value = UserSettings.scroll_speed
	
	_select_item_by_id(effect_button, UserSettings.gameplay_effect)
	_select_item_by_id(judgement_display_button, UserSettings.judgement_display_mode)
	
	audio_offset_spinbox.value = UserSettings.audio_offset_ms
	sudden_death_check.button_pressed = UserSettings.is_sudden_death_on
	
	# Sudden Death Limit 매핑 (1→0, 10→1, 100→2)
	match UserSettings.sudden_death_limit:
		1: sudden_death_limit_button.selected = 0
		10: sudden_death_limit_button.selected = 1
		100: sudden_death_limit_button.selected = 2
		_: sudden_death_limit_button.selected = 1  # 기본값 10
	
	_select_item_by_id(center_display_button, UserSettings.center_display_type)
	note_fx_slider.value = UserSettings.note_fx_brightness

func _connect_signals():
	scroll_speed_slider.value_changed.connect(_on_scroll_speed_slider_changed)
	scroll_speed_spinbox.value_changed.connect(_on_scroll_speed_spinbox_changed)
	effect_button.item_selected.connect(_on_effect_selected)
	judgement_display_button.item_selected.connect(_on_judgement_display_selected)
	audio_offset_spinbox.value_changed.connect(_on_audio_offset_changed)
	sudden_death_check.toggled.connect(_on_sudden_death_toggled)
	sudden_death_limit_button.item_selected.connect(_on_sudden_death_limit_selected)
	center_display_button.item_selected.connect(_on_center_display_selected)
	note_fx_slider.value_changed.connect(_on_note_fx_changed)
	close_button.pressed.connect(_on_close_button_pressed)

# --- Signal Handlers ---

func _on_scroll_speed_slider_changed(value: float):
	scroll_speed_spinbox.value = value
	UserSettings.scroll_speed = value
	_save_settings()

func _on_scroll_speed_spinbox_changed(value: float):
	scroll_speed_slider.value = value
	UserSettings.scroll_speed = value
	_save_settings()

func _on_effect_selected(index: int):
	UserSettings.gameplay_effect = effect_button.get_item_id(index)
	_save_settings()

func _on_judgement_display_selected(index: int):
	UserSettings.judgement_display_mode = judgement_display_button.get_item_id(index)
	_save_settings()

func _on_audio_offset_changed(value: float):
	UserSettings.audio_offset_ms = int(value)
	_save_settings()

func _on_sudden_death_toggled(is_on: bool):
	UserSettings.is_sudden_death_on = is_on
	_update_sudden_death_ui()
	_save_settings()

func _on_sudden_death_limit_selected(index: int):
	# 0→1, 1→10, 2→100
	match index:
		0: UserSettings.sudden_death_limit = 1
		1: UserSettings.sudden_death_limit = 10
		2: UserSettings.sudden_death_limit = 100
	_save_settings()

func _on_center_display_selected(index: int):
	UserSettings.center_display_type = center_display_button.get_item_id(index)
	_save_settings()

func _on_note_fx_changed(value: float):
	UserSettings.note_fx_brightness = value
	_save_settings()

func _on_close_button_pressed():
	hide()

# --- Helper Functions ---

# Sudden Death 활성화 시 Center Display 버튼 비활성화
func _update_sudden_death_ui():
	if UserSettings.is_sudden_death_on:
		center_display_button.disabled = true
		center_display_button.text = tr("CENTER_DISPLAY_FIXED_SUDDEN")
	else:
		center_display_button.disabled = false
		_select_item_by_id(center_display_button, UserSettings.center_display_type)

func _select_item_by_id(option_button: OptionButton, id: int):
	for i in range(option_button.item_count):
		if option_button.get_item_id(i) == id:
			option_button.selected = i
			return

func _save_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	# 기존 설정 유지를 위해 로드 시도 (실패해도 계속 진행)
	
	# Save Gameplay Settings
	config.set_value("Gameplay", "scroll_speed", UserSettings.scroll_speed)
	config.set_value("Gameplay", "gameplay_effect", UserSettings.gameplay_effect)
	config.set_value("Gameplay", "judgement_display_mode", UserSettings.judgement_display_mode)
	config.set_value("Gameplay", "audio_offset_ms", UserSettings.audio_offset_ms)
	config.set_value("Gameplay", "is_sudden_death_on", UserSettings.is_sudden_death_on)
	config.set_value("Gameplay", "sudden_death_limit", UserSettings.sudden_death_limit)
	config.set_value("Gameplay", "center_display_type", UserSettings.center_display_type)
	config.set_value("Gameplay", "note_fx_brightness", UserSettings.note_fx_brightness)
	
	config.save(SETTINGS_PATH)
