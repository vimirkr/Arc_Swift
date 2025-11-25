extends Control

@onready var tab_container = $TabContainer
@onready var recent_list_container = $TabContainer/Recent/ScrollContainer/VBoxContainer
@onready var summary_tab = $TabContainer/Summary
@onready var song_score_tab = $"TabContainer/Song Score"
@onready var back_button = $BackButton # NEW: Add reference to the back button

const RecentPlayEntry = preload("res://scenes/ui/user_profile/recent_play_entry.tscn")

func _ready():
	tab_container.tab_changed.connect(_on_tab_changed)
	_populate_summary_tab()
	_update_ui_text() # NEW: Update button text on ready

func _input(event):
	if event.is_action_pressed("ui_focus_next"):
		tab_container.current_tab = (tab_container.current_tab + 1) % tab_container.get_tab_count()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("ui_focus_prev"):
		tab_container.current_tab = (tab_container.current_tab - 1 + tab_container.get_tab_count()) % tab_container.get_tab_count()
		get_viewport().set_input_as_handled()

func _on_tab_changed(tab_index: int):
	match tab_index:
		0:
			_populate_summary_tab()
		1:
			_populate_recent_tab()
		2:
			_populate_song_score_tab()

func _populate_summary_tab():
	# 미구현 표시 - Summary 탭에 직접 라벨 추가
	if not summary_tab:
		return
	
	for child in summary_tab.get_children():
		child.queue_free()
	
	var not_impl_label = Label.new()
	not_impl_label.text = tr("UI_PROFILE_NOT_IMPLEMENTED")
	not_impl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	not_impl_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	not_impl_label.anchors_preset = Control.PRESET_FULL_RECT
	summary_tab.add_child(not_impl_label)

func _populate_recent_tab():
	for child in recent_list_container.get_children():
		child.queue_free()
	
	if ProfileData.player_data.recent_plays.is_empty():
		var no_data_label = Label.new()
		no_data_label.text = tr("UI_NO_RECENT_PLAYS")
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recent_list_container.add_child(no_data_label)
		return

	for play_data in ProfileData.player_data.recent_plays:
		var entry = RecentPlayEntry.instantiate()
		
		entry.get_node("VBoxContainer/HBoxContainer/SongTitleLabel").text = play_data.song_id
		
		var grid = entry.get_node("VBoxContainer/HBoxContainer/GridContainer")
		grid.get_node("ScoreLabel").text = tr("UI_SCORE") + ": %d" % play_data.score
		grid.get_node("RankLabel").text = tr("UI_RANK") + ": %s" % play_data.rank
		grid.get_node("ComboLabel").text = tr("UI_MAX_COMBO") + ": %d/%d" % [play_data.max_combo, play_data.total_notes]
		grid.get_node("PercentLabel").text = tr("UI_PERCENT") + ": %.2f%%" % play_data.judgement_percent
		grid.get_node("FastSlowLabel").text = tr("UI_FAST") + ": %d / " + tr("UI_SLOW") + ": %d" % [play_data.fast_slow.fast, play_data.fast_slow.slow]
		grid.get_node("RatingLabel").text = tr("UI_RATING") + ": ---"
		
		var jd = play_data.judgements
		var judgement_text = tr("UI_JUDGEMENTS") + " | " + tr("UI_JUDGEMENT_ULTIMATE") + ": %d / " + tr("UI_JUDGEMENT_PERFECT") + ": %d / " + tr("UI_JUDGEMENT_GREAT") + ": %d / " + tr("UI_JUDGEMENT_GOOD") + ": %d / " + tr("UI_JUDGEMENT_MISS") + ": %d" % [jd.ultimate, jd.perfect, jd.great, jd.good, jd.miss]
		entry.get_node("VBoxContainer/JudgementCountsLabel").text = judgement_text
		
		recent_list_container.add_child(entry)

func _populate_song_score_tab():
	# 미구현 표시 - Song Score 탭에 직접 라벨 추가
	if not song_score_tab:
		return
	
	for child in song_score_tab.get_children():
		child.queue_free()
	
	var not_impl_label = Label.new()
	not_impl_label.text = tr("UI_PROFILE_NOT_IMPLEMENTED")
	not_impl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	not_impl_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	not_impl_label.anchors_preset = Control.PRESET_FULL_RECT
	song_score_tab.add_child(not_impl_label)

func _update_ui_text(): # NEW: Function to update translatable text
	back_button.text = tr("UI_BACK")

# --- NEW: Signal callback for the back button ---
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
