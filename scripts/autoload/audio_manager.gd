extends Node
## Глобальный менеджер аудио — управляет музыкой и звуковыми эффектами

# Бусы аудио
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

# Пути к звуковым файлам
const MUSIC_PATH: String = "res://sounds/music.mp3"
const SFX_DAMAGE_PATH: String = "res://sounds/damage.mp3"
const SFX_KILL_BOSS_PATH: String = "res://sounds/KillBoss.mp3"

# AudioStreamPlayer для музыки (2D-независимый)
var _music_player: AudioStreamPlayer
var _sfx_damage_player: AudioStreamPlayer
var _sfx_kill_boss_player: AudioStreamPlayer

# Сохранённые значения громкости (0.0 - 1.0)
var music_volume: float = 0.8
var sfx_volume: float = 1.0

func _ready() -> void:
	_setup_buses()
	_setup_players()
	_load_settings()
	play_music()

func _setup_buses() -> void:
	# Создаём шину Music, если её нет
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, MUSIC_BUS)
		AudioServer.set_bus_send(idx, "Master")

	# Создаём шину SFX, если её нет
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, SFX_BUS)
		AudioServer.set_bus_send(idx, "Master")

func _setup_players() -> void:
	# Плеер музыки
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	var music_stream = _load_stream(MUSIC_PATH)
	if music_stream:
		# Включаем нативное зацикливание MP3
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		elif music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
		_music_player.stream = music_stream
		# Запасной вариант через сигнал
		_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	# Плеер звука урона
	_sfx_damage_player = AudioStreamPlayer.new()
	_sfx_damage_player.bus = SFX_BUS
	_sfx_damage_player.stream = _load_stream(SFX_DAMAGE_PATH)
	add_child(_sfx_damage_player)

	# Плеер звука убийства босса
	_sfx_kill_boss_player = AudioStreamPlayer.new()
	_sfx_kill_boss_player.bus = SFX_BUS
	_sfx_kill_boss_player.stream = _load_stream(SFX_KILL_BOSS_PATH)
	add_child(_sfx_kill_boss_player)

func _load_stream(path: String) -> AudioStream:
	# Прямая загрузка — ResourceLoader.exists() не работает для
	# файлов, добавленных после последнего импорта редактора
	var stream = load(path)
	if stream == null:
		push_error("AudioManager: не удалось загрузить — " + path + ". Откройте редактор Godot, чтобы файлы импортировались.")
	return stream

## Запустить фоновую музыку (зациклено)
func play_music() -> void:
	if _music_player and _music_player.stream:
		_music_player.play()

func _on_music_finished() -> void:
	# Запасной вариант зацикливания (если loop не поддерживается форматом)
	if _music_player:
		_music_player.play()

## Воспроизвести звук получения урона
func play_damage() -> void:
	if _sfx_damage_player and _sfx_damage_player.stream:
		_sfx_damage_player.stop()
		_sfx_damage_player.play()

## Воспроизвести звук убийства босса
func play_kill_boss() -> void:
	if _sfx_kill_boss_player and _sfx_kill_boss_player.stream:
		_sfx_kill_boss_player.stop()
		_sfx_kill_boss_player.play()

## Установить громкость музыки (0.0 - 1.0)
func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))
	# Обновляем значение в GameManager для последующего сохранения
	GameManager.audio_music_volume = music_volume

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))
	# Обновляем значение в GameManager для последующего сохранения
	GameManager.audio_sfx_volume = sfx_volume

## Получить текущую громкость музыки (0.0 - 1.0)
func get_music_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return music_volume

## Получить текущую громкость SFX (0.0 - 1.0)
func get_sfx_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return sfx_volume

## Загрузить настройки из GameManager
func _load_settings() -> void:
	music_volume = GameManager.audio_music_volume
	sfx_volume = GameManager.audio_sfx_volume
	var music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_idx != -1:
		AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(music_volume))
	var sfx_bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_bus_idx != -1:
		AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(sfx_volume))
