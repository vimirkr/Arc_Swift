class_name NoteObject extends ColorRect

const VISUAL_MARGIN = 10.0

var note_data: Dictionary
var left_rail: Rail
var right_rail: Rail
var note_speed_pixels_per_sec: float
var game_gear_node: Control

var game_gear_transform_inv: Transform2D

func init(data: Dictionary, l_rail: Rail, r_rail: Rail, speed: float, gear: Control):
	note_data = data
	left_rail = l_rail
	right_rail = r_rail
	note_speed_pixels_per_sec = speed
	game_gear_node = gear
	
	game_gear_transform_inv = game_gear_node.get_global_transform_with_canvas().affine_inverse()
	
	# 노트 색상 설정
	match note_data.note_type:
		GlobalEnums.NoteType.TAP:
			color = Color.YELLOW
		GlobalEnums.NoteType.LONG:
			color = Color.GREEN
		GlobalEnums.NoteType.SWIPE:
			color = Color.CYAN
	
	_update_visual_properties()

func _update_visual_properties():
	var left_global = left_rail.global_position
	var right_global = right_rail.global_position
	
	var left_local = game_gear_transform_inv * left_global
	var right_local = game_gear_transform_inv * right_global
	
	var note_width = right_local.x - left_local.x - VISUAL_MARGIN
	size.x = note_width
	
	if note_data.note_type == GlobalEnums.NoteType.LONG:
		var duration_sec = note_data.duration_ms / 1000.0
		size.y = duration_sec * note_speed_pixels_per_sec
	else:
		size.y = 30.0

func update_position(current_song_time_ms: float) -> bool:
	var time_diff_ms = note_data.time_ms - current_song_time_ms
	var time_remaining_sec = time_diff_ms / 1000.0
	
	var left_global = left_rail.global_position
	var left_local = game_gear_transform_inv * left_global
	
	var judge_y = left_rail.judge_y
	var target_y = judge_y - (time_remaining_sec * note_speed_pixels_per_sec)
	
	position.x = left_local.x + (VISUAL_MARGIN / 2.0)
	position.y = target_y
	
	if target_y > (judge_y + 200.0):
		return true
	
	return false
