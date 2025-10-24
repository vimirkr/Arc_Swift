extends Control

@onready var timer = $Timer

func _ready():
	timer.start()

func _on_timer_timeout():
	# CORRECTED: Change the destination to the new warning screen.
	get_tree().change_scene_to_file("res://scenes/boot/warning_screen.tscn")
