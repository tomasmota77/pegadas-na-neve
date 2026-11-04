extends Node
## Autoload "Game": níveis, progresso guardado e informação dos animais.

const SAVE_PATH := "user://save.json"
const HINTS_PER_LEVEL := 3

const COLORS := {
	"sky": Color("e7eff6"),
	"ink": Color("20304a"),
	"ink_soft": Color("5d6f89"),
	"snow": Color("ffffff"),
	"frost": Color("cfdce8"),
	"frost_dark": Color("a9bccf"),
	"ok": Color("3e9a5e"),
	"bad": Color("d9534f"),
}

const ANIMALS := {
	"ourico": {
		"name": "Ouriço", "rule": "Anda 1 casa", "color": Color("2e8c7e"),
		"detail": "Anda 1 casa de cada vez: para cima, para baixo ou para os lados.",
	},
	"coelho": {
		"name": "Coelho", "rule": "Salta 2 casas", "color": Color("c2477a"),
		"detail": "Salta sempre 2 casas em linha reta, por cima do que estiver no meio, até de rochas.",
	},
	"raposa": {
		"name": "Raposa", "rule": "Anda na diagonal", "color": Color("e3801f"),
		"detail": "Anda 1 casa na diagonal. O caminho dela não se pode cruzar em X.",
	},
}

const WORLDS := [
	{"name": "Clareira", "levels": [0, 1, 2, 3, 4, 5]},
	{"name": "Bosque", "levels": [6, 7, 8, 9, 10, 11]},
]

var levels: Array = []
var progress := {"done": {}, "seen": []}  # done: índice -> melhor tempo (s)
var current := 0


func _ready() -> void:
	var f := FileAccess.open("res://data/levels.json", FileAccess.READ)
	levels = JSON.parse_string(f.get_as_text())
	_load()


func texture(name: String) -> Texture2D:
	var path := "res://assets/images/%s.png" % name
	return load(path) if ResourceLoader.exists(path) else null


func is_done(i: int) -> bool:
	return progress.done.has(str(i))


func best_time(i: int) -> float:
	return float(progress.done.get(str(i), 0.0))


func first_unsolved() -> int:
	for i in levels.size():
		if not is_done(i):
			return i
	return levels.size() - 1


func world_of(i: int) -> int:
	for w in WORLDS.size():
		if i in WORLDS[w].levels:
			return w
	return 0


func mark_done(i: int, seconds: float) -> void:
	var k := str(i)
	if not progress.done.has(k) or seconds < float(progress.done[k]):
		progress.done[k] = seconds
	_save()


func has_seen(animal_type: String) -> bool:
	return animal_type in progress.seen


func mark_seen(animal_type: String) -> void:
	if not has_seen(animal_type):
		progress.seen.append(animal_type)
		_save()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		progress.done = data.get("done", {})
		progress.seen = data.get("seen", [])


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(progress))


static func format_time(s: float) -> String:
	var t := int(s)
	return "%d:%02d" % [int(t / 60.0), t % 60]
