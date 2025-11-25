extends Control

# UI 노드 참조
@onready var grade_label = $MainLayout/VBoxContainer/MiddleSection/LeftPanel/GradeLabel
@onready var rate_label = $MainLayout/VBoxContainer/MiddleSection/LeftPanel/RateLabel
@onready var ultimate_label = $MainLayout/VBoxContainer/MiddleSection/RightPanel/UltimateLabel
@onready var perfect_label = $MainLayout/VBoxContainer/MiddleSection/RightPanel/PerfectLabel
@onready var great_label = $MainLayout/VBoxContainer/MiddleSection/RightPanel/GreatLabel
@onready var good_label = $MainLayout/VBoxContainer/MiddleSection/RightPanel/GoodLabel
@onready var miss_label = $MainLayout/VBoxContainer/MiddleSection/RightPanel/MissLabel
@onready var fast_label = $MainLayout/VBoxContainer/MiddleSection/RightPanel/FastLabel
@onready var slow_label = $MainLayout/VBoxContainer/MiddleSection/RightPanel/SlowLabel
@onready var result_title = $MainLayout/VBoxContainer/TopSection/ResultTitle
@onready var press_any_key_label = $MainLayout/VBoxContainer/BottomSection/PressAnyKeyLabel

# 결과 데이터
var result_data: Dictionary

func _ready():
	# GameplayData에서 결과 데이터 로드
	result_data = GameplayData.result_data
	
	# 현지화 적용
	result_title.text = tr("UI_RESULT")
	press_any_key_label.text = tr("UI_PRESS_ANY_KEY")
	
	# UI 업데이트
	_update_ui()
	
	print("[Result] Result screen loaded. Rate: %.2f%%" % result_data.get("rate_percentage", 0.0))

func _update_ui():
	# 판정 레이트 계산 및 등급 결정
	var rate = result_data.get("rate_percentage", 0.0)
	var judgement_counts = result_data.get("judgement_counts", {})
	var miss_count = judgement_counts.get("miss", 0)
	
	# 등급 계산
	var grade = _calculate_grade(rate, miss_count, judgement_counts)
	grade_label.text = grade
	
	# 등급별 색상 설정
	match grade:
		"AP":
			grade_label.add_theme_color_override("font_color", Color(1, 1, 0))  # 금색
		"FC":
			grade_label.add_theme_color_override("font_color", Color(0, 1, 1))  # 청록색
		"P":
			grade_label.add_theme_color_override("font_color", Color(0, 1, 0))  # 초록색
		"F":
			grade_label.add_theme_color_override("font_color", Color(1, 0, 0))  # 빨간색
	
	# 판정 퍼센트 표기
	rate_label.text = tr("UI_RATE") + ": %.2f%%" % rate
	
	# 판정 현황 표기
	ultimate_label.text = tr("UI_JUDGEMENT_ULTIMATE") + ": %d" % judgement_counts.get("ultimate", 0)
	perfect_label.text = tr("UI_JUDGEMENT_PERFECT") + ": %d" % judgement_counts.get("perfect", 0)
	great_label.text = tr("UI_JUDGEMENT_GREAT") + ": %d" % judgement_counts.get("great", 0)
	good_label.text = tr("UI_JUDGEMENT_GOOD") + ": %d" % judgement_counts.get("good", 0)
	miss_label.text = tr("UI_JUDGEMENT_MISS") + ": %d" % miss_count
	
	# Fast/Slow 카운트 표기
	fast_label.text = tr("UI_FAST") + ": %d" % result_data.get("fast_count", 0)
	slow_label.text = tr("UI_SLOW") + ": %d" % result_data.get("slow_count", 0)

func _calculate_grade(rate: float, miss_count: int, judgement_counts: Dictionary) -> String:
	# AP: 100% 판정 퍼센트
	if rate >= 100.0:
		return "AP"
	
	# FC: Miss 없이 Full Combo
	if miss_count == 0:
		return "FC"
	
	# P: 80% 이상
	if rate >= 80.0:
		return "P"
	
	# F: 80% 미만
	return "F"

func _input(event):
	# 아무 키나 입력 시 노래 선택 화면으로 이동
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			_return_to_select_song()

func _return_to_select_song():
	print("[Result] Returning to select song screen...")
	get_tree().change_scene_to_file("res://scenes/gameplay/select_song/select_song.tscn")
