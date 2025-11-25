# res://scenes/gameplay/ingame/pause_popup.gd
extends CanvasLayer

signal resume_requested
signal restart_requested
signal select_music_requested

@onready var resume_button = $RootControl/CenterContainer/VBoxContainer/ResumeButton
@onready var restart_button = $RootControl/CenterContainer/VBoxContainer/RestartButton
@onready var select_music_button = $RootControl/CenterContainer/VBoxContainer/SelectMusicButton

func _ready():
	# 버튼 텍스트 현지화
	resume_button.text = tr("UI_RESUME")
	restart_button.text = tr("UI_RESTART")
	select_music_button.text = tr("UI_SELECT_MUSIC")
	
	# 버튼 시그널 연결
	if not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)
	if not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
	if not select_music_button.pressed.is_connected(_on_select_music_button_pressed):
		select_music_button.pressed.connect(_on_select_music_button_pressed)

func _on_resume_button_pressed():
	resume_requested.emit()
	hide()

func _on_restart_button_pressed():
	restart_requested.emit()
	hide()

func _on_select_music_button_pressed():
	select_music_requested.emit()
	hide()
