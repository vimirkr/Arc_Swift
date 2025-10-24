extends Control

# This script simulates a patcher/loading screen and handles the logic
# for deciding whether to show the tutorial or the main menu.

# Preload the Label node for easy access.
@onready var status_label = $Label

func _ready():
	# In a real game, this is where you would: (여기서 파일/업데이 체크 할거임)
	# 1. Check file integrity.
	# 2. Connect to a server to check for new updates.
	# 3. Download and apply patches if needed.
	
	# For now, we'll just show a message and simulate a short delay. (근데 일단 서버 없으니 별 수 없음)
	status_label.text = "Checking for updates..."
	
	# Wait for 2 seconds to simulate the checking process.
	await get_tree().create_timer(2.0).timeout
	
	# After the "check", change the message to prompt the user.
	status_label.text = "Tap the screen to start"

func _input(event):
	# This function is called every time there is an input event.
	
	# We only proceed if the status label shows the "Tap to start" message.
	if status_label.text != "Tap the screen to start":
		return

	# Check if the input is a mouse click or a screen touch.
	if event is InputEventMouseButton and event.pressed or event is InputEventScreenTouch and event.pressed:
		# Now, the patcher's only job is to go to the main menu.
		# The tutorial logic will be handled later in the song_select scene.
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
