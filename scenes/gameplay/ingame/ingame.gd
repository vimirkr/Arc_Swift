extends Control

# -- 노드 레퍼런스 --
@onready var loading_screen = $LoadingScreen
@onready var gameplay_ui = $GameplayUI
@onready var pause_menu = $PauseMenu
@onready var pause_popup = $PausePopup
@onready var note_manager = $NoteManager
@onready var music_player = $MusicPlayer
@onready var loading_timer = $Timers/LoadingTimer
@onready var start_delay_timer = $Timers/StartDelayTimer
@onready var result_timer = $Timers/ResultTimer
@onready var judgement_label = $GameplayUI/JudgementLabel # (임시) 판정 표시용 레이블
var center_display_label: Label = null  # 중앙 정보 표시 라벨 (동적 생성)

# -- 게임 상태 --
enum GameState { LOADING, READY, COUNTDOWN, PLAYING, PAUSED, SHOW_RESULT, TRANSITIONING }
var current_state = GameState.LOADING

# -- 게임 설정 변수 --
@export var note_speed_pixels_per_sec: float = 1000.0 # 노트 낙하 속도 (기본값, UserSettings.scroll_speed로 덮어씀)

# -- 판정 타이밍 (밀리초) --
const PERFECT_MS = 30
const GREAT_MS = 60
const GOOD_MS = 100
const MISS_MS = 100 # GOOD 범위를 벗어나면 즉시 Miss

# -- 스와이프 후속 노트 판정 타이밍 (더 널널한 판정) --
const SWIPE_PERFECT_MS = 75
const SWIPE_GREAT_MS = 100
const SWIPE_GOOD_MS = 125

# -- 입력 버퍼 시스템 --
var input_buffer: Array[Dictionary] = [] # 입력 이벤트 버퍼
const INPUT_BUFFER_TIME_MS = 50.0 # 입력을 버퍼에 유지하는 시간

# -- 노트 관리 변수 --
var note_spawn_index: int = 0
var current_song_time_ms: float = 0.0
var active_notes_by_lane: Array = [] # Array[Array[NoteObject]]
var notes_to_remove: Array[NoteObject] = [] 
var game_gear_node: Control 

# -- 게임 데이터 변수 --
var selected_song_data: Dictionary
var selected_difficulty_data: Dictionary
var chart_data: Dictionary 

# -- 노트 스폰/관리용 변수 --
var parsed_note_list: Array[Dictionary] = [] 
var note_object_scene = preload("res://scenes/gameplay/ingame/NoteObject.tscn")
var rails: Array[Rail] = []

# -- LONG 노트 홀드 상태 추적 --
# 각 레인별로 현재 홀드 중인 LONG 노트를 추적 (lane_index -> NoteObject)
var holding_long_notes: Dictionary = {}

# -- 스와이프 노트 연결 관리 --
# 스와이프 그룹별 스폰된 노트 목록 (group_id -> Array[NoteObject])
var spawned_swipe_notes_by_group: Dictionary = {}

# -- 판정 통계 변수 --
var current_combo: int = 0
var total_score_points: float = 0.0  # 누적 점수 (100% 판정 = 1점)
var total_notes_count: int = 0  # 전체 노트 개수
var processed_notes_count: int = 0  # 처리된 노트 개수

# 판정별 카운트 (Ultimate/Perfect/Great/Good/Miss)
var judgement_counts: Dictionary = {
	"ultimate": 0,
	"perfect": 0,
	"great": 0,
	"good": 0,
	"miss": 0
}

# Fast/Slow 카운트
var fast_count: int = 0
var slow_count: int = 0

# -- 게임 종료 관련 변수 --
var all_notes_processed: bool = false  # 모든 노트 처리 완료 플래그
var time_since_last_note: float = 0.0  # 마지막 노트 이후 경과 시간 (초)
var fadeout_started: bool = false  # 페이드아웃 시작 여부
const END_DELAY_TIME: float = 3.0  # 마지막 노트 후 대기 시간 (초)
const FADEOUT_START_TIME: float = 2.0  # 페이드아웃 시작 시간 (초)
const FADEOUT_DURATION: float = 1.0  # 페이드아웃 지속 시간 (초)

# GameGear의 역변환 행렬을 저장할 변수
var game_gear_transform_inv: Transform2D

# -- 일시정지 관련 변수 --
var input_block_time_ms: float = 0.0  # 입력 차단 시간 (밀리초)
const RESUME_INPUT_BLOCK_MS: float = 50.0  # Resume 후 입력 차단 시간

#region Godot Lifecycle Functions
#------------------------------------

func _ready():
	pause_menu.hide()
	gameplay_ui.hide()
	loading_screen.show() 
	
	# JudgementLabel이 씬에 정의되어 있으므로 추가 설정만 진행
	if judgement_label:
		# 해상도 독립적인 중앙 배치 확인
		judgement_label.set_anchors_preset(Control.PRESET_CENTER)
		judgement_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		judgement_label.grow_vertical = Control.GROW_DIRECTION_BOTH
		judgement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		judgement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# 뷰포트 크기 기준으로 크기 설정
		var viewport_size = get_viewport_rect().size
		judgement_label.custom_minimum_size = Vector2(400, 100)
		judgement_label.offset_left = -200
		judgement_label.offset_top = -50
		judgement_label.offset_right = 200
		judgement_label.offset_bottom = 50
		judgement_label.text = ""  # 초기에는 비움
	
	# Center Display Label 생성 (JudgementLabel 위쪽)
	center_display_label = Label.new()
	center_display_label.set_anchors_preset(Control.PRESET_CENTER)
	center_display_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_display_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	center_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 뷰포트 크기 기준으로 크기 설정 (JudgementLabel보다 작게)
	var viewport_size = get_viewport_rect().size
	var label_width = viewport_size.x * 0.3  # 화면 너비의 30%
	var label_height = 60.0
	center_display_label.custom_minimum_size = Vector2(label_width, label_height)
	center_display_label.offset_left = -label_width / 2.0
	center_display_label.offset_top = -150.0  # JudgementLabel 위쪽에 배치
	center_display_label.offset_right = label_width / 2.0
	center_display_label.offset_bottom = -150.0 + label_height
	
	# 폰트 크기 설정
	center_display_label.add_theme_font_size_override("font_size", 32)
	center_display_label.text = ""
	
	# GameplayUI에 추가
	if is_instance_valid(gameplay_ui):
		gameplay_ui.add_child(center_display_label)
	
	# 일시정지 팝업 시그널 연결
	if pause_popup:
		if not pause_popup.resume_requested.is_connected(_on_pause_resume):
			pause_popup.resume_requested.connect(_on_pause_resume)
		if not pause_popup.restart_requested.is_connected(_on_pause_restart):
			pause_popup.restart_requested.connect(_on_pause_restart)
		if not pause_popup.select_music_requested.is_connected(_on_pause_select_music):
			pause_popup.select_music_requested.connect(_on_pause_select_music)
		pause_popup.hide()
	
	# 타이머 시그널 연결
	if loading_timer and not loading_timer.timeout.is_connected(_start_loading_process):
		loading_timer.timeout.connect(_start_loading_process)
	if start_delay_timer and not start_delay_timer.timeout.is_connected(_on_start_delay_timer_timeout):
		start_delay_timer.timeout.connect(_on_start_delay_timer_timeout)
	
	# 로딩 타이머 시작 (1초 후 로딩 시작)
	loading_timer.wait_time = 1.0
	loading_timer.one_shot = true
	loading_timer.start()


func _unhandled_input(event):
	# ESC 키로 일시정지
	if event.is_action_pressed("ui_cancel", true):  # ESC key
		if current_state == GameState.PLAYING:
			_pause_game()
		elif current_state == GameState.PAUSED:
			_on_pause_resume()
		return
	
	# F5 키로 재시작 (플레이 중 또는 일시정지 중에 가능)
	if event.is_action_pressed("ui_text_submit", true):  # F5
		if current_state == GameState.PLAYING or current_state == GameState.PAUSED:
			_restart_game()
		return
	
	# 게임 플레이 중일 때만 입력 처리
	if current_state != GameState.PLAYING:
		return
	
	# 입력 차단 시간 동안 입력 무시
	if input_block_time_ms > 0.0:
		return
	
	# 7개 레인에 대한 입력 처리 (if문 사용으로 동시 입력 가능)
	if event.is_action_pressed("lane_1", true):  # Z key - SIDE_L
		input_buffer.append({"lane": GlobalEnums.Lane.SIDE_L, "time_ms": current_song_time_ms})
	if event.is_action_pressed("lane_2", true):  # S key - MID_1
		input_buffer.append({"lane": GlobalEnums.Lane.MID_1, "time_ms": current_song_time_ms})
	if event.is_action_pressed("lane_3", true):  # D key - MID_2
		input_buffer.append({"lane": GlobalEnums.Lane.MID_2, "time_ms": current_song_time_ms})
	if event.is_action_pressed("lane_4", true):  # SPACE - MID_3
		input_buffer.append({"lane": GlobalEnums.Lane.MID_3, "time_ms": current_song_time_ms})
	if event.is_action_pressed("lane_5", true):  # J key - MID_4
		input_buffer.append({"lane": GlobalEnums.Lane.MID_4, "time_ms": current_song_time_ms})
	if event.is_action_pressed("lane_6", true):  # K key - MID_5
		input_buffer.append({"lane": GlobalEnums.Lane.MID_5, "time_ms": current_song_time_ms})
	if event.is_action_pressed("lane_7", true):  # M key - SIDE_R
		input_buffer.append({"lane": GlobalEnums.Lane.SIDE_R, "time_ms": current_song_time_ms})


func _process(delta):
	# 입력 블록 타이머 처리
	if input_block_time_ms > 0.0:
		input_block_time_ms -= delta * 1000.0
		if input_block_time_ms < 0.0:
			input_block_time_ms = 0.0
	
	match current_state:
		GameState.PLAYING:
			_process_input_buffer() # 버퍼된 입력 처리
			_process_held_keys_for_swipe() # 스와이프용 키 홀드 체크
			_process_holding_long_notes() # LONG 노트 홀드 상태 체크
			_update_gameplay(delta)
			_update_center_display()  # Center Display 업데이트
			_check_song_end()  # 곡 종료 확인
			
			# 모든 노트 처리 후 타이머 증가
			if all_notes_processed:
				time_since_last_note += delta
		GameState.READY:
			# READY 상태에서도 시간을 진행하고 노트를 업데이트 (음수 시간에서 0으로)
			current_song_time_ms += delta * 1000.0
			_update_gameplay(delta)
		_:
			pass 


#endregion

#region Loading and Initialization
#------------------------------------

func _start_loading_process():
	print("데이터 로딩 시작...")
	
	_clear_all_notes() 
	for i in 7: 
		active_notes_by_lane.append([]) 
	
	if GameplayData.selected_song_data == null or GameplayData.selected_difficulty_data == null:
		print("[WARNING] GameplayData is empty. Using DEBUG data.")
		if not _load_debug_data(): 
			printerr("[ERROR] Failed to load debug data.")
			return
	
	if not _load_data_from_globals(): return
	if not _load_chart_data(): return

	game_gear_node = gameplay_ui.get_node_or_null("GameGear")
	if game_gear_node == null:
		printerr("[CRITICAL] GameGear를 찾을 수 없습니다!")
		return
	
	# Rails 배열 초기화
	rails.clear()
	var rail_container = game_gear_node.get_node_or_null("RailContainer")
	if rail_container:
		for i in range(8):  # Rail_0부터 Rail_7까지
			var rail_node = rail_container.get_node_or_null("Rail_%d" % i)
			if rail_node:
				rails.append(rail_node)
			else:
				printerr("[ERROR] Rail_%d를 찾을 수 없습니다!" % i)
	
	if rails.size() < 8:
		printerr("[ERROR] 레일이 충분하지 않습니다. 필요: 8개, 현재: %d개" % rails.size())
		return
	
	# GameGear의 역변환 행렬을 캐싱
	game_gear_transform_inv = game_gear_node.get_global_transform_with_canvas().affine_inverse()
	
	# NoteManager에 차트 파싱 요청
	note_manager.parse_chart(chart_data)
	parsed_note_list = note_manager.parsed_note_list
	
	if parsed_note_list.is_empty():
		printerr("[ERROR] 파싱된 노트가 없습니다!")
		return
	
	print("[INFO] 총 %d개의 노트가 파싱되었습니다." % parsed_note_list.size())
	
	# READY 상태로 전환
	_transition_to_ready()


func _load_debug_data() -> bool:
	# 디버그용 기본 데이터 로드
	var debug_song_path = "res://song/Original/example_no_commercial"
	var debug_chart_path = debug_song_path + "/Chart/example_no_commercial_Chart_Easy.json"
	
	if not FileAccess.file_exists(debug_chart_path):
		printerr("[ERROR] 디버그 차트 파일을 찾을 수 없습니다: ", debug_chart_path)
		return false
	
	selected_song_data = {
		"title": "Debug Song",
		"artist": "Debug Artist",
		"audio_path": debug_song_path + "/example_no_commercial.ogg"
	}
	
	selected_difficulty_data = {
		"path": debug_chart_path
	}
	
	print("[DEBUG] 디버그 데이터 로드 완료")
	return true


func _load_data_from_globals() -> bool:
	if GameplayData.selected_song_data != null:
		selected_song_data = GameplayData.selected_song_data
	if GameplayData.selected_difficulty_data != null:
		selected_difficulty_data = GameplayData.selected_difficulty_data
	
	if selected_song_data.is_empty() or selected_difficulty_data.is_empty():
		printerr("[ERROR] 선택된 곡 데이터가 비어있습니다.")
		return false
	
	print("[INFO] 곡 정보: ", selected_song_data.get("title", "Unknown"))
	return true


func _load_chart_data() -> bool:
	var chart_path = selected_difficulty_data.get("path", "")
	if chart_path.is_empty():
		printerr("[ERROR] 차트 경로가 지정되지 않았습니다.")
		return false
	
	if not FileAccess.file_exists(chart_path):
		printerr("[ERROR] 차트 파일을 찾을 수 없습니다: ", chart_path)
		return false
	
	var file = FileAccess.open(chart_path, FileAccess.READ)
	if file == null:
		printerr("[ERROR] 차트 파일을 열 수 없습니다: ", chart_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		printerr("[ERROR] JSON 파싱 실패: ", json.get_error_message())
		return false
	
	chart_data = json.get_data()
	print("[INFO] 차트 데이터 로드 완료")
	return true


func _transition_to_ready():
	print("로딩 완료. READY 상태로 전환합니다.")
	loading_screen.hide()
	gameplay_ui.show()
	current_state = GameState.READY
	
	# 3초 대기 시간을 음수로 설정 (노래 시작 = 0ms)
	current_song_time_ms = -3000.0  # -3초에서 시작
	note_spawn_index = 0
	
	# 판정 통계 초기화
	current_combo = 0
	total_score_points = 0.0
	processed_notes_count = 0
	total_notes_count = parsed_note_list.size()  # 전체 노트 개수 설정
	
	# 판정별 카운트 초기화
	judgement_counts["ultimate"] = 0
	judgement_counts["perfect"] = 0
	judgement_counts["great"] = 0
	judgement_counts["good"] = 0
	judgement_counts["miss"] = 0
	
	# Fast/Slow 카운트 초기화
	fast_count = 0
	slow_count = 0
	
	# 게임 종료 관련 변수 초기화
	all_notes_processed = false
	time_since_last_note = 0.0
	fadeout_started = false

	var audio_path = selected_song_data.get("audio_path")
	if audio_path and FileAccess.file_exists(audio_path):
		music_player.stream = load(audio_path)
	else:
		printerr("[ERROR] 음악 파일을 찾을 수 없습니다: ", audio_path)

	# 스크롤 속도를 READY 상태에서 미리 설정
	var visible_time_range_ms = UserSettings.get_visible_time_range_ms()
	var viewport_height = get_viewport_rect().size.y
	var distance = viewport_height - 200  # judge_y 위치
	note_speed_pixels_per_sec = (distance / visible_time_range_ms) * 1000.0
	print("[INFO] Scroll Speed: %.1f, Note Speed: %.1f px/s" % [UserSettings.scroll_speed, note_speed_pixels_per_sec])

	_update_gameplay(0.0) 

	# 기존 타이머 중지 후 재시작 (중복 방지)
	start_delay_timer.stop()
	start_delay_timer.wait_time = 3.0  # 3초로 변경
	start_delay_timer.one_shot = true
	start_delay_timer.start()


func _on_start_delay_timer_timeout():
	_start_game()


# 실제 게임 플레이를 시작합니다.
func _start_game():
	print("게임 시작! (0ms 시작)")
	current_state = GameState.PLAYING
	
	# current_song_time_ms는 이미 0에 가까워졌으므로 그대로 유지
	# 음악 재생 시작
	if music_player.stream:
		music_player.play()
		print("[INFO] 음악 재생 시작")
	else:
		printerr("[WARNING] 음악 스트림이 없습니다!")

#endregion

#region Gameplay Loop
#------------------------------------

func _update_gameplay(delta: float):
	# ---
	# 1. 시간 업데이트 (READY에서도 작동)
	# ---
	if current_state == GameState.READY:
		# READY 상태: current_song_time_ms가 -3000 -> 0으로 증가
		# 0이 되면 _start_game이 호출됨
		pass  # _process에서 이미 증가시킴
	
	elif current_state == GameState.PLAYING:
		# PLAYING 상태: 음악 재생 위치와 동기화
		if music_player.playing:
			current_song_time_ms = music_player.get_playback_position() * 1000.0
		else:
			# 음악이 멈췄지만 게임은 계속 (마지막 노트 처리 대기)
			current_song_time_ms += delta * 1000.0
	
	# ---
	# 노트 스폰 (READY와 PLAYING 모두에서 작동)
	# ---
	while note_spawn_index < parsed_note_list.size():
		var note_data = parsed_note_list[note_spawn_index]
		var spawn_time = note_data.time_ms
		var look_ahead_time = UserSettings.get_visible_time_range_ms()
		
		if current_song_time_ms >= (spawn_time - look_ahead_time):
			_spawn_note_object(note_data)
			note_spawn_index += 1
		else:
			break
	
	# ---
	# 2. 활성 노트 업데이트
	# ---
	notes_to_remove.clear() 
	
	for lane_array in active_notes_by_lane:
		for note_obj in lane_array:
			if is_instance_valid(note_obj):
				# 홀드 중인 LONG 노트는 별도 처리되므로 건너뜀
				if note_obj.note_data.get("is_holding", false):
					continue
				
				var wants_to_die = note_obj.update_position(current_song_time_ms)
				
				if current_state == GameState.PLAYING:
					if wants_to_die:
						if not notes_to_remove.has(note_obj): 
							notes_to_remove.append(note_obj)
							_show_judgement("Miss (Off-screen)")
							_on_miss()  # Miss 처리
						continue 
					
					var time_diff = note_obj.note_data.time_ms - current_song_time_ms
					
					# 노트 타입에 따른 Miss 판정 시점 결정
					var miss_threshold = MISS_MS
					if note_obj.note_data.note_type == GlobalEnums.NoteType.SWIPE:
						var is_head = note_obj.note_data.get("is_swipe_head", false)
						miss_threshold = MISS_MS if is_head else SWIPE_GOOD_MS
					
					if time_diff < -miss_threshold: 
						if not notes_to_remove.has(note_obj): 
							notes_to_remove.append(note_obj)
							_show_judgement("Miss (Late)")
							_on_miss()  # Miss 처리 
			else:
				if not notes_to_remove.has(note_obj):
					notes_to_remove.append(note_obj) 

	# ---
	# 3. 순회가 끝난 후 안전하게 노트 제거
	# ---
	if not notes_to_remove.is_empty():
		for note_to_remove in notes_to_remove:
			if is_instance_valid(note_to_remove):
				var lane_index = note_to_remove.note_data.lane
				active_notes_by_lane[lane_index].erase(note_to_remove) 
				note_to_remove.queue_free()
			else:
				for lane_array in active_notes_by_lane:
					if lane_array.has(note_to_remove):
						lane_array.erase(note_to_remove)
						break


func _spawn_note_object(note_data: Dictionary):
	var lane_index = note_data.lane # 0~6
	
	if lane_index < 0 or (lane_index + 1) >= rails.size():
		printerr("[ERROR] 유효하지 않은 레인 인덱스이거나 레일이 부족합니다: ", lane_index)
		return

	var left_rail: Rail = rails[lane_index]
	var right_rail: Rail = rails[lane_index + 1]
	
	var note_obj = note_object_scene.instantiate()
	note_obj.init(note_data, left_rail, right_rail, note_speed_pixels_per_sec, game_gear_node)
	
	game_gear_node.add_child(note_obj)
	active_notes_by_lane[lane_index].push_back(note_obj)
	
	# 겹노트 감지: 같은 레인, 같은 시간에 이미 노트가 있으면 겹노트로 표시
	_check_and_mark_stacked_notes(lane_index, note_obj)
	
	# 스와이프 노트: 같은 그룹의 이전 노트와 연결
	if note_data.note_type == GlobalEnums.NoteType.SWIPE:
		_setup_swipe_connection(note_obj)


# 겹노트 감지 및 표시
func _check_and_mark_stacked_notes(lane_index: int, new_note: NoteObject):
	var lane_array: Array = active_notes_by_lane[lane_index]
	var new_time = new_note.note_data.time_ms
	
	# 같은 레인의 다른 노트들과 시간 비교 (±50ms 이내면 겹노트)
	for existing_note in lane_array:
		if existing_note == new_note:
			continue
		if not is_instance_valid(existing_note):
			continue
		
		var time_diff = abs(existing_note.note_data.time_ms - new_time)
		if time_diff < 50.0:  # 50ms 이내면 동시 노트로 판단
			existing_note.set_stacked(true)
			new_note.set_stacked(true)


# 스와이프 노트 연결선 설정
func _setup_swipe_connection(note_obj: NoteObject):
	var group_id = note_obj.note_data.get("swipe_group_id", -1)
	if group_id == -1:
		return
	
	# 그룹 배열 초기화
	if not spawned_swipe_notes_by_group.has(group_id):
		spawned_swipe_notes_by_group[group_id] = []
	
	var group_notes: Array = spawned_swipe_notes_by_group[group_id]
	
	# 이전 노트와 연결 (시간순으로 스폰되므로 마지막 노트가 이전 노트)
	if not group_notes.is_empty():
		var prev_note = group_notes.back()
		if is_instance_valid(prev_note):
			prev_note.setup_swipe_connection(note_obj)
	
	# 현재 노트를 그룹에 추가
	group_notes.append(note_obj)


# [NEW] 버퍼 시스템에서 호출 - 입력 처리 가능 여부를 반환
func _try_process_lane_input(lane_index: int) -> bool:
	var lane_array: Array = active_notes_by_lane[lane_index]
	
	if lane_array.is_empty():
		return false # 처리할 노트 없음
		
	var target_note: NoteObject = lane_array[0]
	var note_type = target_note.note_data.note_type

	if note_type == GlobalEnums.NoteType.TAP:
		return _process_tap_note(lane_index, target_note)
	elif note_type == GlobalEnums.NoteType.SWIPE:
		return _process_swipe_note(lane_index, target_note)
	elif note_type == GlobalEnums.NoteType.LONG:
		return _process_long_note_start(lane_index, target_note)
	
	return false


# TAP 노트 판정 처리
func _process_tap_note(lane_index: int, target_note: NoteObject) -> bool:
	var time_diff = target_note.note_data.time_ms - current_song_time_ms
		
	# GOOD 판정 범위를 벗어난 입력은 처리하지 않음
	if abs(time_diff) > GOOD_MS:
		return false

	# 판정 처리 및 점수 계산
	var score_multiplier: float = 0.0
	
	if abs(time_diff) <= PERFECT_MS:
		_show_judgement("PERFECT")
		score_multiplier = 1.0  # 100%
		current_combo += 1
		judgement_counts["perfect"] += 1
	elif abs(time_diff) <= GREAT_MS:
		_show_judgement("GREAT")
		score_multiplier = 0.75  # 75%
		current_combo += 1
		judgement_counts["great"] += 1
	elif abs(time_diff) <= GOOD_MS:
		_show_judgement("GOOD")
		score_multiplier = 0.5  # 50%
		current_combo += 1
		judgement_counts["good"] += 1
	
	# Fast/Slow 판정 (Early = Fast, Late = Slow)
	if time_diff < 0:
		fast_count += 1
	elif time_diff > 0:
		slow_count += 1
	
	# 점수 누적
	total_score_points += score_multiplier
	processed_notes_count += 1
	
	# 노트 제거
	active_notes_by_lane[lane_index].pop_front() 
	target_note.queue_free()
	
	return true


# SWIPE 노트 판정 처리 (첫 노트 vs 후속 노트 구분)
func _process_swipe_note(lane_index: int, target_note: NoteObject) -> bool:
	var time_diff = target_note.note_data.time_ms - current_song_time_ms
	var is_head = target_note.note_data.get("is_swipe_head", false)
	
	# 판정 범위 결정 (첫 노트: 일반 TAP, 후속: 더 널널한 판정)
	var perfect_threshold = PERFECT_MS if is_head else SWIPE_PERFECT_MS
	var great_threshold = GREAT_MS if is_head else SWIPE_GREAT_MS
	var good_threshold = GOOD_MS if is_head else SWIPE_GOOD_MS
	
	# 판정 범위를 벗어난 입력은 처리하지 않음
	if abs(time_diff) > good_threshold:
		return false

	# 판정 처리 및 점수 계산
	var score_multiplier: float = 0.0
	
	if abs(time_diff) <= perfect_threshold:
		_show_judgement("PERFECT")
		score_multiplier = 1.0
		current_combo += 1
		judgement_counts["perfect"] += 1
	elif abs(time_diff) <= great_threshold:
		_show_judgement("GREAT")
		score_multiplier = 0.75
		current_combo += 1
		judgement_counts["great"] += 1
	elif abs(time_diff) <= good_threshold:
		_show_judgement("GOOD")
		score_multiplier = 0.5
		current_combo += 1
		judgement_counts["good"] += 1
	
	# Fast/Slow 판정
	if time_diff < 0:
		fast_count += 1
	elif time_diff > 0:
		slow_count += 1
	
	# 점수 누적
	total_score_points += score_multiplier
	processed_notes_count += 1
	
	# 노트 제거
	active_notes_by_lane[lane_index].pop_front() 
	target_note.queue_free()
	
	return true


# LONG 노트 시작 판정 처리 (시작 시 TAP과 동일한 규칙 적용)
func _process_long_note_start(lane_index: int, target_note: NoteObject) -> bool:
	var time_diff = target_note.note_data.time_ms - current_song_time_ms
		
	# GOOD 판정 범위를 벗어난 입력은 처리하지 않음
	if abs(time_diff) > GOOD_MS:
		return false

	# 판정 처리 및 점수 계산 (TAP과 동일)
	var score_multiplier: float = 0.0
	
	if abs(time_diff) <= PERFECT_MS:
		_show_judgement("PERFECT")
		score_multiplier = 1.0
		current_combo += 1
		judgement_counts["perfect"] += 1
	elif abs(time_diff) <= GREAT_MS:
		_show_judgement("GREAT")
		score_multiplier = 0.75
		current_combo += 1
		judgement_counts["great"] += 1
	elif abs(time_diff) <= GOOD_MS:
		_show_judgement("GOOD")
		score_multiplier = 0.5
		current_combo += 1
		judgement_counts["good"] += 1
	
	# Fast/Slow 판정
	if time_diff < 0:
		fast_count += 1
	elif time_diff > 0:
		slow_count += 1
	
	# 점수 누적
	total_score_points += score_multiplier
	processed_notes_count += 1
	
	# LONG 노트를 홀드 상태로 전환 (제거하지 않고 유지)
	# 노트를 활성 리스트에서 제거하고 홀드 리스트로 이동
	active_notes_by_lane[lane_index].pop_front()
	holding_long_notes[lane_index] = target_note
	target_note.note_data["is_holding"] = true
	
	return true
	
	return true


func _show_judgement(judgement_text: String):
	# Judgement Display Mode에 따라 표시 여부 결정
	match UserSettings.judgement_display_mode:
		UserSettings.JudgementDisplayMode.OFF:
			return  # 표시 안함
		UserSettings.JudgementDisplayMode.HIDE:
			return  # 판정 처리는 하지만 표시 안함
		UserSettings.JudgementDisplayMode.ALL_EXCEPT_ULTIMATE:
			# Ultimate은 추후 구현, 현재는 모두 표시
			pass
		UserSettings.JudgementDisplayMode.BELOW_PERFECT:
			if judgement_text == "PERFECT":
				return  # Perfect는 표시 안함
	
	if is_instance_valid(judgement_label):
		judgement_label.text = judgement_text
	print(judgement_text)

# Miss 처리: 콤보 리셋, 점수 0점 추가
func _on_miss():
	current_combo = 0  # 콤보 초기화
	total_score_points += 0.0  # Miss는 0점
	processed_notes_count += 1
	judgement_counts["miss"] += 1

func _check_song_end():
	# 모든 노트가 처리되었는지 확인 (음악 종료와 무관)
	if processed_notes_count >= total_notes_count and not all_notes_processed:
		all_notes_processed = true
		time_since_last_note = 0.0
		print("[Ingame] All notes processed. Starting %d second end delay..." % END_DELAY_TIME)
	
	# 모든 노트 처리 후 3초 대기
	if all_notes_processed:
		# 2초 지점에서 페이드아웃 시작 (음악이 재생 중인 경우만)
		if time_since_last_note >= FADEOUT_START_TIME and not fadeout_started and music_player.playing:
			fadeout_started = true
			_start_music_fadeout()
			print("[Ingame] Starting music fadeout at %.1f seconds" % time_since_last_note)
		
		# 3초 후 결과 화면으로 이동
		if time_since_last_note >= END_DELAY_TIME:
			_save_result_and_go_to_result_screen()

func _start_music_fadeout():
	# Tween을 사용하여 음악 볼륨을 부드럽게 감소
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, FADEOUT_DURATION)
	print("[Ingame] Music fadeout tween created (%.1f seconds)" % FADEOUT_DURATION)

func _save_result_and_go_to_result_screen():
	# 판정 퍼센트 계산
	var rate_percentage: float = 0.0
	if processed_notes_count > 0:
		rate_percentage = (total_score_points / float(processed_notes_count)) * 100.0
	
	# 결과 데이터를 GameplayData에 저장
	GameplayData.result_data = {
		"rate_percentage": rate_percentage,
		"judgement_counts": judgement_counts.duplicate(),
		"fast_count": fast_count,
		"slow_count": slow_count,
		"total_notes": total_notes_count,
		"max_combo": current_combo  # TODO: 최대 콤보 추적 필요
	}
	
	print("[Ingame] Game finished. Rate: %.2f%%, Transitioning to result screen..." % rate_percentage)
	
	# 리절트 화면으로 이동
	get_tree().change_scene_to_file("res://scenes/gameplay/result/result.tscn")

func _update_center_display():
	if not is_instance_valid(center_display_label):
		return
	
	match UserSettings.center_display_type:
		UserSettings.CenterDisplayType.SCORE:
			# 점수 퍼센트 표시
			var rate = 0.0
			if processed_notes_count > 0:
				rate = (total_score_points / float(processed_notes_count)) * 100.0
			center_display_label.text = "Rate: %.2f%%" % rate
		
		UserSettings.CenterDisplayType.COMBO:
			# 콤보 표시
			if current_combo > 0:
				center_display_label.text = "%d Combo" % current_combo
			else:
				center_display_label.text = ""
		
		UserSettings.CenterDisplayType.SUDDEN_COUNT:
			# Sudden Death 카운트 표시 (TODO: 구현 필요)
			center_display_label.text = "SD: ---"
		
		UserSettings.CenterDisplayType.OFF:
			# 표시 안함
			center_display_label.text = ""

#endregion

#region Input Processing
#------------------------------------

func _process_input_buffer():
	# 입력 버퍼가 비어있으면 처리할 것 없음
	if input_buffer.is_empty():
		return
	
	# 버퍼의 모든 입력을 처리
	for input_event in input_buffer:
		var lane = input_event.lane
		var input_time = input_event.time_ms
		
		# 입력 시간이 현재 시간과 너무 차이나면 무시 (오래된 입력)
		if abs(current_song_time_ms - input_time) > INPUT_BUFFER_TIME_MS:
			continue
		
		# 해당 레인의 노트 처리 시도
		_try_process_lane_input(lane)
	
	# 버퍼 비우기
	input_buffer.clear()


# 스와이프 노트용: 키가 눌려있는 상태에서 스와이프 노트 처리
func _process_held_keys_for_swipe():
	if input_block_time_ms > 0.0:
		return
	
	# 각 레인에 대해 키가 눌려있는지 확인
	var lane_actions = ["lane_1", "lane_2", "lane_3", "lane_4", "lane_5", "lane_6", "lane_7"]
	var lane_indices = [
		GlobalEnums.Lane.SIDE_L, GlobalEnums.Lane.MID_1, GlobalEnums.Lane.MID_2,
		GlobalEnums.Lane.MID_3, GlobalEnums.Lane.MID_4, GlobalEnums.Lane.MID_5,
		GlobalEnums.Lane.SIDE_R
	]
	
	for i in range(lane_actions.size()):
		if Input.is_action_pressed(lane_actions[i]):
			var lane_index = lane_indices[i]
			var lane_array: Array = active_notes_by_lane[lane_index]
			
			if lane_array.is_empty():
				continue
			
			var target_note: NoteObject = lane_array[0]
			
			# 스와이프 노트만 홀드 처리
			if target_note.note_data.note_type == GlobalEnums.NoteType.SWIPE:
				_try_process_lane_input(lane_index)


# LONG 노트 홀드 상태 체크 (키를 떼면 노트 제거, 꼬리가 지나가면 자동 제거)
func _process_holding_long_notes():
	var lane_actions = ["lane_1", "lane_2", "lane_3", "lane_4", "lane_5", "lane_6", "lane_7"]
	var lane_indices = [
		GlobalEnums.Lane.SIDE_L, GlobalEnums.Lane.MID_1, GlobalEnums.Lane.MID_2,
		GlobalEnums.Lane.MID_3, GlobalEnums.Lane.MID_4, GlobalEnums.Lane.MID_5,
		GlobalEnums.Lane.SIDE_R
	]
	
	var notes_to_release: Array = []
	
	for lane_index in holding_long_notes.keys():
		var note_obj: NoteObject = holding_long_notes[lane_index]
		
		if not is_instance_valid(note_obj):
			notes_to_release.append(lane_index)
			continue
		
		var note_end_time_ms = note_obj.note_data.time_ms + note_obj.note_data.duration_ms
		
		# 꼬리가 판정선을 지나갔으면 자동 제거 (성공적으로 홀드 완료)
		if current_song_time_ms >= note_end_time_ms:
			notes_to_release.append(lane_index)
			note_obj.queue_free()
			continue
		
		# 홀드 중인 노트 시각적 업데이트 (높이 감소)
		note_obj.update_holding_visual(current_song_time_ms)
		
		# 해당 레인의 키가 눌려있는지 확인
		var action_index = lane_indices.find(lane_index)
		if action_index >= 0 and action_index < lane_actions.size():
			if not Input.is_action_pressed(lane_actions[action_index]):
				# 키를 뗐으면 노트 제거
				notes_to_release.append(lane_index)
				note_obj.queue_free()
	
	# 홀드 목록에서 제거
	for lane_index in notes_to_release:
		holding_long_notes.erase(lane_index)

#endregion

#region Pause/Resume
#------------------------------------

func _pause_game():
	if current_state != GameState.PLAYING:
		return
	
	print("[Ingame] Game paused")
	current_state = GameState.PAUSED
	get_tree().paused = true
	
	# Pause Popup 표시
	if pause_popup:
		pause_popup.show()

func _on_pause_resume():
	if current_state != GameState.PAUSED:
		return
	
	print("[Ingame] Game resumed")
	
	# Pause Popup 숨기기
	if pause_popup:
		pause_popup.hide()
	
	# 입력 차단 (50ms)
	input_block_time_ms = RESUME_INPUT_BLOCK_MS
	
	# 게임 재개
	current_state = GameState.PLAYING
	get_tree().paused = false

func _on_pause_restart():
	print("[Ingame] Restarting game...")
	get_tree().paused = false
	_restart_game()

# Select Music 버튼 처리 - 저장 없이 셀렉트송으로 이동
func _on_pause_select_music():
	get_tree().paused = false
	music_player.stop()
	get_tree().change_scene_to_file("res://scenes/gameplay/select_song/select_song.tscn")

#endregion

#region Restart/Clear
#------------------------------------

func _restart_game():
	print("게임 상태 초기화 및 1초 후 재시작...")
	get_tree().paused = false
	music_player.stop()
	
	start_delay_timer.stop()
	
	current_state = GameState.LOADING 
	
	_clear_all_notes()
	
	note_spawn_index = 0
	current_song_time_ms = 0.0
	
	_transition_to_ready()

func _clear_all_notes():
	for lane_array in active_notes_by_lane:
		for note_obj in lane_array:
			if is_instance_valid(note_obj):
				note_obj.queue_free()
		lane_array.clear()
	
	# 홀드 중인 LONG 노트 제거
	for lane_index in holding_long_notes.keys():
		var note_obj = holding_long_notes[lane_index]
		if is_instance_valid(note_obj):
			note_obj.queue_free()
	holding_long_notes.clear()
	
	# 스와이프 그룹 초기화
	spawned_swipe_notes_by_group.clear()
	
	# 입력 버퍼도 초기화
	input_buffer.clear()

#endregion
