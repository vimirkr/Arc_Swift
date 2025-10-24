# res://globals/TextureLoader.gd
extends Node

# 시그널: 텍스처 로딩이 완료되면 경로와 결과물을 함께 보냅니다.
signal texture_loaded(path, texture)

# 캐시: 로드된 텍스처를 저장합니다. [경로: 텍스처] 형태의 딕셔너리입니다.
var cache: Dictionary = {}
# 요청 큐: 로드해야 할 텍스처 경로들을 저장하는 배열입니다.
var request_queue: Array = []
# 중복 요청 방지용: 현재 큐에 있거나 처리 중인 경로를 저장합니다.
var pending_requests: Dictionary = {}

var thread: Thread
var mutex: Mutex = Mutex.new()
var semaphore: Semaphore = Semaphore.new()

func _ready():
	# 백그라운드 스레드를 생성하고 시작합니다.
	thread = Thread.new()
	thread.start(_thread_function)

func _exit_tree():
	# 게임 종료 시 스레드를 안전하게 정리합니다.
	request_queue.clear()
	semaphore.post()
	thread.wait_to_finish()

# 외부에서 텍스처를 요청할 때 호출하는 함수입니다.
func request_texture(path: String):
	mutex.lock()
	# 이미 캐시에 있거나, 이미 요청된 텍스처는 무시합니다.
	if cache.has(path) or pending_requests.has(path):
		mutex.unlock()
		return
	
	# 새로운 요청을 큐와 중복 방지 목록에 추가합니다.
	request_queue.push_back(path)
	pending_requests[path] = true
	mutex.unlock()
	
	# 스레드에게 새로운 작업이 있음을 알립니다.
	semaphore.post()

# 백그라운드 스레드에서 실행될 메인 함수입니다.
func _thread_function():
	while true:
		# 새로운 작업이 들어올 때까지 대기합니다.
		semaphore.wait()

		mutex.lock()
		if request_queue.is_empty():
			mutex.unlock()
			# 게임이 종료되는 경우를 대비한 탈출 조건입니다.
			if not thread.is_alive(): break
			continue
		
		# 큐에서 작업할 경로를 하나 꺼냅니다.
		var path = request_queue.pop_front()
		mutex.unlock()

		# ImageLoader를 사용해 파일을 읽고 텍스처를 생성합니다.
		var image = Image.load_from_file(path)
		if image:
			var texture = ImageTexture.create_from_image(image)
			# 결과를 메인 스레드로 안전하게 전달하기 위해 call_deferred를 사용합니다.
			call_deferred("_on_load_completed", path, texture)
		else:
			call_deferred("_on_load_completed", path, null)


func _on_load_completed(path: String, texture: Texture2D):
	mutex.lock()
	# 로딩이 완료되었으니 중복 방지 목록에서 제거합니다.
	pending_requests.erase(path)
	if texture:
		# 성공 시 캐시에 저장합니다.
		cache[path] = texture
	mutex.unlock()
	
	# 로딩 완료 시그널을 발생시켜 select_song 씬에 알립니다.
	texture_loaded.emit(path, texture)
