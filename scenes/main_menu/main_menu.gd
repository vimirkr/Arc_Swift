extends Control

# This script handles the main menu's button interactions.
# Each function will be connected to the 'pressed' signal of its corresponding button.


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
