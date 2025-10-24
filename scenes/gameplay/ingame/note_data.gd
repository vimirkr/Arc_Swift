## [오류 수정]
## class_name은 반드시 extends 바로 다음, 파일 최상단에 선언되어야 합니다.
class_name ParsedNote extends RefCounted

# 노트 종류를 전역 열거형으로 정의
enum NoteType { TAP, LONG, SWIPE }

# 7개 라인을 전역 열거형으로 정의
enum Lane { SIDE_L, MID_1, MID_2, MID_3, MID_4, MID_5, SIDE_R }

# ParsedNote 클래스 본문
var time_ms: float     # 노트의 시작 시간 (밀리초)
var lane: Lane         # 7개 라인 중 하나 (0~6)
var note_type: NoteType # 노트 종류 (TAP, LONG, SWIPE)

# 롱노트/스와이프 전용
var duration_ms: float = 0.0 # 롱노트의 지속 시간
var tick_count: int = 0      # 롱노트의 틱 수
var end_lane: Lane = Lane.MID_3 # 스와이프 노트의 도착 라인 (기본값 설정)
