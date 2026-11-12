extends Node
## Autoload "Sfx": efeitos sonoros e música.
##
## Os sons ficam em assets/sounds/<nome>.ogg (ou .mp3 / .wav). Um som que não
## exista simplesmente não toca. Variações: <nome>_2, <nome>_3... escolhidas ao acaso.
## A lista de sons e quando tocam está em docs/sons.md.

const DIR := "res://assets/sounds/"
const EXTS := ["ogg", "mp3", "wav"]

## Volume de cada som em dB (0 = como vem do ficheiro).
const VOLUME := {
	"passo_ourico": -6.0, "passo_coelho": -6.0, "passo_raposa": -6.0, "passo_esquilo": -6.0, "passo_voltar": -10.0,
	"nota": -14.0, "chegou": -4.0, "marca": -10.0, "linha": -12.0,
	"desfazer": -8.0, "limpar": -6.0, "dica": -4.0, "errado": -8.0,
	"vitoria": -2.0, "estrela": -6.0, "toque": -12.0, "painel": -12.0,
	"animal_ourico": -4.0, "animal_coelho": -4.0, "animal_raposa": -4.0, "animal_esquilo": -4.0,
	"musica": -16.0, "ambiente": -20.0,
}

## Escala pentatónica maior, em meios-tons: soa sempre bem, por qualquer ordem.
const PENTA := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]

var _cache := {}         # nome -> Array[AudioStream]
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_ambient = AudioStreamPlayer.new()
	add_child(_music)
	add_child(_ambient)


## Toca um efeito. pitch multiplica a altura; jitter varia-a um pouco ao acaso.
func play(name: String, pitch := 1.0, jitter := 0.04, volume_db := 0.0) -> void:
	if not Game.progress.sfx:
		return
	var streams := _streams(name)
	if streams.is_empty():
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = streams.pick_random()
	p.pitch_scale = pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	p.volume_db = VOLUME.get(name, 0.0) + volume_db + randf_range(-1.0, 0.0)
	p.play()


## Nota da escala pentatónica: degree 0 é a nota base, e cada grau sobe.
func note(degree: int, name := "nota") -> void:
	var semis: int = PENTA[clampi(degree, 0, PENTA.size() - 1)]
	play(name, pow(2.0, semis / 12.0), 0.0)


## Passo de um animal: o som do passo e uma nota que sobe com o comprimento do caminho.
func step(animal: String, length: int) -> void:
	play("passo_" + animal)
	note(clampi(length - 2, 0, 8))


## Música e ambiente em ciclo. Chamado ao arrancar e quando muda a definição.
## Pausa a música durante um anúncio (e retoma-a depois).
func pause_music(on: bool) -> void:
	_music.stream_paused = on
	_ambient.stream_paused = on


func refresh_music() -> void:
	_loop(_music, "musica", Game.progress.music)
	_loop(_ambient, "ambiente", Game.progress.music)


func _loop(p: AudioStreamPlayer, name: String, on: bool) -> void:
	var streams := _streams(name)
	if not on or streams.is_empty():
		p.stop()
		return
	if p.playing:
		return
	var s: AudioStream = streams[0]
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	elif "loop" in s:
		s.loop = true  # ogg e mp3
	p.stream = s
	p.volume_db = VOLUME.get(name, 0.0)
	p.play()


func _streams(name: String) -> Array:
	if _cache.has(name):
		return _cache[name]
	var out := []
	for suffix in [""] + range(2, 10).map(func(i): return "_%d" % i):
		var found := false
		for ext in EXTS:
			var path: String = DIR + name + suffix + "." + ext
			if ResourceLoader.exists(path):
				out.append(load(path))
				found = true
				break
		if not found and suffix != "":
			break
	_cache[name] = out
	return out
