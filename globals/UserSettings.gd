# res://globals/UserSettings.gd
extends Node

# --- Colorblind Mode ---
enum ColorMode { DEFAULT, DEUTERANOPIA, TRITANOPIA }
var current_color_mode = ColorMode.DEFAULT
const PALETTES = {
	ColorMode.DEFAULT: {"side1": Color.BLUE, "side2": Color.MAGENTA, "center1": Color.YELLOW, "center2": Color.LIME_GREEN, "double": Color.PURPLE},
	ColorMode.DEUTERANOPIA: {"side1": Color.BLUE, "side2": Color.ORANGE, "center1": Color.SKY_BLUE, "center2": Color.WHITE, "double": Color.TEAL},
	ColorMode.TRITANOPIA: {"side1": Color.RED, "side2": Color.ORANGE, "center1": Color.TEAL, "center2": Color.WHITE, "double": Color.LIGHT_GRAY}
}
func set_color_mode(mode: ColorMode): current_color_mode = mode
func get_note_color(note_type: String) -> Color: return PALETTES[current_color_mode][note_type]

# --- Low Specification Mode ---
var low_spec_mode_on = false
func set_low_spec_mode(is_on: bool): low_spec_mode_on = is_on

# --- Gameplay Settings ---
enum GameplayEffect { NONE, MIRROR, FADE_IN, FADE_OUT }
enum JudgementDisplayMode { ALL_EXCEPT_ULTIMATE, BELOW_PERFECT, HIDE, OFF }
enum CenterDisplayType { SCORE, COMBO, SUDDEN_COUNT, OFF }

# Scroll Speed: 1.0 ~ 10.0 (0.1 단위, 기본값: 5.0)
# 작동 원리: visible_time_range_ms = 3000.0 / scroll_speed (Time = Constant / Speed)
# 노트가 화면 최상단에서 판정선까지 내려오는데 걸리는 시간(ms)을 결정
# 예: 1.0배속 = 3000ms(3초), 5.0배속 = 600ms(0.6초), 10.0배속 = 300ms(0.3초)
var scroll_speed: float = 5.0

# Effect: NONE, MIRROR, FADE_IN, FADE_OUT
# MIRROR: 레인 인덱스를 좌우 반전 (SIDE_L↔SIDE_R, MID_1↔MID_5, MID_2↔MID_4, MID_3은 그대로)
# FADE_IN/OUT: 옵션 선택만 가능, 실제 쉐이더 구현은 추후
var gameplay_effect: GameplayEffect = GameplayEffect.NONE

# Judgement Display Mode: 판정 라벨 표시 방식
# ALL_EXCEPT_ULTIMATE: Ultimate 제외하고 모두 표시
# BELOW_PERFECT: Perfect 미만만 표시
# HIDE: 판정은 처리하지만 표시 안함
# OFF: 판정 자체를 끔
var judgement_display_mode: JudgementDisplayMode = JudgementDisplayMode.ALL_EXCEPT_ULTIMATE

# Audio/Visual Offset: -500ms ~ +500ms (기본값: 0)
var audio_offset_ms: int = 0

# Sudden Death: 활성화 여부
var is_sudden_death_on: bool = false

# Sudden Death Limit: 1, 10, 100 중 하나 (기본값: 10)
var sudden_death_limit: int = 10

# Center Display Info: 판정선 위에 표시될 정보
# 우선순위 로직: is_sudden_death_on이 true인 경우, 강제로 SUDDEN_COUNT 표시
var center_display_type: CenterDisplayType = CenterDisplayType.COMBO

# Note FX Brightness: 0.0 ~ 1.0 (UI만 구현)
var note_fx_brightness: float = 1.0

# Scroll Speed 계산 함수
func get_visible_time_range_ms() -> float:
	return 3000.0 / scroll_speed

# Mirror Effect 적용 함수 (레인 인덱스 변환)
# GlobalEnums.Lane enum 값을 받아 미러링된 레인 반환
func apply_mirror_to_lane(lane: int) -> int:
	if gameplay_effect != GameplayEffect.MIRROR:
		return lane
	
	# GlobalEnums.Lane: SIDE_L=0, MID_1=1, MID_2=2, MID_3=3, MID_4=4, MID_5=5, SIDE_R=6
	match lane:
		0: return 6  # SIDE_L ↔ SIDE_R
		1: return 5  # MID_1 ↔ MID_5
		2: return 4  # MID_2 ↔ MID_4
		3: return 3  # MID_3 (그대로)
		4: return 2  # MID_4 ↔ MID_2
		5: return 1  # MID_5 ↔ MID_1
		6: return 0  # SIDE_R ↔ SIDE_L
		_: return lane

# 실제 표시할 Center Display 타입 반환 (Sudden Death 우선순위 적용)
func get_active_center_display_type() -> CenterDisplayType:
	if is_sudden_death_on:
		return CenterDisplayType.SUDDEN_COUNT
	return center_display_type

# --- Audio Volume Settings ---
var master_volume: float = 10.0
var music_volume: float = 10.0
var sfx_volume: float = 10.0
var ui_volume: float = 10.0

# [FINAL CORRECTED VERSION]
# Helper function to convert linear volume (0-10) to decibels (-80 to 0)
static func linear_to_db_custom(linear_val: float) -> float:
	if linear_val <= 0:
		return -80.0
	# Use the global scope linear_to_db function, which is correct for Godot 4.x
	# The function name is NOT linear2db.
	return linear_to_db(linear_val / 10.0)

static func set_bus_volume(bus_name: String, linear_val: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		# Use the corrected custom function name
		AudioServer.set_bus_volume_db(bus_index, linear_to_db_custom(linear_val))

func set_master_volume(value: float):
	master_volume = value
	set_bus_volume("Master", value)

func set_music_volume(value: float):
	music_volume = value
	set_bus_volume("Music", value)

func set_sfx_volume(value: float):
	sfx_volume = value
	set_bus_volume("SFX", value)

func set_ui_volume(value: float):
	ui_volume = value
	set_bus_volume("UI", value)
