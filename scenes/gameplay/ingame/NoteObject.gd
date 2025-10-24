extends ColorRect

# [오류 수정]
# 이제 전역 class_name인 ParsedNote를 참조합니다.
var note_data: ParsedNote
var note_speed: float = 1000.0 # 초당 픽셀

var time_to_judge_line: float = 0.0
var current_note_time: float = 0.0

# [오류 수정]
# ingame.gd가 스폰할 때 호출할 초기화 함수
func init(data: ParsedNote, speed: float, judge_line_y: float):
	note_data = data
	note_speed = speed
	
	# Y 위치를 (0,0) 기준으로 계산하기 위해 판정선까지의 이동 시간을 계산
	time_to_judge_line = judge_line_y / note_speed
	
	# 노트의 색상이나 모양을 타입에 따라 변경 (추후 확장)
	# [오류 수정] 전역 ParsedNote의 내부 NoteType 열거형을 참조합니다.
	match note_data.note_type:
		ParsedNote.NoteType.TAP:
			color = Color.YELLOW
		ParsedNote.NoteType.LONG:
			color = Color.GREEN
		ParsedNote.NoteType.SWIPE:
			color = Color.CYAN


# ingame.gd로부터 현재 곡 시간을 받아 자신의 Y위치를 계산
func update_position(current_song_time_ms: float, judge_line_y: float):
	# 현재 시간과 노트의 목표 시간 사이의 차이 (밀리초)
	var time_diff_ms = note_data.time_ms - current_song_time_ms
	
	# 이 노트가 판정선에 도달하기까지 남은 시간 (초)
	var time_remaining_sec = time_diff_ms / 1000.0
	
	# 남은 시간과 속도를 곱하여 판정선으로부터의 Y거리 계산
	position.y = judge_line_y - (time_remaining_sec * note_speed)
	
	# (추후 구현) 화면을 벗어난 노트 처리 (Miss 판정)
	if time_diff_ms < -150.0: # 150ms가 지나면 Miss 처리하고 제거
		queue_free()
