extends Control

# This script handles keyboard scrolling and the back button functionality for the credits screen.

# The speed at which the content scrolls when using arrow keys.
@export var scroll_speed = 300.0

# Preload the ScrollContainer node for easy access.
@onready var scroll_container = $MarginContainer/ScrollContainer


func _process(delta):
	# This function runs on every frame.
	# We check for keyboard input here to create smooth scrolling.
	
	# Scroll down if the 'ui_down' action (Down Arrow Key) is pressed.
	if Input.is_action_pressed("ui_down"):
		scroll_container.scroll_vertical += scroll_speed * delta
	
	# Scroll up if the 'ui_up' action (Up Arrow Key) is pressed.
	if Input.is_action_pressed("ui_up"):
		scroll_container.scroll_vertical -= scroll_speed * delta


# This function will be connected to the back button's 'pressed' signal.
func _on_back_button_pressed():
	# Go back to the main menu.
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
