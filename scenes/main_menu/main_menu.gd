extends Control

# This script handles the main menu's button interactions.
# Each function will be connected to the 'pressed' signal of its corresponding button.

@onready var select_music_button = $VBoxContainer/SelectMusic_Button
@onready var profile_button = $VBoxContainer/Profile_Button
@onready var option_button = $VBoxContainer/Option_Button
@onready var credits_button = $VBoxContainer/Credits_Button

func _ready():
	# 버튼 텍스트 현지화
	select_music_button.text = tr("UI_SELECT_MUSIC")
	profile_button.text = tr("UI_PROFILE")
	option_button.text = tr("UI_OPTION")
	credits_button.text = tr("UI_CREDITS")

# Called when the SelectMusic_Button is pressed.
func _on_select_music_button_pressed():
	# Transitions to the song selection screen using the new path.
	get_tree().change_scene_to_file("res://scenes/gameplay/select_song/select_song.tscn")


# Called when the Profile_Button is pressed.
func _on_profile_button_pressed():
	# Transitions to the user profile (statistics) screen using the new path.
	get_tree().change_scene_to_file("res://scenes/ui/user_profile/user_profile.tscn")


# Called when the Option_Button is pressed.
func _on_option_button_pressed():
	# Transitions to the options screen using the new path.
	get_tree().change_scene_to_file("res://scenes/ui/option/option.tscn")


# Called when the Credits_Button is pressed.
func _on_credits_button_pressed():
	# Transitions to the credits screen using the new path.
	get_tree().change_scene_to_file("res://scenes/ui/credits/credits.tscn")
