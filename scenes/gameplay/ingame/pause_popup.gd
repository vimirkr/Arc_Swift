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

func _on_resume_button_pressed():
	resume_requested.emit()
	hide()

func _on_restart_button_pressed():
	restart_requested.emit()
	hide()

func _on_select_music_button_pressed():
	select_music_requested.emit()
	hide()
