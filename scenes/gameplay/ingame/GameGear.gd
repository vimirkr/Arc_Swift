extends Control

@onready var rail_container = $RailContainer
@onready var judgement_line = $JudgementLine

func _ready():
	_setup_rails_for_resolution()

func _setup_rails_for_resolution():
	# 뷰포트 크기 가져오기
	var viewport_size = get_viewport_rect().size
	
	# JudgementLine의 실제 Y 위치 계산
	# JudgementLine은 anchor_top = 1.0, offset_top = -200.0으로 설정됨
	var judgement_line_y = viewport_size.y - 200.0
	
	# Rail 컨테이너의 모든 자식 Rail 노드 설정
	for rail_node in rail_container.get_children():
		if rail_node is Rail:
			# top_y는 0 (화면 맨 위)
			rail_node.top_y = 0.0
			# judge_y는 JudgementLine 위치와 일치
			rail_node.judge_y = judgement_line_y
			# 레일 다시 그리기
			rail_node.queue_redraw()
	
	# Rail 위치도 해상도에 맞게 조정
	_setup_rail_positions()

func _setup_rail_positions():
	# 뷰포트 크기 가져오기
	var viewport_size = get_viewport_rect().size
	
	# 8개의 레일을 화면 너비에 균등 분배
	var rail_count = 8
	var rail_spacing = viewport_size.x / (rail_count - 1)
	
	var rails = rail_container.get_children()
	for i in range(rails.size()):
		if rails[i] is Rail:
			rails[i].position.x = i * rail_spacing
