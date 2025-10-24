extends Node

# ParsedNote, NoteType, Lane은 이제 note_data.gd에 전역으로 정의됨

# 파싱된 노트들이 저장될 배열
var parsed_note_list: Array[ParsedNote] = []

var bpm: float = 100.0
var offset_ms: float = 0.0

# ingame.gd가 호출할 메인 파싱 함수
func parse_chart(chart_data: Dictionary):
	parsed_note_list.clear()

	# 1. 기본 정보 로드
	bpm = chart_data.get("bpm", 100.0)
	offset_ms = chart_data.get("offset", 0.0)
	
	var chart = chart_data.charts[0]
	var beatrice_notes = chart.notes
	var beatrice_links = chart.links

	# 2. 빠른 조회를 위해 노트를 UUID 맵에 저장
	var uuid_to_note_map = {}
	for note_data in beatrice_notes:
		uuid_to_note_map[note_data.uuid] = note_data

	# 3. 링크의 일부가 된 노트들을 추적 (중복 생성 방지)
	var processed_uuids = {}

	# 4. 링크 처리 (롱노트 / 스와이프 노트)
	for link_data in beatrice_links:
		var start_note_data = link_data.startNote
		var end_note_data = link_data.endNote

		# 링크의 시작점과 끝점을 processed_uuids에 등록
		processed_uuids[start_note_data.uuid] = true
		processed_uuids[end_note_data.uuid] = true

		var start_lane_7 = _map_lane(start_note_data.lane)
		var end_lane_7 = _map_lane(end_note_data.lane)
		
		if start_lane_7 == end_lane_7:
			# 롱노트 (레인이 같음)
			_create_long_note(start_note_data, end_note_data, start_lane_7, link_data.get("tick_count", 2))
		else:
			# 스와이프 노트 (레인이 다름)
			_create_swipe_notes(start_note_data, end_note_data, start_lane_7, end_lane_7)

	# 5. 링크되지 않은 노트 처리 (단타 노트)
	for note_data in beatrice_notes:
		if not processed_uuids.has(note_data.uuid):
			_create_tap_note(note_data)
	
	# (디버그) 파싱된 노트 수 출력
	print("[NoteManager] Chart parsing complete. Total notes generated: %d" % parsed_note_list.size())


# 단타 노트를 생성하고 리스트에 추가
func _create_tap_note(note_data):
	var note = ParsedNote.new() # 전역 클래스 ParsedNote 사용
	note.time_ms = note_data.songPos + offset_ms
	note.lane = _map_lane(note_data.lane)
	note.note_type = ParsedNote.NoteType.TAP # [수정] 전역 열거형 참조
	parsed_note_list.push_back(note)


# 롱노트를 생성하고 리스트에 추가
func _create_long_note(start_note_data, end_note_data, lane_7, tick_count):
	var note = ParsedNote.new()
	note.time_ms = start_note_data.songPos + offset_ms
	note.lane = lane_7
	note.note_type = ParsedNote.NoteType.LONG # [수정] 전역 열거형 참조
	note.duration_ms = end_note_data.songPos - start_note_data.songPos
	note.tick_count = tick_count
	parsed_note_list.push_back(note)


# 스와이프 노트 (시작 + 중간 + 끝)를 생성하고 리스트에 추가
func _create_swipe_notes(start_note_data, end_note_data, start_lane_7, end_lane_7):
	var start_time_ms = start_note_data.songPos + offset_ms
	var end_time_ms = end_note_data.songPos + offset_ms
	
	var lane_diff = end_lane_7 - start_lane_7
	var time_diff_ms = end_time_ms - start_time_ms
	
	# 레인 이동 방향 (1 또는 -1)
	var step = 1 if lane_diff > 0 else -1
	# 총 이동할 레인 수 (예: 3)
	var total_steps = abs(lane_diff)
	
	# 스텝이 0이면(버그 방지), 바로 끝 노트만 생성
	if total_steps == 0:
		var err_note = ParsedNote.new()
		err_note.time_ms = end_time_ms
		err_note.lane = end_lane_7
		err_note.note_type = ParsedNote.NoteType.SWIPE
		err_note.duration_ms = time_diff_ms
		err_note.end_lane = end_lane_7
		parsed_note_list.push_back(err_note)
		return

	# 1칸 이동당 걸리는 시간 (예: 200ms)
	var time_per_step = time_diff_ms / total_steps

	# 시작 노트와 중간 노트들 생성
	for i in range(total_steps):
		var note = ParsedNote.new()
		note.time_ms = start_time_ms + (time_per_step * i)
		note.lane = start_lane_7 + (step * i)
		note.note_type = ParsedNote.NoteType.SWIPE
		
		# 스와이프 뭉치를 식별하기 위해 추가 정보 저장
		note.duration_ms = time_diff_ms # 뭉치의 총 시간
		note.end_lane = end_lane_7       # 뭉치의 최종 목적지
		
		parsed_note_list.push_back(note)
	
	# 마지막 노트 생성
	var end_note = ParsedNote.new()
	end_note.time_ms = end_time_ms
	end_note.lane = end_lane_7
	end_note.note_type = ParsedNote.NoteType.SWIPE
	end_note.duration_ms = time_diff_ms
	end_note.end_lane = end_lane_7
	parsed_note_list.push_back(end_note)


# Beatrice 12-line을 7-lane으로 매핑
func _map_lane(beatrice_lane: int) -> ParsedNote.Lane: # [수정] 반환 타입
	match beatrice_lane:
		1:  return ParsedNote.Lane.SIDE_L
		2, 3: return ParsedNote.Lane.MID_1
		4, 5: return ParsedNote.Lane.MID_2
		6, 7: return ParsedNote.Lane.MID_3
		8, 9: return ParsedNote.Lane.MID_4
		10, 11: return ParsedNote.Lane.MID_5
		12: return ParsedNote.Lane.SIDE_R
		_:
			printerr("Unknown beatrice lane: %d" % beatrice_lane)
			return ParsedNote.Lane.MID_3 # 기본값
