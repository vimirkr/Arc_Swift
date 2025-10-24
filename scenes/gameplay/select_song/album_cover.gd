extends Control

@onready var title_label = $Outline/InfoBox/TitleLabel
@onready var artist_bpm_label = $Outline/InfoBox/ArtistBpmLabel
@onready var album_jacket = $Outline/InfoBox/Album_Jacket
@onready var outline = $Outline

# 텍스트 정보만 설정하는 함수
func set_info(song_data: Dictionary):
	await ready
	title_label.text = song_data.get("title", "Unknown Title")
	artist_bpm_label.text = "%s / BPM: %s" % [song_data.get("artist", "Unknown"), song_data.get("bpm_string", "---")]

# 텍스처를 설정하거나 로딩 상태로 만드는 함수
func set_texture(texture: Texture2D = null):
	await ready
	if texture:
		album_jacket.texture = texture
		album_jacket.modulate = Color.WHITE # 로딩 후 원래 색상으로
	else:
		# 텍스처가 없으면 (로딩 중이거나 실패 시) 반투명하게 만듭니다.
		album_jacket.texture = null
		album_jacket.modulate = Color(1, 1, 1, 0.5)
