extends Control

var border_rect: ColorRect
var album_jacket: TextureRect
var title_label: Label
var artist_label: Label
var charter_label: Label

func _ready():
	# 노드 참조 가져오기
	border_rect = $BorderRect
	album_jacket = $InnerMargin/ContentBox/AlbumJacket
	title_label = $InnerMargin/ContentBox/InfoContainer/TitleLabel
	artist_label = $InnerMargin/ContentBox/InfoContainer/ArtistLabel
	charter_label = $InnerMargin/ContentBox/InfoContainer/CharterLabel
	
	# 디버그: 노드가 제대로 로드되었는지 확인
	print("[AlbumCover] _ready called, nodes loaded: ", title_label != null)

# 노래 정보 설정 (제목, 작곡가, 차트 디자이너)
func set_song_data(song_data: Dictionary, chart_data: Dictionary):
	if title_label == null:
		push_error("[AlbumCover] Labels not initialized!")
		return
	
	# 노래 제목 (중앙 상단)
	var title = song_data.get("title", "Unknown Title")
	title_label.text = title
	title_label.visible = true
	print("[AlbumCover] Set title: ", title)
	
	# 작곡가 (중앙 중단, 없으면 숨김)
	var artist = song_data.get("artist", "")
	if artist.is_empty():
		artist_label.visible = false
	else:
		artist_label.text = artist
		artist_label.visible = true
		print("[AlbumCover] Set artist: ", artist)
	
	# 차트 디자이너 (좌하단)
	var charter = chart_data.get("charter", "")
	if charter.is_empty():
		charter_label.visible = false
	else:
		charter_label.text = "Charter: %s" % charter
		charter_label.visible = true
		print("[AlbumCover] Set charter: ", charter)

# 난이도에 따른 테두리 색상 설정
func set_border_color(is_regular: bool):
	if border_rect == null:
		return
	if is_regular:
		border_rect.color = Color.WHITE  # 정규 난이도: 하얀색
	else:
		border_rect.color = Color.BLACK  # 비정규 난이도: 검은색

# 텍스처 설정 (앨범 자켓 이미지)
func set_texture(texture: Texture2D = null):
	if album_jacket == null:
		return
	if texture:
		album_jacket.texture = texture
		album_jacket.modulate = Color.WHITE
	else:
		# 텍스처 없음 (로딩 중이거나 없는 경우, 추후 디폴트 이미지로 대체 예정)
		album_jacket.texture = null
		album_jacket.modulate = Color(1, 1, 1, 0.5)
