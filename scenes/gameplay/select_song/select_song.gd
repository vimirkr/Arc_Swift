extends Control

#-- UI Node References (MODIFIED) --
@onready var cover_stage = $MarginContainer/MainLayout/Content/MarginContainer/CoverStage
@onready var left_button = $MarginContainer/MainLayout/SubHeader/LeftButton
@onready var right_button = $MarginContainer/MainLayout/SubHeader/RightButton
@onready var category_button = $MarginContainer/MainLayout/SubHeader/CategoryButton
@onready var difficulty_buttons_container = $MarginContainer/MainLayout/Footer/DifficultyButtonsContainer
@onready var options_menu = $OptionsMenu
@onready var ingame_option_popup = $IngameOptionPopup
@onready var back_button = $MarginContainer/MainLayout/Header/BackButton
@onready var options_button = $MarginContainer/MainLayout/Header/OptionsButton
@onready var start_button = $MarginContainer/MainLayout/Footer/StartButton
@onready var preview_player = $PreviewPlayer

#-- Marker Positions (Will be calculated dynamically) --
var markers = {}

#-- State Machine --
enum Mode { SELECT_SONG, SELECT_CATEGORY }
var current_mode = Mode.SELECT_SONG

#-- Input Handling --
var swipe_start_pos = Vector2.ZERO
var swipe_start_time = 0
const SHORT_SWIPE_THRESHOLD = 150
const LONG_SWIPE_THRESHOLD = 400
const SWIPE_TIME_LIMIT = 500
const SHORT_SWIPE_JUMP = 5
const LONG_SWIPE_JUMP = 10

#-- Visual Settings --
const MOVE_DURATION = 0.25
const SELECTED_SCALE = Vector2(1.0, 1.0)
const UNSELECTED_SCALE = Vector2(0.75, 0.75)
const UNSELECTED_ALPHA = 0.7

#-- Dynamic Layout Variables --
var cover_size = Vector2.ZERO
var side_cover_gap = 0.0
var outer_cover_gap = 0.0


#-- Data --
const AlbumCover = preload("res://scenes/gameplay/select_song/album_cover.tscn")
var song_db = {}
var categories = []
var current_category_index = 0
var current_song_index = 0
var current_difficulty_index = 0

# A pool of AlbumCover nodes to reuse
var cover_pool = []
const COVER_POOL_SIZE = 7
var path_to_cover_map = {}


func _ready():
	await get_tree().process_frame

	var stage_height = cover_stage.size.y
	cover_size = Vector2(stage_height * 0.75, stage_height)
	side_cover_gap = stage_height * 0.05
	outer_cover_gap = stage_height * 0.025

	_load_song_database()
	_scan_song_folders()

	back_button.pressed.connect(_on_back_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	category_button.pressed.connect(_on_category_button_pressed)
	left_button.pressed.connect(func(): _change_selection(-1))
	right_button.pressed.connect(func(): _change_selection(1))

	_create_cover_pool()
	
	if not TextureLoader.is_connected("texture_loaded", _on_texture_loaded):
		TextureLoader.texture_loaded.connect(_on_texture_loaded)

	if categories.is_empty():
		category_button.text = tr("UI_NO_SONGS_FOUND")
		start_button.disabled = true
		left_button.disabled = true
		right_button.disabled = true
	else:
		_initialize_covers()

	_update_ui_text()

func _exit_tree():
	if preview_player:
		preview_player.stop()
	
	if TextureLoader and TextureLoader.is_connected("texture_loaded", _on_texture_loaded):
		TextureLoader.texture_loaded.disconnect(_on_texture_loaded)

func _initialize_covers():
	_calculate_marker_positions()
	_setup_album_covers()
	_update_display(false)  # 초기 표시는 애니메이션 없이
	_update_display(false)

func _input(event):
	if not is_node_ready() or categories.is_empty(): return

	if Input.is_action_just_pressed("ui_accept"):
		_on_start_button_pressed(); return
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_button_pressed(); return
	if Input.is_action_just_pressed("ui_options"):
		_on_options_button_pressed(); return
	if Input.is_action_just_pressed("ui_focus_next"):
		var diff_buttons = difficulty_buttons_container.get_children()
		if not diff_buttons.is_empty():
			current_difficulty_index = wrapi(current_difficulty_index + 1, 0, diff_buttons.size())
			_update_difficulty_buttons()
		return

	if Input.is_action_just_pressed("ui_left"): _change_selection(-1)
	if Input.is_action_just_pressed("ui_right"): _change_selection(1)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: _change_selection(-1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _change_selection(1)

	if event is InputEventScreenTouch:
		if event.is_pressed():
			swipe_start_pos = event.position
			swipe_start_time = Time.get_ticks_msec()
		elif event.is_released() and swipe_start_pos != Vector2.ZERO:
			var swipe_vector = event.position - swipe_start_pos
			var swipe_length = swipe_vector.length()
			var swipe_time = Time.get_ticks_msec() - swipe_start_time

			if swipe_time < SWIPE_TIME_LIMIT and abs(swipe_vector.x) > abs(swipe_vector.y):
				var jump_amount = 0
				if swipe_length > LONG_SWIPE_THRESHOLD:
					jump_amount = LONG_SWIPE_JUMP
				elif swipe_length > SHORT_SWIPE_THRESHOLD:
					jump_amount = SHORT_SWIPE_JUMP
				
				if jump_amount > 0:
					if swipe_vector.x < 0: _change_selection(-jump_amount)
					else: _change_selection(jump_amount)
			
			swipe_start_pos = Vector2.ZERO

func _calculate_marker_positions():
	var center_x = cover_stage.size.x / 2
	var center_y = cover_stage.size.y / 2
	
	markers[0] = Vector2(center_x, center_y)
	
	var side_offset = (cover_size.x / 2.0) + (cover_size.x * UNSELECTED_SCALE.x / 2.0) + side_cover_gap
	markers[1] = Vector2(center_x + side_offset, center_y)
	markers[-1] = Vector2(center_x - side_offset, center_y)

	var outer_offset = side_offset + (cover_size.x * UNSELECTED_SCALE.x / 2.0) + (cover_size.x * UNSELECTED_SCALE.x / 2.0) + outer_cover_gap
	markers[2] = Vector2(center_x + outer_offset, center_y)
	markers[-2] = Vector2(center_x - outer_offset, center_y)


func _load_song_database():
	var path = "res://song/_song_db.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var content = JSON.parse_string(file.get_as_text())
		if content: song_db = content
	else:
		printerr("_song_db.json not found!")

func _scan_song_folders():
	categories.clear()
	var dir = DirAccess.open("res://song")
	if not dir:
		printerr("Cannot open directory: res://song")
		return

	dir.list_dir_begin()
	var file_or_dir_name = dir.get_next()
	while file_or_dir_name != "":
		if dir.current_is_dir() and not file_or_dir_name.begins_with("."):
			var category_path = "res://song/%s" % file_or_dir_name
			var category_dir = DirAccess.open(category_path)
			if category_dir:
				category_dir.list_dir_begin()
				var inner_file = category_dir.get_next()
				while inner_file != "":
					if inner_file.begins_with("_category_") and inner_file.ends_with(".json"):
						var category_json_path = "%s/%s" % [category_path, inner_file]
						var file = FileAccess.open(category_json_path, FileAccess.READ)
						var song_list = JSON.parse_string(file.get_as_text())
						if song_list and not song_list.is_empty():
							categories.append({
								"name": file_or_dir_name,
								"path": category_path + "/",
								"songs": song_list
							})
						break 
					inner_file = category_dir.get_next()
		file_or_dir_name = dir.get_next()

func _create_cover_pool():
	for i in range(COVER_POOL_SIZE):
		var cover = AlbumCover.instantiate()
		cover.visible = false
		cover.set_deferred("size", cover_size)
		cover_stage.add_child(cover)
		cover_pool.append(cover)

func _change_selection(jump_amount: int):
	match current_mode:
		Mode.SELECT_SONG:
			if categories.is_empty() or categories[current_category_index].songs.is_empty(): return
			var current_song_list = categories[current_category_index].songs
			current_song_index = wrapi(current_song_index + jump_amount, 0, current_song_list.size())
		Mode.SELECT_CATEGORY:
			if categories.is_empty(): return
			current_category_index = wrapi(current_category_index + jump_amount, 0, categories.size())
			_setup_album_covers()
	
	_update_display()

func _setup_album_covers():
	current_song_index = 0
	current_difficulty_index = 0

func _update_display(use_animation: bool = true):
	if categories.is_empty() or markers.is_empty():
		for cover in cover_pool: cover.visible = false
		_update_difficulty_buttons()
		_update_ui_text()
		return

	category_button.text = categories[current_category_index].name
	var current_song_list = categories[current_category_index].songs
	
	path_to_cover_map.clear()
	
	if current_song_list.is_empty():
		for cover in cover_pool: cover.visible = false
		_update_difficulty_buttons()
		_play_current_song_preview()
		_update_ui_text()
		return

	for i in range(-2, 3):
		var song_index = wrapi(current_song_index + i, 0, current_song_list.size())
		var cover_node = cover_pool[i + 3]
		var song_entry = current_song_list[song_index]
		
		var full_song_data = song_db.get(song_entry.song_id, {})
		var jacket_path = categories[current_category_index].path + song_entry.jacket_file
		
		path_to_cover_map[jacket_path] = cover_node
		
		# 차트 데이터 로드 (모든 앨범 커버에서 표시)
		var is_selected = (i == 0)
		var chart_data = {}
		var is_regular = true  # 기본값: 정규 난이도
		
		# 선택된 커버는 현재 난이도, 선택되지 않은 커버는 첫 번째 난이도 사용
		if song_entry.has("charts") and not song_entry.charts.is_empty():
			var diff_index = 0
			if is_selected:
				diff_index = current_difficulty_index
				if diff_index >= song_entry.charts.size():
					diff_index = 0
			var chart_info = song_entry.charts[diff_index]
			var chart_path = categories[current_category_index].path + chart_info.file
			chart_data = _load_chart_metadata(chart_path)
			is_regular = chart_data.get("is_regular_difficulty", true)
		
		# 커버 먼저 표시
		cover_node.visible = true
		
		# 노드가 준비될 때까지 대기
		if not cover_node.is_node_ready():
			await cover_node.ready
		
		# 앨범 커버에 노래 정보와 차트 정보 전달
		cover_node.set_border_color(is_regular)
		cover_node.set_song_data(full_song_data, chart_data)
		
		if TextureLoader.cache.has(jacket_path):
			cover_node.set_texture(TextureLoader.cache[jacket_path])
		else:
			cover_node.set_texture(null) 
			TextureLoader.request_texture(jacket_path)

		var target_pos = markers[i]
		var target_scale = SELECTED_SCALE if is_selected else UNSELECTED_SCALE
		var target_alpha = 1.0 if is_selected else UNSELECTED_ALPHA
		cover_node.z_index = 5 - abs(i)

		cover_node.pivot_offset = cover_size / 2.0
		target_pos -= cover_node.pivot_offset

		if use_animation:
			var tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_property(cover_node, "position", target_pos, MOVE_DURATION)
			tween.tween_property(cover_node, "scale", target_scale, MOVE_DURATION)
			tween.tween_property(cover_node, "modulate:a", target_alpha, MOVE_DURATION)
		else:
			cover_node.position = target_pos
			cover_node.scale = target_scale
			cover_node.modulate.a = target_alpha

	_update_difficulty_buttons()
	_play_current_song_preview()
	_update_ui_text()
	_request_neighbor_category_textures()


func _on_texture_loaded(path: String, texture: Texture2D):
	if path_to_cover_map.has(path):
		var cover_node = path_to_cover_map[path]
		if is_instance_valid(cover_node):
			cover_node.set_texture(texture)

func _request_neighbor_category_textures():
	if categories.size() <= 1: return
	
	var next_category_index = wrapi(current_category_index + 1, 0, categories.size())
	var prev_category_index = wrapi(current_category_index - 1, 0, categories.size())
	
	_preload_category_textures(next_category_index)
	_preload_category_textures(prev_category_index)

func _preload_category_textures(category_index: int):
	var category = categories[category_index]
	for song_entry in category.songs:
		var jacket_path = category.path + song_entry.jacket_file
		TextureLoader.request_texture(jacket_path)

func _update_difficulty_buttons():
	for button in difficulty_buttons_container.get_children(): button.queue_free()

	if categories.is_empty() or categories[current_category_index].songs.is_empty(): return
	
	var song_entry = categories[current_category_index].songs[current_song_index]
	var difficulties = song_entry.charts
	if current_difficulty_index >= difficulties.size(): current_difficulty_index = 0

	for i in range(difficulties.size()):
		var diff_data = difficulties[i]
		var button = Button.new()
		button.text = "%s %d" % [diff_data.difficulty, diff_data.level]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): _on_difficulty_selected(i))
		difficulty_buttons_container.add_child(button)
		if i == current_difficulty_index: button.disabled = true

func _update_ui_text():
	options_button.text = tr("UI_OPTIONS")
	back_button.text = tr("UI_BACK")
	match current_mode:
		Mode.SELECT_SONG:
			start_button.text = tr("UI_GAME_START")
		Mode.SELECT_CATEGORY:
			start_button.text = tr("UI_CONFIRM")

func _play_current_song_preview():
	preview_player.stop()
	if categories.is_empty() or categories[current_category_index].songs.is_empty(): return

	var category = categories[current_category_index]
	var song_entry = category.songs[current_song_index]
	var audio_path = category.path + song_entry.audio_file

	if FileAccess.file_exists(audio_path):
		var stream = load(audio_path)
		preview_player.stream = stream
		preview_player.play()
		if song_entry.has("preview_start_ms"):
			preview_player.seek(song_entry.preview_start_ms / 1000.0)
	else:
		printerr("Preview audio file not found at path: ", audio_path)

func _on_category_button_pressed():
	current_mode = Mode.SELECT_CATEGORY
	category_button.modulate = Color.YELLOW
	preview_player.stop()
	_update_display(false)
	_update_ui_text()

# [ --- DEBUGGING PRINT STATEMENTS ADDED --- ]
func _on_start_button_pressed():
	print("[DEBUG] Start button pressed. Current mode: %s" % Mode.keys()[current_mode])
	
	match current_mode:
		Mode.SELECT_SONG:
			print("[DEBUG] Mode is SELECT_SONG.")
			
			if categories.is_empty():
				print("[DEBUG] ERROR: 'categories' array is empty. Returning.")
				return
			
			if categories[current_category_index].songs.is_empty():
				print("[DEBUG] ERROR: Selected category '%s' has no songs. Returning." % categories[current_category_index].name)
				return
			
			print("[DEBUG] Category has songs. Proceeding to load data...")
			
			var category = categories[current_category_index]
			var song_entry = category.songs[current_song_index]
			var chart_entry = song_entry.charts[current_difficulty_index]
			
			if song_entry == null:
				print("[DEBUG] CRITICAL ERROR: 'song_entry' is null. Returning.")
				return
			if chart_entry == null:
				print("[DEBUG] CRITICAL ERROR: 'chart_entry' is null. Returning.")
				return

			print("[DEBUG] Setting GameplayData...")
			GameplayData.selected_song_data = song_db.get(song_entry.song_id, {})
			GameplayData.selected_song_data["audio_path"] = category.path + song_entry.audio_file
			GameplayData.selected_difficulty_data = chart_entry
			GameplayData.selected_difficulty_data["path"] = category.path + chart_entry.file
			
			print("[DEBUG] GameplayData set. Path: %s" % GameplayData.selected_difficulty_data["path"])

			preview_player.stop()
			
			print("[DEBUG] Attempting to change scene to ingame.tscn...")
			get_tree().change_scene_to_file("res://scenes/gameplay/ingame/ingame.tscn")

		Mode.SELECT_CATEGORY:
			print("[DEBUG] Mode is SELECT_CATEGORY. Switching to SONG mode.")
			current_mode = Mode.SELECT_SONG
			category_button.modulate = Color.WHITE
			_update_display(false)
			# [MODIFIED] _update_ui_text() was missing here, which is why the button text didn't update
			_update_ui_text()

# 차트 메타데이터 로드 (charter, is_regular_difficulty)
func _load_chart_metadata(chart_path: String) -> Dictionary:
	var result = {}
	if not FileAccess.file_exists(chart_path):
		return result
	
	var file = FileAccess.open(chart_path, FileAccess.READ)
	if file == null:
		return result
	
	var json_data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if json_data and typeof(json_data) == TYPE_DICTIONARY:
		# 새 포맷: metadata 안에 있음
		if json_data.has("metadata"):
			var metadata = json_data.get("metadata", {})
			result["charter"] = metadata.get("charter", "")
			result["is_regular_difficulty"] = metadata.get("is_regular_difficulty", true)
		# 레거시 포맷: 최상위에 있음
		else:
			result["charter"] = json_data.get("charter", "")
			result["is_regular_difficulty"] = json_data.get("is_regular_difficulty", true)
	
	return result

func _on_difficulty_selected(index: int):
	current_difficulty_index = index
	_update_difficulty_buttons()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_options_button_pressed():
	if ingame_option_popup:
		ingame_option_popup.show()
	else:
		# Fallback to old options menu if popup not found
		if options_menu:
			options_menu.show()
