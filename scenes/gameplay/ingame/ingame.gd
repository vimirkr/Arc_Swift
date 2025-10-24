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
@onready var note_manager = $NoteManager
@onready var music_player = $MusicPlayer
@onready var loading_timer = $Timers/LoadingTimer
@onready var start_delay_timer = $Timers/StartDelayTimer
@onready var result_timer = $Timers/ResultTimer

#-- 씬 및 설정값 --
const NoteObjectScene = preload("res://scenes/gameplay/ingame/NoteObject.tscn")

@export var note_speed_pixels_per_sec: float = 1000.0
var judge_line_y: float = 880.0 # 모바일 UI 이미지에 맞게 Y좌표 수정 (임시)

var note_spawn_index: int = 0
var current_song_time_ms: float = 0.0

# [FIX] NoteObject가 class_name으로 등록되었으므로, 이제 이 타입 힌트가 정상 작동합니다.
var active_notes: Array[NoteObject] = []
var game_gear_node: Control

#-- 게임 데이터 변수 --
var selected_song_data: Dictionary
var selected_difficulty_data: Dictionary
var chart_data: Dictionary


func _ready():
	# 1. UI 초기화
	loading_screen.show()
	gameplay_ui.hide()
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


# 비동기(asynchronous) 로딩 프로세스를 처리하는 메인 함수
func _start_loading_process():
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

	# 5. (구현 예정) 로딩 화면에 곡 정보 표시
	# loading_screen.get_node("TitleLabel").text = selected_song_data.title
	
	print("[INFO] 데이터 로딩 완료. 최소 로딩 시간(2초) 대기 중...")

	# 6. 최소 로딩 시간(2초)이 끝날 때까지 대기
	await loading_timer.timeout
	
	print("[INFO] 로딩 완료. 게임 시작 카운트다운으로 전환합니다.")
	
	# 7. 로딩이 끝났으므로 게임 시작 전 카운트다운으로 전환
	_transition_to_countdown()


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


# 실제 게임 플레이를 시작합니다.
func _start_game():
	print("게임 시작!")
	current_state = GameState.PLAYING
	
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
			note_spawn_index += 1
		else:
			# 아직 스폰할 시간이 아님. 다음 프레임에 확인
			break


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
		return

	# [FIX] 이제 Position2D 노드의 position.x 값을 사용합니다.
	# 노트의 X 위치는 레인의 X 위치와 같습니다.
	note_obj.position = Vector2(lane_node.position.x, 0) # Y는 update_position에서 계산됨
	note_obj.init(note_data, note_speed_pixels_per_sec, judge_line_y)
	
	active_notes.push_back(note_obj)
	
	# [FIX] 노트를 GameGear 노드의 자식으로 추가합니다.
	# 이렇게 하면 모든 노트가 GameGear의 로컬 좌표계를 기준으로 움직입니다.
	game_gear_node.add_child(note_obj)
