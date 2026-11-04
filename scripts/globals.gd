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
	"star": Color("f5b82e"),
}

## Os textos (nome, regra, detalhe...) estão em data/traducoes.csv,
## com as chaves NAME_<TIPO>, RULE_<TIPO>, DETAIL_<TIPO>, MEET_<TIPO> e LEAD_<TIPO>.
const ANIMALS := {
	"ourico": {"color": Color("2e8c7e")},
	"coelho": {"color": Color("c2477a")},
	"raposa": {"color": Color("e3801f")},
}

## Nome de cada mundo: chave WORLD_<n> em data/traducoes.csv.
const WORLDS := [
	{"levels": [0, 1, 2, 3, 4, 5]},
	{"levels": [6, 7, 8, 9, 10, 11]},
]

## Línguas do jogo (código -> nome na própria língua). Para juntar uma,
## acrescenta a coluna em data/traducoes.csv e o ficheiro em project.godot.
const LANGS := {"pt": "Português", "en": "English", "es": "Español", "fr": "Français", "de": "Deutsch"}

var levels: Array = []
## done: índice (texto) -> {"t": melhor tempo em s, "s": melhores estrelas}
## lang: "" segue a língua do telemóvel
var progress := {"done": {}, "seen": [], "vibrate": true, "lang": ""}
var current := 0


func _ready() -> void:
	var f := FileAccess.open("res://data/levels.json", FileAccess.READ)
	levels = JSON.parse_string(f.get_as_text())
	_load()
	_apply_language()


# ---------- línguas ----------

## Língua em uso ("pt", "en", ...).
func language() -> String:
	if progress.lang in LANGS:
		return progress.lang
	var os_lang := OS.get_locale_language()
	return os_lang if os_lang in LANGS else "en"


func set_language(code: String) -> void:
	progress.lang = code
	_save()
	_apply_language()


func _apply_language() -> void:
	TranslationServer.set_locale(language())


## Texto de um animal: field é "NAME", "RULE", "DETAIL", "MEET" ou "LEAD".
func animal_text(t: String, field: String) -> String:
	return tr("%s_%s" % [field, t.to_upper()])


func level_name(i: int) -> String:
	return tr("LEVEL_NAME_%d" % (i + 1))


func world_name(w: int) -> String:
	return tr("WORLD_%d" % (w + 1))


## Imagem com texto na língua atual: procura <name>_<língua>.png (ex.: logo_pt).
func texture_localized(name: String) -> Texture2D:
	return texture("%s_%s" % [name, TranslationServer.get_locale().left(2)])


var _textures := {}  # nome -> Texture2D ou null


## Imagem de assets/images/<name>.png, ou null se não existir.
## Fica guardada: uma textura carregada só dentro de um _draw() era libertada
## logo a seguir e aparecia como um quadrado branco.
func texture(name: String) -> Texture2D:
	if not _textures.has(name):
		var path := "res://assets/images/%s.png" % name
		_textures[name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[name]


func is_done(i: int) -> bool:
	return progress.done.has(str(i))


## Um nível está aberto se for o primeiro ou se o anterior estiver resolvido.
func is_unlocked(i: int) -> bool:
	return i == 0 or is_done(i - 1) or is_done(i)


func best_time(i: int) -> float:
	return float(progress.done.get(str(i), {}).get("t", 0.0))


func stars(i: int) -> int:
	return int(progress.done.get(str(i), {}).get("s", 0))


## Estrelas por nível: 3 sem dicas, 2 com uma, 1 com mais.
static func stars_for(hints_used: int) -> int:
	return clampi(3 - hints_used, 1, 3)


func total_stars() -> int:
	var n := 0
	for k in progress.done:
		n += int(progress.done[k].get("s", 0))
	return n


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


## Guarda o resultado. Devolve true se for um novo recorde de tempo.
func mark_done(i: int, seconds: float, got_stars: int) -> bool:
	var k := str(i)
	var prev: Dictionary = progress.done.get(k, {})
	var record := prev.is_empty() or seconds < float(prev.get("t", INF))
	progress.done[k] = {
		"t": seconds if record else float(prev.t),
		"s": maxi(got_stars, int(prev.get("s", 0))),
	}
	_save()
	return record and not prev.is_empty()


func has_seen(animal_type: String) -> bool:
	return animal_type in progress.seen


func mark_seen(animal_type: String) -> void:
	if not has_seen(animal_type):
		progress.seen.append(animal_type)
		_save()


func set_vibrate(on: bool) -> void:
	progress.vibrate = on
	_save()


func vibrate(ms: int) -> void:
	if progress.vibrate:
		Input.vibrate_handheld(ms)


func reset_progress() -> void:
	progress.done = {}
	progress.seen = []
	_save()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (data is Dictionary):
		return
	var done = data.get("done", {})
	if done is Dictionary:
		for k in done:
			# formato antigo: só o tempo
			var v = done[k]
			progress.done[k] = v if v is Dictionary else {"t": float(v), "s": 3}
	var seen = data.get("seen", [])
	if seen is Array:
		progress.seen = seen
	progress.vibrate = bool(data.get("vibrate", true))
	progress.lang = str(data.get("lang", ""))


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(progress))


static func format_time(s: float) -> String:
	var t := int(s)
	return "%d:%02d" % [int(t / 60.0), t % 60]
