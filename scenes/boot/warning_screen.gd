extends Control

# Node paths updated to reflect the new scene structure without ScrollContainer.
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var body_label = $MarginContainer/VBoxContainer/BodyLabel
@onready var continue_label = $MarginContainer/VBoxContainer/ContinueLabel
@onready var timer = $Timer

# A flag to prevent changing the scene multiple times.
var _is_transitioning = false

func _ready():
	# Update text based on the current language
	title_label.text = tr("WARNING_PHOTOSENSITIVITY_TITLE")
	
	# 경고문 조합: 광과민성 + 청력 보호 + 휴식 권장
	var warning_text = tr("WARNING_PHOTOSENSITIVITY_BODY")
	warning_text += "\n\n" + tr("WARNING_HEARING_PROTECTION")
	warning_text += "\n\n" + tr("WARNING_TAKE_BREAKS")
	body_label.text = warning_text
	
	continue_label.text = tr("UI_PRESS_ANY_KEY_OR_WAIT")

	# Set the timer to 7 seconds, one-shot (only runs once).
	timer.wait_time = 7.0
	timer.one_shot = true
	timer.start()

func _input(event):
	# Proceed to the next scene on any key press or screen touch
	if event.is_pressed():
		_change_scene()

func _on_timer_timeout():
	# This function is called when the Timer finishes.
	_change_scene()

func _change_scene():
	# This helper function ensures the scene is changed only once.
	if _is_transitioning:
		return
	_is_transitioning = true
	
	get_tree().change_scene_to_file("res://scenes/patcher/patcher_screen.tscn")
