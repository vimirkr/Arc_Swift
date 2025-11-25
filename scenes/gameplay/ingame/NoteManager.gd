extends Node

# ParsedNote, NoteType, Lane은 이제 note_data.gd와 GlobalEnums로 정의됨
# 파싱된 노트들이 담길 배열
var parsed_note_list: Array[Dictionary] = []

var bpm: float = 100.0
var offset_ms: float = 0.0

# ingame.gd가 호출할 메인 파싱 함수
func parse_chart(chart_data: Dictionary):
	parsed_note_list.clear()

	# 신 포맷 감지: "metadata"와 "notes" 노드가 최상위에 있으면 신 포맷
	if chart_data.has("metadata") and chart_data.has("notes"):
		print("[NoteManager] 신 포맷 차트 감지, 신 파서 사용")
		_parse_new_format(chart_data)
		return

	# 레거시 Beatrice 포맷 파싱
	var charts = chart_data.get("charts", [])
	if charts.is_empty():
		printerr("[NoteManager] 'charts' 배열이 비어있거나 없습니다.")
		return

	print("[NoteManager] Beatrice 레거시 포맷 감지, 기존 파서 사용")
	# 첫 번째 차트만 사용 (Beatrice 기본 구조)
	var chart = charts[0]
	
	# 1. BPM 및 offset 추출
	bpm = chart_data.get("bpm", 100.0)
	offset_ms = chart_data.get("offset", 0.0)
	print("[NoteManager] BPM: %.1f, Offset: %.1f ms" % [bpm, offset_ms])

	# 2. notes와 links 추출
	var beatrice_notes = chart.get("notes", [])
	var beatrice_links = chart.get("links", [])
	
	# 3. 링크의 시작과 끝 노트들을 추적 (중복 생성 방지)
	var processed_uuids = {}

	# 4. 링크 처리 (롱노트 / 스와이프 노트)
	for link_data in beatrice_links:
		var start_note_data = link_data.startNote
		var end_note_data = link_data.endNote

		# 링크의 시작점과 끝점을 processed_uuids에 등록
		processed_uuids[start_note_data.uuid] = true
		processed_uuids[end_note_data.uuid] = true

		var start_lane_7 = _map_beatrice_lane_to_7(start_note_data.lane)
		var end_lane_7 = _map_beatrice_lane_to_7(end_note_data.lane)
		
		if start_lane_7 == end_lane_7:
			# 롱노트 (레인이 같음)
			_create_long_note(start_note_data, end_note_data, start_lane_7, link_data.get("tick_count", 2))
		else:
			# 스와이프 노트 (레인이 다름)
			_create_swipe_notes(start_note_data, end_note_data, start_lane_7, end_lane_7)

	# 5. 링크가 아닌 노트 처리 (단타 노트)
	for note_data in beatrice_notes:
		if not processed_uuids.has(note_data.uuid):
			_create_tap_note(note_data)
	
	# 6. 시간순 정렬 (CRITICAL: 동시치기 노트가 올바른 순서로 스폰되도록)
	parsed_note_list.sort_custom(func(a, b): return a.time_ms < b.time_ms)
	
	# (디버그) 파싱된 노트 수 출력
	print("[NoteManager] Chart parsing complete. Total notes generated: %d" % parsed_note_list.size())


# 단타 노트를 생성하고 리스트에 추가
func _create_tap_note(note_data):
	var note = {
		"time_ms": note_data.songPos + offset_ms,
		"lane": _map_beatrice_lane_to_7(note_data.lane),
		"note_type": GlobalEnums.NoteType.TAP,
		"duration_ms": 0.0,
		"tick_count": 0,
		"end_lane": _map_beatrice_lane_to_7(note_data.lane)
	}
	parsed_note_list.push_back(note)


# 롱노트를 생성하고 리스트에 추가
func _create_long_note(start_note_data, end_note_data, lane_7, tick_count):
	var note = {
		"time_ms": start_note_data.songPos + offset_ms,
		"lane": lane_7,
		"note_type": GlobalEnums.NoteType.LONG,
		"duration_ms": end_note_data.songPos - start_note_data.songPos,
		"tick_count": tick_count,
		"end_lane": lane_7
	}
	parsed_note_list.push_back(note)


# 스와이프 노트 (시작 + 중간 + 끝) 생성하고 리스트에 추가
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
		var err_note = {
			"time_ms": end_time_ms,
			"lane": end_lane_7,
			"note_type": GlobalEnums.NoteType.SWIPE,
			"duration_ms": time_diff_ms,
			"tick_count": 0,
			"end_lane": end_lane_7
		}
		parsed_note_list.push_back(err_note)
		return

	# 1번 이동에 걸리는 시간 (예: 200ms)
	var time_per_step = time_diff_ms / total_steps

	# 시작 노트와 중간 노트를 생성
	for i in range(total_steps):
		var note = {
			"time_ms": start_time_ms + (time_per_step * i),
			"lane": start_lane_7 + (step * i),
			"note_type": GlobalEnums.NoteType.SWIPE,
			"duration_ms": time_diff_ms,
			"tick_count": 0,
			"end_lane": end_lane_7
		}
		parsed_note_list.push_back(note)
	
	# 마지막 노트 생성
	var end_note = {
		"time_ms": end_time_ms,
		"lane": end_lane_7,
		"note_type": GlobalEnums.NoteType.SWIPE,
		"duration_ms": time_diff_ms,
		"tick_count": 0,
		"end_lane": end_lane_7
	}
	parsed_note_list.push_back(end_note)


# 신 포맷 파서 (metadata + notes 구조)
func _parse_new_format(chart_data: Dictionary):
	var notes = chart_data.get("notes", [])
	if notes.is_empty():
		printerr("[NoteManager] 신 포맷: 'notes' 배열이 비어있습니다.")
		return
	
	# active_lines 추적 (change 이벤트로 변경 가능)
	var active_lines = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]  # 기본값: 12개 레인
	
	for note in notes:
		var line = note.get("line", -1)
		var time = note.get("time", 0)
		var note_type = note.get("type", "")
		var duration = note.get("duration", 0)
		
		# Event lane (N+5, 여기서는 17번 레인) 처리: 게임플레이에 영향 주지만 표시 안함
		if line >= 17:
			# TODO: BPM/속도 변경 이벤트 처리
			continue
		
		# Temporary lanes (N ~ N+4, 여기서는 12-16번 레인) 처리: 차트 효율성, 표시 안함
		if line >= 12:
			continue
		
		# change 타입: active_lines 변경
		if note_type == "change":
			var new_active_lines = note.get("active_lines", [])
			if not new_active_lines.is_empty():
				active_lines = new_active_lines.duplicate()
			continue
		
		# 일반 노트 처리: active_lines에 있는 레인만 표시
		if line < 0 or line >= active_lines.size():
			continue
		
		# 레인 번호를 7-lane enum으로 매핑
		var lane_enum = _map_new_format_lane_to_7(line, active_lines)
		if lane_enum == -1:
			continue
		
		var parsed_note = {
			"time_ms": float(time),
			"lane": lane_enum,
			"duration_ms": float(duration),
			"tick_count": 0,
			"end_lane": lane_enum
		}
		
		# 노트 타입 매핑
		match note_type:
			"tap":
				parsed_note["note_type"] = GlobalEnums.NoteType.TAP
			"hold":
				parsed_note["note_type"] = GlobalEnums.NoteType.LONG
				parsed_note["tick_count"] = max(1, int(duration / 500.0))  # 0.5초마다 틱
			"swift":  # 오타 수정 필요
				parsed_note["note_type"] = GlobalEnums.NoteType.SWIPE
			_:
				printerr("[NoteManager] 알 수 없는 노트 타입: ", note_type)
				continue
		
		parsed_note_list.push_back(parsed_note)
	
	# 시간순 정렬 (CRITICAL: 동시치기 노트가 올바른 순서로 스폰되도록)
	parsed_note_list.sort_custom(func(a, b): return a.time_ms < b.time_ms)


# 신 포맷 레인 번호를 7-lane enum으로 매핑
# 규칙: 가장 낮은 번호 = SIDE_L, 가장 높은 번호 = SIDE_R, 나머지는 2개씩 묶어서 MID_1~5
func _map_new_format_lane_to_7(line: int, active_lines: Array) -> int:
	var active_count = active_lines.size()
	
	if active_count < 2:
		printerr("[NoteManager] active_lines가 2개 미만입니다")
		return -1
	
	# 정렬된 active_lines 생성
	var sorted_lines = active_lines.duplicate()
	sorted_lines.sort()
	
	# line이 active_lines에 있는지 확인
	var line_index = sorted_lines.find(line)
	if line_index == -1:
		return -1
	
	# 가장 왼쪽 (가장 낮은 번호)
	if line_index == 0:
		return GlobalEnums.Lane.SIDE_L
	
	# 가장 오른쪽 (가장 높은 번호)
	if line_index == active_count - 1:
		return GlobalEnums.Lane.SIDE_R
	
	# 중간 레인: 2개씩 묶어서 MID_1~5로 매핑
	# 예: 12개 레인 시 lane 0(SIDE_L), lanes 1-2(MID_1), 3-4(MID_2), ..., lane 11(SIDE_R)
	var center_index = line_index - 1  # SIDE_L 제외
	var pair_index = center_index / 2
	
	match pair_index:
		0: return GlobalEnums.Lane.MID_1
		1: return GlobalEnums.Lane.MID_2
		2: return GlobalEnums.Lane.MID_3
		3: return GlobalEnums.Lane.MID_4
		4: return GlobalEnums.Lane.MID_5
		_:
			printerr("[NoteManager] 중간 레인 매핑 실패: pair_index = ", pair_index)
			return -1


# Beatrice 12-line -> 7-Lane 매핑 (기획서 참조)
# [FIX] 반환 타입을 int로 변경하여 실패 시 -1 반환
func _map_beatrice_lane_to_7(beatrice_lane: int) -> int:
	match beatrice_lane:
		1:  return GlobalEnums.Lane.SIDE_L
		2, 3: return GlobalEnums.Lane.MID_1
		4, 5: return GlobalEnums.Lane.MID_2
		6, 7: return GlobalEnums.Lane.MID_3
		8, 9: return GlobalEnums.Lane.MID_4
		10, 11: return GlobalEnums.Lane.MID_5
		12: return GlobalEnums.Lane.SIDE_R
		_:
			printerr("[NoteManager] 알 수 없는 beatrice_lane 값입니다: %d" % beatrice_lane)
			return -1  # 실패 시 -1 반환
