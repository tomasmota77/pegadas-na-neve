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
	"accent": Color("f2962c"),   # botão principal (laranja quente)
	"accent2": Color("8ea8ea"),  # botão secundário (azul suave)
}

## Os textos (nome, regra, detalhe...) estão em data/traducoes.csv,
## com as chaves NAME_<TIPO>, RULE_<TIPO>, DETAIL_<TIPO>, MEET_<TIPO> e LEAD_<TIPO>.
const ANIMALS := {
	"ourico": {"color": Color("2e8c7e")},
	"coelho": {"color": Color("c2477a")},
	"raposa": {"color": Color("e3801f")},
	"esquilo": {"color": Color("7b5cc4")},
}

## Mundos, montados a partir do campo "world" de cada nível em data/levels.json:
## [{"levels": [índices]}, ...]. Nome de cada mundo: chave WORLD_<n> em data/traducoes.csv.
var WORLDS: Array = []

## Versão do ficheiro de gravação.
## 2: os níveis do Bosque passaram de 6-11 para 12-17 (a Clareira ganhou mais 6 níveis).
## 3: o progresso passou a ser guardado pelo id do nível em vez do número.
const SAVE_VERSION := 3

## Ordem dos níveis na versão 2 (número -> id), para converter gravações antigas.
const LEGACY_ORDER_V2 := ["Primeiros passos", "Caracol", "Salto a salto", "Vizinhos", "Trilhos cruzados",
	"Neve funda", "c07", "c08", "c09", "c10", "c11", "c12", "Passo de raposa", "Entre rochas",
	"Por cima das pedras", "Três trilhos", "Bosque cerrado", "Tempestade", "b07", "b08", "b09", "b10",
	"b11", "b12", "l01", "l02", "l03", "l04", "l05", "l06", "l07", "l08", "l09", "l10", "l11", "l12",
	"m01", "m02", "m03", "m04", "m05", "m06", "m07", "m08", "m09", "m10", "m11", "m12",
	"n01", "n02", "n03", "n04", "n05", "n06", "n07", "n08", "n09", "n10", "n11", "n12"]

## Línguas do jogo (código -> nome na própria língua). Para juntar uma,
## acrescenta a coluna em data/traducoes.csv e o ficheiro em project.godot.
const LANGS := {"pt": "Português", "en": "English", "es": "Español", "fr": "Français", "de": "Deutsch"}

var levels: Array = []
## done: índice (texto) -> {"t": melhor tempo em s, "s": melhores estrelas}
## lang: "" segue a língua do telemóvel
var progress := {"done": {}, "seen": [], "vibrate": true, "lang": "", "music": true, "sfx": true}
var current := 0


func _ready() -> void:
	var f := FileAccess.open("res://data/levels.json", FileAccess.READ)
	levels = JSON.parse_string(f.get_as_text())
	WORLDS.clear()
	for i in levels.size():
		var w := int(levels[i].get("world", 1)) - 1
		while WORLDS.size() <= w:
			WORLDS.append({"levels": []})
		WORLDS[w].levels.append(i)
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


## Nível especial: "hard" (Difícil, a meio de cada mundo), "super" (Super difícil,
## a fechar o mundo) ou "" (normal). Vem do campo "tag" de data/levels.json.
func level_tag(i: int) -> String:
	return str(levels[i].get("tag", ""))


const TAG_COLORS := {"hard": Color("f08a24"), "super": Color("d9434f")}


## Nome mostrado por baixo de "Nível N": o nome do mundo.
func level_name(i: int) -> String:
	return world_name(world_of(i))


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


## O progresso é guardado pelo id do nível (não pelo número), para que mudar a
## ordem ou juntar níveis não baralhe o que o jogador já resolveu.
func level_id(i: int) -> String:
	return str(levels[i].get("id", i))


func is_done(i: int) -> bool:
	return progress.done.has(level_id(i))


## Um nível está aberto se for o primeiro ou se o anterior estiver resolvido.
func is_unlocked(i: int) -> bool:
	return i == 0 or is_done(i - 1) or is_done(i)


func best_time(i: int) -> float:
	return float(progress.done.get(level_id(i), {}).get("t", 0.0))


func stars(i: int) -> int:
	return int(progress.done.get(level_id(i), {}).get("s", 0))


## Estrelas por nível: 3 sem dicas, 2 com uma, 1 com mais.
static func stars_for(hints_used: int) -> int:
	return clampi(3 - hints_used, 1, 3)


func total_stars() -> int:
	var n := 0
	for i in levels.size():
		n += stars(i)
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
	var k := level_id(i)
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


func set_music(on: bool) -> void:
	progress.music = on
	_save()
	Sfx.refresh_music()


func set_sfx(on: bool) -> void:
	progress.sfx = on
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
	var version := int(data.get("version", 1))
	if done is Dictionary:
		for k in done:
			# formato antigo: só o tempo
			var v = done[k]
			var key: String = k
			# versão 1: o Bosque eram os níveis 6-11; na versão 2 passaram a 12-17
			if version < 2 and int(k) >= 6:
				key = str(int(k) + 6)
			# versões 1 e 2 guardavam o número do nível; a 3 guarda o id
			if version < 3:
				var idx := int(key)
				if idx < 0 or idx >= LEGACY_ORDER_V2.size():
					continue
				key = LEGACY_ORDER_V2[idx]
			progress.done[key] = v if v is Dictionary else {"t": float(v), "s": 3}
	var seen = data.get("seen", [])
	if seen is Array:
		progress.seen = seen
	progress.vibrate = bool(data.get("vibrate", true))
	progress.lang = str(data.get("lang", ""))
	progress.music = bool(data.get("music", true))
	progress.sfx = bool(data.get("sfx", true))


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		var data := progress.duplicate()
		data.version = SAVE_VERSION
		f.store_string(JSON.stringify(data))


static func format_time(s: float) -> String:
	var t := int(s)
	return "%d:%02d" % [int(t / 60.0), t % 60]
