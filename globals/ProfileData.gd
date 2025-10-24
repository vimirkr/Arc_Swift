extends Node

const SAVE_PATH = "user://profile.json"
const MAX_RECENT_PLAYS = 20

var player_data = {
	"songs": {},
	"recent_plays": []
}

func _ready():
	load_profile()

func save_profile():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(player_data, "\t")
		file.store_string(json_string)
		file.close()

func load_profile():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parse_result = JSON.parse_string(json_string)
		if parse_result != null:
			player_data = parse_result
		file.close()

# A simple function to determine rank based on judgement percentage.
func _calculate_rank(percent: float) -> String:
	if percent >= 99.0:
		return "EX"
	elif percent >= 97.0:
		return "S"
	elif percent >= 95.0:
		return "A"
	elif percent >= 90.0:
		return "B"
	elif percent >= 80.0:
		return "C"
	else:
		return "D"

# This is the main function the result screen will call.
func update_play_record(song_id: String, difficulty: String, new_record: Dictionary):
	# Add rank to the new record before saving.
	new_record["rank"] = _calculate_rank(new_record.judgement_percent)

	# 1. Update song-specific data
	if not player_data.songs.has(song_id):
		player_data.songs[song_id] = {
			"best_scores": { "easy": null, "normal": null, "hard": null },
			"play_counts": { "easy": 0, "normal": 0, "hard": 0 }
		}
	
	# Update play count
	player_data.songs[song_id].play_counts[difficulty] += 1

	# Check and update best score
	var current_best = player_data.songs[song_id].best_scores[difficulty]
	if current_best == null or new_record.score > current_best.score:
		player_data.songs[song_id].best_scores[difficulty] = new_record
	
	# 2. Add to recent plays
	var recent_play_data = new_record.duplicate(true)
	recent_play_data["song_id"] = song_id
	recent_play_data["difficulty"] = difficulty
	recent_play_data["timestamp"] = Time.get_unix_time_from_system()
	
	player_data.recent_plays.push_front(recent_play_data)
	
	if player_data.recent_plays.size() > MAX_RECENT_PLAYS:
		player_data.recent_plays.pop_back()

	# 3. Save everything to the file
	save_profile()
