@tool
extends Node2D
class_name Rail

# [해상도 독립적] GameGear.gd에서 동적으로 설정됨
@export var top_y: float = 0.0
@export var judge_y: float = 1080.0  # 기본값 (런타임에서 덮어씀)

# [NEW] 레일 색상 및 표시 여부를 에디터에서 조절
@export var draw_enabled: bool = true
@export var draw_color: Color = Color(1.0, 1.0, 1.0, 0.5) # 반투명 흰색

func _draw():
	if not draw_enabled:
		return
	# [MODIFIED] Color.RED 대신 draw_color 사용
	draw_line(Vector2(0, top_y), Vector2(0, judge_y), draw_color, 2.0)

# [MODIFIED] ingame.gd와 NoteObject.gd가 호출하는 헬퍼 함수들
func get_global_top_y() -> float:
	return global_position.y + top_y

func get_global_judge_y() -> float:
	return global_position.y + judge_y

# [REMOVED] get_global_x() 함수를 제거 (잘못된 접근 방식)
