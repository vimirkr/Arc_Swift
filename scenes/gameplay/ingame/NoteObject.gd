class_name NoteObject extends ColorRect

const VISUAL_MARGIN = 10.0
const CENTER_LINE_WIDTH = 4.0  # 겹노트 중앙선 두께

var note_data: Dictionary
var left_rail: Rail
var right_rail: Rail
var note_speed_pixels_per_sec: float
var game_gear_node: Control

var game_gear_transform_inv: Transform2D

# 겹노트 표시용 (같은 레인에 2개 노트가 겹칠 때)
var is_stacked_note: bool = false

# 스와이프 연결선 관련
var swipe_line: Line2D = null
var next_swipe_note: NoteObject = null  # 같은 그룹의 다음 노트

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


# 겹노트 설정 (같은 레인에 2개 노트)
func set_stacked(stacked: bool):
	is_stacked_note = stacked
	queue_redraw()  # _draw() 다시 호출


# 스와이프 연결선 생성 (다음 노트로 연결)
func setup_swipe_connection(next_note: NoteObject):
	if note_data.note_type != GlobalEnums.NoteType.SWIPE:
		return
	
	next_swipe_note = next_note
	
	# Line2D 생성
	swipe_line = Line2D.new()
	swipe_line.width = 3.0
	swipe_line.default_color = Color.CYAN
	swipe_line.z_index = -1  # 노트 뒤에 그리기
	add_child(swipe_line)


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
	
	# 노트의 "머리(head)" = 판정 대상 = 노트의 하단(bottom)
	# target_y는 노트의 top-left 기준이므로, 노트 높이를 빼서 하단이 판정선에 맞도록 조정
	var head_y = judge_y - (time_remaining_sec * note_speed_pixels_per_sec)
	var target_y = head_y - size.y  # 노트의 top = head_y - 노트 높이
	
	position.x = left_local.x + (VISUAL_MARGIN / 2.0)
	position.y = target_y
	
	# 롱노트의 경우: 꼬리(tail)가 판정선을 지나면 화면에서 제거
	# 일반 노트의 경우: 머리(head)가 판정선을 200px 이상 지나면 제거
	var note_bottom_y = target_y + size.y  # 노트의 하단(머리) 위치
	
	if note_bottom_y > (judge_y + 200.0):
		return true
	
	# 스와이프 연결선 업데이트
	_update_swipe_line()
	
	return false


# 스와이프 연결선 위치 업데이트
func _update_swipe_line():
	if swipe_line == null or next_swipe_note == null:
		return
	
	if not is_instance_valid(next_swipe_note):
		swipe_line.visible = false
		return
	
	# 이 노트의 중앙 상단
	var start_pos = Vector2(size.x / 2.0, 0)
	
	# 다음 노트의 중앙 하단 (이 노트 기준 로컬 좌표로 변환)
	var next_global = next_swipe_note.global_position + Vector2(next_swipe_note.size.x / 2.0, next_swipe_note.size.y)
	var my_global = global_position
	var end_pos = next_global - my_global
	
	swipe_line.clear_points()
	swipe_line.add_point(start_pos)
	swipe_line.add_point(end_pos)
	swipe_line.visible = true


# 겹노트 중앙선 그리기
func _draw():
	if is_stacked_note:
		# 노트 중앙에 검은 세로선 그리기
		var center_x = size.x / 2.0
		var half_width = CENTER_LINE_WIDTH / 2.0
		draw_rect(Rect2(center_x - half_width, 0, CENTER_LINE_WIDTH, size.y), Color.BLACK)


# LONG 노트 홀드 중 시각적 업데이트 (남은 시간에 따라 높이 감소)
func update_holding_visual(current_song_time_ms: float):
	if note_data.note_type != GlobalEnums.NoteType.LONG:
		return
	
	var note_end_time_ms = note_data.time_ms + note_data.duration_ms
	var remaining_time_ms = note_end_time_ms - current_song_time_ms
	
	# 남은 시간이 0 이하면 최소 높이로 설정
	if remaining_time_ms <= 0:
		size.y = 0.0
		return
	
	# 남은 시간에 따라 높이 재계산
	var remaining_sec = remaining_time_ms / 1000.0
	size.y = remaining_sec * note_speed_pixels_per_sec
	
	# 노트 하단(머리)이 판정선에 고정되도록 위치 조정
	var left_global = left_rail.global_position
	var left_local = game_gear_transform_inv * left_global
	var judge_y = left_rail.judge_y
	
	position.x = left_local.x + (VISUAL_MARGIN / 2.0)
	position.y = judge_y - size.y  # 머리가 판정선에 고정
	
	queue_redraw()  # 겹노트 선 다시 그리기
