# res://globals/GameplayData.gd
extends Node

# 인게임 씬에 전달할 데이터를 저장할 변수들
var selected_song_data: Dictionary
var selected_difficulty_data: Dictionary

# 리절트 씬에 전달할 결과 데이터
var result_data: Dictionary = {
	"rate_percentage": 0.0,
	"judgement_counts": {
		"ultimate": 0,
		"perfect": 0,
		"great": 0,
		"good": 0,
		"miss": 0
	},
	"fast_count": 0,
	"slow_count": 0,
	"total_notes": 0,
	"max_combo": 0
}
