extends Control

#-- 상태 머신 (State Machine) --
enum GameState {
	LOADING,      # 1. 로딩 중
	COUNTDOWN,    # 2. 시작 전 카운트다운
	PLAYING,      # 3. 플레이 중
	PAUSED,       # 4. 일시정지
	SHOW_RESULT,  # 5. 결과 표시
	TRANSITIONING # 6. 씬 전환 중
}
var current_state = GameState.LOADING

#-- 씬 노드 레퍼런스 --
@onready var loading_screen = $LoadingScreen
@onready var gameplay_ui = $GameplayUI
@onready var pause_menu = $PauseMenu
@onready var pause_popup = $PausePopup
@onready var note_manager = $NoteManager
@onready var music_player = $MusicPlayer
@onready var loading_timer = $Timers/LoadingTimer
@onready var start_delay_timer = $Timers/StartDelayTimer
@onready var result_timer = $Timers/ResultTimer
<<<<<<< Updated upstream

#-- 씬 및 설정값 --
const NoteObjectScene = preload("res://scenes/gameplay/ingame/NoteObject.tscn")

@export var note_speed_pixels_per_sec: float = 1000.0
var judge_line_y: float = 880.0 # 모바일 UI 이미지에 맞게 Y좌표 수정 (임시)

=======
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
const MISS_MS = 150 # 이 시간 이후에 치면 Miss, 이 시간 전에 치면 Fast

# -- 입력 버퍼 시스템 --
var input_buffer: Array[Dictionary] = [] # 입력 이벤트 버퍼
const INPUT_BUFFER_TIME_MS = 50.0 # 입력을 버퍼에 유지하는 시간

# -- 노트 관리 변수 --
>>>>>>> Stashed changes
var note_spawn_index: int = 0
var current_song_time_ms: float = 0.0

# [FIX] NoteObject가 class_name으로 등록되었으므로, 이제 이 타입 힌트가 정상 작동합니다.
var active_notes: Array[NoteObject] = []
var game_gear_node: Control

#-- 게임 데이터 변수 --
var selected_song_data: Dictionary
var selected_difficulty_data: Dictionary
var chart_data: Dictionary

<<<<<<< Updated upstream
=======
# -- 노트 스폰/관리용 변수 --
var parsed_note_list: Array[Dictionary] = [] 
var note_object_scene = preload("res://scenes/gameplay/ingame/NoteObject.tscn")
var rails: Array[Rail] = []

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

#region Godot Lifecycle Functions
#------------------------------------
>>>>>>> Stashed changes

func _ready():
	# 1. UI 초기화
	loading_screen.show()
	gameplay_ui.hide()
<<<<<<< Updated upstream
	pause_menu.hide()

	# 2. 로딩 타이머 설정
	loading_timer.wait_time = 2.0
	loading_timer.one_shot = true
	loading_timer.start()

	# 3. 데이터 로딩 프로세스 시작
	_start_loading_process()


func _physics_process(delta):
	if current_state != GameState.PLAYING:
		return

	# [버그 수정]
	# 1. `delta`를 사용하여 시간을 수동으로 증가시킵니다.
	#    이렇게 하면 music_player가 1프레임 늦게 시작해도 게임 루프가 멈추지 않습니다.
	current_song_time_ms += delta * 1000.0

	# 2. music_player가 재생 중일 때, 시간을 오디오에 동기화합니다.
	if music_player.is_playing():
		current_song_time_ms = music_player.get_playback_position() * 1000.0
	
	# 3. `else: return`을 제거하여 아래 코드가 항상 실행되도록 합니다.

	# 현재 시간에 맞춰 노트를 스폰합니다.
	_spawn_notes()
	
	# 화면에 활성화된 노트들의 위치를 업데이트합니다.
	var notes_to_remove = []
	for note in active_notes:
		note.update_position(current_song_time_ms, judge_line_y)
		# update_position에서 큐프리된 노트를 배열에서 제거
		if not is_instance_valid(note):
			notes_to_remove.push_back(note)
	
	for note in notes_to_remove:
		active_notes.erase(note)
=======
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
	center_display_label.custom_minimum_size = Vector2(400, 80)
	center_display_label.offset_left = -200
	center_display_label.offset_top = -130  # JudgementLabel 위쪽 (약 80px 위)
	center_display_label.offset_right = 200
	center_display_label.offset_bottom = -50
	center_display_label.add_theme_font_size_override("font_size", 24)  # Fast/Slow와 동일한 크기
	center_display_label.text = ""
	gameplay_ui.add_child(center_display_label)

	start_delay_timer.timeout.connect(_on_start_delay_timer_timeout)
	start_delay_timer.one_shot = true
	
	# PausePopup 시그널 연결
	if pause_popup:
		pause_popup.resume_requested.connect(_on_pause_resume)
		pause_popup.restart_requested.connect(_on_pause_restart)
		pause_popup.select_music_requested.connect(_on_pause_select_music)
	
	await _start_loading_process()

# [MODIFIED] 입력 처리 - 버퍼링 시스템 사용으로 입력 누락 방지
func _unhandled_input(event):
	# ESC 키로 일시정지 팝업 표시/숨김
	if event.is_action_pressed("ui_cancel", true):
		if current_state == GameState.PLAYING:
			_pause_game()
		elif current_state == GameState.PAUSED:
			_on_pause_resume()
		get_viewport().set_input_as_handled()
		return
	
	# F5 재시작 (정확한 타이밍을 위해 "just pressed" 사용)
	if event.is_action_pressed("debug_restart", true):
		print("DEBUG: Restarting game state...")
		_restart_game()
		get_viewport().set_input_as_handled()
		return
		
	# 게임 플레이 중이 아니면 입력 무시
	if current_state != GameState.PLAYING:
		return
		
	# 마우스 이동 등 불필요한 이벤트 무시
	if not (event is InputEventKey or event is InputEventScreenTouch or event is InputEventJoypadButton):
		return

	# [NEW] 모든 레인 입력을 버퍼에 추가 (동시입력 보장)
	# 두 번째 'true' 인자가 'just_pressed'와 동일하게 작동합니다.
	var lanes_pressed = []
	
	if event.is_action_pressed("lane_1", true):
		lanes_pressed.append(GlobalEnums.Lane.SIDE_L)
	if event.is_action_pressed("lane_2", true):
		lanes_pressed.append(GlobalEnums.Lane.MID_1)
	if event.is_action_pressed("lane_3", true):
		lanes_pressed.append(GlobalEnums.Lane.MID_2)
	if event.is_action_pressed("lane_4", true):
		lanes_pressed.append(GlobalEnums.Lane.MID_3)
	if event.is_action_pressed("lane_5", true):
		lanes_pressed.append(GlobalEnums.Lane.MID_4)
	if event.is_action_pressed("lane_6", true):
		lanes_pressed.append(GlobalEnums.Lane.MID_5)
	if event.is_action_pressed("lane_7", true):
		lanes_pressed.append(GlobalEnums.Lane.SIDE_R)
	
	# 입력된 레인들을 버퍼에 추가
	if not lanes_pressed.is_empty():
		for lane in lanes_pressed:
			input_buffer.append({
				"lane": lane,
				"time_ms": current_song_time_ms
			})
		get_viewport().set_input_as_handled()


# [MODIFIED] _physics_process -> _process로 변경 (판정 Jitter 해결)
func _process(delta):
	# 입력 블록 타이머 처리
	if input_block_time_ms > 0.0:
		input_block_time_ms -= delta * 1000.0
		if input_block_time_ms < 0.0:
			input_block_time_ms = 0.0
	
	match current_state:
		GameState.PLAYING:
			_process_input_buffer() # 버퍼된 입력 처리
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
>>>>>>> Stashed changes


# 비동기(asynchronous) 로딩 프로세스를 처리하는 메인 함수
func _start_loading_process():
<<<<<<< Updated upstream
	# 1. GameplayData로부터 곡 정보 가져오기
	if not _load_data_from_globals():
		printerr("[ERROR] 필수 데이터가 없어 메인 메뉴로 돌아갑니다.")
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		return

	# 2. 채보(.json) 파일 로드하기
	if not _load_chart_data():
		printerr("[ERROR] 채보 파일 로드에 실패하여 메인 메뉴로 돌아갑니다.")
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		return

	# 3. NoteManager에 채보 데이터 전달 및 파싱
	note_manager.parse_chart(chart_data)
	
	# 4. 노트 매니저의 파싱된 노트를 시간순으로 정렬
	note_manager.parsed_note_list.sort_custom(
		func(a, b): return a.time_ms < b.time_ms
	)
=======
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
		printerr("[ERROR] GameplayUI에 GameGear 씬이 인스턴스화되지 않았습니다.")
		return

	game_gear_transform_inv = game_gear_node.get_global_transform_with_canvas().affine_inverse()

	var rail_container = game_gear_node.get_node_or_null("RailContainer")
	if rail_container == null:
		printerr("[ERROR] GameGear.tscn에 'RailContainer'가 없습니다.")
		return
		
	var expected_rail_count = 8
	if rail_container.get_child_count() != expected_rail_count:
		printerr("[CRITICAL ERROR] 'RailContainer'의 자식 노드 수가 잘못되었습니다. (기대: %d, 실제: %d)" % [expected_rail_count, rail_container.get_child_count()])
		return

	rails.clear() 
	for i in range(expected_rail_count): 
		var rail_node = rail_container.get_child(i)
		if rail_node is Rail:
			rails.append(rail_node)
		else:
			printerr("[ERROR] RailContainer의 자식 노드가 Rail 타입이 아닙니다: ", i)
			return 
>>>>>>> Stashed changes

	# 5. (구현 예정) 로딩 화면에 곡 정보 표시
	# loading_screen.get_node("TitleLabel").text = selected_song_data.title
	
	print("[INFO] 데이터 로딩 완료. 최소 로딩 시간(2초) 대기 중...")

	# 6. 최소 로딩 시간(2초)이 끝날 때까지 대기
	await loading_timer.timeout
	
<<<<<<< Updated upstream
	print("[INFO] 로딩 완료. 게임 시작 카운트다운으로 전환합니다.")
	
	# 7. 로딩이 끝났으므로 게임 시작 전 카운트다운으로 전환
	_transition_to_countdown()
=======
	_transition_to_ready()
>>>>>>> Stashed changes


# GameplayData 싱글톤에서 데이터를 가져옵니다.
func _load_data_from_globals() -> bool:
	if GameplayData.selected_song_data == null or GameplayData.selected_difficulty_data == null:
		return false
		
	selected_song_data = GameplayData.selected_song_data
	selected_difficulty_data = GameplayData.selected_difficulty_data
	return true


# 선택된 난이도의 채보(.json) 파일을 불러옵니다.
func _load_chart_data() -> bool:
	var chart_path = selected_difficulty_data.get("path")
	if not FileAccess.file_exists(chart_path):
		printerr("[ERROR] 채보 파일을 찾을 수 없습니다: %s" % chart_path)
		return false
	
	var file = FileAccess.open(chart_path, FileAccess.READ)
	var content = file.get_as_text()
	chart_data = JSON.parse_string(content)
	
	if chart_data == null:
		printerr("[ERROR] 채보 파일 파싱에 실패했습니다: %s" % chart_path)
		return false

	return true


<<<<<<< Updated upstream
# 로딩 단계에서 -> 카운트다운 단계로 전환합니다.
func _transition_to_countdown():
	current_state = GameState.COUNTDOWN
	
	# 로딩 화면 숨기기, 게임 UI 표시
	loading_screen.hide()
	gameplay_ui.show()
	
	# GameGear 노드를 찾아서 변수에 저장
	game_gear_node = $GameplayUI.get_node_or_null("GameGear")
	if game_gear_node == null:
		printerr("CRITICAL ERROR: 'GameGear.tscn' 씬이 'GameplayUI' 노드에 추가되지 않았습니다.")
		# 이 오류는 캔버스 지침을 따랐다면 발생하지 않습니다.
		return

	# 2초 후 게임을 시작하기 위해 타이머 설정
	start_delay_timer.wait_time = 2.0
	start_delay_timer.one_shot = true
	# 타이머가 끝나면 _start_game 함수를 호출하도록 연결
	start_delay_timer.timeout.connect(_start_game)
	start_delay_timer.start()
=======
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

	start_delay_timer.wait_time = 3.0  # 3초로 변경
	start_delay_timer.start()


func _on_start_delay_timer_timeout():
	_start_game()
>>>>>>> Stashed changes


# 실제 게임 플레이를 시작합니다.
func _start_game():
	print("게임 시작! (0ms 시작)")
	current_state = GameState.PLAYING
	
<<<<<<< Updated upstream
	# 변수 초기화
	note_spawn_index = 0
	current_song_time_ms = 0.0
	
	# 음악 로드 및 재생
	var audio_path = selected_song_data.get("audio_path")
	if not FileAccess.file_exists(audio_path):
		printerr("[ERROR] 오디오 파일을 찾을 수 없습니다: %s" % audio_path)
		return
		
	var stream = load(audio_path)
	music_player.stream = stream
	music_player.play()


# 현재 시간에 스폰해야 할 노트들을 처리
func _spawn_notes():
	# 노트가 스폰되어야 하는 시간적 여유 (노트가 화면 상단에 보이기 시작하는 시간)
	var travel_time_ms = (judge_line_y / note_speed_pixels_per_sec) * 1000.0
	
	# 스폰 큐를 확인
	while note_spawn_index < note_manager.parsed_note_list.size():
		var note_data = note_manager.parsed_note_list[note_spawn_index]
		
		# 이 노트가 스폰되어야 하는 시간인가?
		if note_data.time_ms <= current_song_time_ms + travel_time_ms:
			# 스폰!
			_spawn_note_object(note_data)
=======
	# current_song_time_ms는 0에 가까워야 함 (READY에서 -3000ms부터 증가)
	current_song_time_ms = 0.0  # 음악 시작 시점으로 리셋
	
	if music_player.stream:
		music_player.play()
	else:
		print("[WARNING] 음악 스트림이 없어 재생할 수 없습니다.")

# [NEW] 입력 버퍼 처리 함수 - 매 프레임마다 버퍼된 입력을 처리
func _process_input_buffer():
	# 입력 블록 중이면 버퍼 처리 중단
	if input_block_time_ms > 0.0:
		return
	
	# 오래된 입력 제거
	var expired_inputs = []
	for i in range(input_buffer.size()):
		var input_data = input_buffer[i]
		var time_diff = current_song_time_ms - input_data.time_ms
		if time_diff > INPUT_BUFFER_TIME_MS:
			expired_inputs.append(i)
	
	# 역순으로 제거 (인덱스 변경 방지)
	for i in range(expired_inputs.size() - 1, -1, -1):
		input_buffer.remove_at(expired_inputs[i])
	
	# 버퍼에 있는 입력 처리 (FIFO 순서)
	var processed_inputs = []
	for i in range(input_buffer.size()):
		var input_data = input_buffer[i]
		var lane_index = input_data.lane
		
		# 해당 레인에 처리 가능한 노트가 있는지 확인
		if _try_process_lane_input(lane_index):
			processed_inputs.append(i)
	
	# 처리된 입력 제거 (역순)
	for i in range(processed_inputs.size() - 1, -1, -1):
		input_buffer.remove_at(processed_inputs[i])


func _update_gameplay(delta):
	if current_state == GameState.PLAYING:
		if music_player.is_playing():
			current_song_time_ms = music_player.get_playback_position() * 1000.0
		else:
			pass 
	
	# ---
	# 1. 노트 스폰 확인
	# ---
	while note_spawn_index < parsed_note_list.size():
		var next_note_data = parsed_note_list[note_spawn_index]
		
		if rails.is_empty(): break 
		
		var reference_rail = rails[0]
		var local_top_y = (game_gear_transform_inv * Vector2(0, reference_rail.get_global_top_y())).y
		var local_judge_y = (game_gear_transform_inv * Vector2(0, reference_rail.get_global_judge_y())).y
		
		var time_to_judge_sec = 0.0
		var distance = local_judge_y - local_top_y
		
		if distance > 0 and note_speed_pixels_per_sec > 0:
			time_to_judge_sec = distance / note_speed_pixels_per_sec
		if time_to_judge_sec <= 0: time_to_judge_sec = 1.0 
		
		var time_to_judge_ms = time_to_judge_sec * 1000.0
		
		var spawn_time_ms = next_note_data.time_ms - time_to_judge_ms
		
		if current_song_time_ms >= spawn_time_ms:
			_spawn_note_object(next_note_data)
>>>>>>> Stashed changes
			note_spawn_index += 1
		else:
			# 아직 스폰할 시간이 아님. 다음 프레임에 확인
			break

<<<<<<< Updated upstream

# 실제 노트 오브젝트 씬을 인스턴스화하고 배치
func _spawn_note_object(note_data: ParsedNote):
	var note_obj = NoteObjectScene.instantiate()
	
	# 레인 컨테이너에서 해당 레인 노드 찾기
	var lane_container = game_gear_node.get_node("LaneContainer")
	if lane_container == null:
		printerr("[ERROR] GameGear.tscn에 'LaneContainer'가 없습니다.")
		return
		
	# [FIX] get_child는 인덱스(0~6)로 노드를 가져옴.
	# note_data.lane은 ParsedNote.Lane 열거형 (0~6)이므로 올바르게 작동합니다.
	var lane_node: Position2D = lane_container.get_child(note_data.lane)
	if lane_node == null:
		printerr("[ERROR] 레인 노드를 찾을 수 없습니다: %d" % note_data.lane)
=======
	# ---
	# 2. 활성 노트 업데이트
	# ---
	notes_to_remove.clear() 
	
	for lane_array in active_notes_by_lane:
		for note_obj in lane_array:
			if is_instance_valid(note_obj):
				var wants_to_die = note_obj.update_position(current_song_time_ms)
				
				if current_state == GameState.PLAYING:
					if wants_to_die:
						if not notes_to_remove.has(note_obj): 
							notes_to_remove.append(note_obj)
							_show_judgement("Miss (Off-screen)")
							_on_miss()  # Miss 처리
						continue 
					
					var time_diff = note_obj.note_data.time_ms - current_song_time_ms
					if time_diff < -MISS_MS: 
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
>>>>>>> Stashed changes
		return

	# [FIX] 이제 Position2D 노드의 position.x 값을 사용합니다.
	# 노트의 X 위치는 레인의 X 위치와 같습니다.
	note_obj.position = Vector2(lane_node.position.x, 0) # Y는 update_position에서 계산됨
	note_obj.init(note_data, note_speed_pixels_per_sec, judge_line_y)
	
<<<<<<< Updated upstream
	active_notes.push_back(note_obj)
=======
	note_obj.init(note_data, left_rail, right_rail, note_speed_pixels_per_sec, game_gear_node)
>>>>>>> Stashed changes
	
	# [FIX] 노트를 GameGear 노드의 자식으로 추가합니다.
	# 이렇게 하면 모든 노트가 GameGear의 로컬 좌표계를 기준으로 움직입니다.
	game_gear_node.add_child(note_obj)
<<<<<<< Updated upstream
=======
	active_notes_by_lane[lane_index].push_back(note_obj)


# [NEW] 버퍼 시스템에서 호출 - 입력 처리 가능 여부를 반환
func _try_process_lane_input(lane_index: int) -> bool:
	var lane_array: Array = active_notes_by_lane[lane_index]
	
	if lane_array.is_empty():
		return false # 처리할 노트 없음
		
	var target_note: NoteObject = lane_array[0]

	if target_note.note_data.note_type != GlobalEnums.NoteType.TAP:
		return false # TAP 노트만 처리

	var time_diff = target_note.note_data.time_ms - current_song_time_ms
		
	# GOOD 판정 범위를 벗어난 입력은 처리하지 않음
	if abs(time_diff) > GOOD_MS:
		return false

	# 판정 처리 및 점수 계산
	var score_multiplier: float = 0.0
	var judgement_type: String = ""
	
	if abs(time_diff) <= PERFECT_MS:
		judgement_type = "perfect"
		_show_judgement("PERFECT")
		score_multiplier = 1.0  # 100%
		current_combo += 1
		judgement_counts["perfect"] += 1
	elif abs(time_diff) <= GREAT_MS:
		judgement_type = "great"
		_show_judgement("GREAT")
		score_multiplier = 0.75  # 75%
		current_combo += 1
		judgement_counts["great"] += 1
	elif abs(time_diff) <= GOOD_MS:
		judgement_type = "good"
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
	
	return true # 성공적으로 처리됨

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
	
	var display_type = UserSettings.get_active_center_display_type()
	
	match display_type:
		UserSettings.CenterDisplayType.OFF:
			center_display_label.text = ""
		UserSettings.CenterDisplayType.SCORE:
			# 판정 퍼센트 표기: Rate: XX.XX%
			var rate_percentage: float = 0.0
			if processed_notes_count > 0:
				rate_percentage = (total_score_points / float(processed_notes_count)) * 100.0
			center_display_label.text = "Rate: %.2f%%" % rate_percentage
		UserSettings.CenterDisplayType.COMBO:
			# 콤보 표기: N Combo
			if current_combo > 0:
				center_display_label.text = "%d Combo" % current_combo
			else:
				center_display_label.text = ""
		UserSettings.CenterDisplayType.SUDDEN_COUNT:
			# TODO: Sudden Death 시스템 구현 후 업데이트
			center_display_label.text = str(UserSettings.sudden_death_limit)

#endregion

#region Placeholder Functions (To be implemented)
#------------------------------------

func _show_result_screen():
	print("결과 화면 표시 (구현 필요)")
	current_state = GameState.SHOW_RESULT

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
	
	# 입력 버퍼도 초기화
	input_buffer.clear()

#endregion

#region Pause System Functions
#------------------------------------

# 일시정지 상태로 전환
func _pause_game():
	if current_state != GameState.PLAYING:
		return
	
	current_state = GameState.PAUSED
	music_player.stream_paused = true
	
	if pause_popup:
		pause_popup.show()

# Resume 버튼 처리 - 50ms 동안 입력 무시
var input_block_time_ms: float = 0.0
const INPUT_BLOCK_DURATION_MS: float = 50.0

func _on_pause_resume():
	if current_state != GameState.PAUSED:
		return
	
	current_state = GameState.PLAYING
	music_player.stream_paused = false
	
	if pause_popup:
		pause_popup.hide()
	
	# 50ms 동안 입력을 무시하기 위한 타이머 설정
	input_block_time_ms = INPUT_BLOCK_DURATION_MS
	input_buffer.clear()  # 버퍼도 초기화

# Restart 버튼 처리 (F5와 동일)
func _on_pause_restart():
	_restart_game()

# Select Music 버튼 처리 - 저장 없이 셀렉트송으로 이동
func _on_pause_select_music():
	get_tree().paused = false
	music_player.stop()
	get_tree().change_scene_to_file("res://scenes/gameplay/select_song/select_song.tscn")

#endregion
>>>>>>> Stashed changes
