class_name PuzzleState
extends RefCounted
## Estado e regras de um nível de Pegadas na Neve (sem nada de interface).
##
## Coordenadas: Vector2i(coluna, linha). O JSON guarda [linha, coluna].

const MOVES := {
	"ourico": [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)],
	"coelho": [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)],
	"raposa": [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)],
}

var width := 0
var height := 0
var rocks := {}            # Vector2i -> true
var animals: Array = []    # [{type, den: Vector2i, food: Vector2i}]
var row_targets: Array = []
var col_targets: Array = []
var givens := {}           # Vector2i -> tipo de animal (pegadas visíveis)
var solution := {}         # tipo -> Array[Vector2i]

var paths := {}            # tipo -> Array[Vector2i] (começa sempre na toca)
var marks := {}            # Vector2i -> true (casas marcadas com X pelo jogador)
var active := ""           # animal a ser arrastado agora
var hints_used := 0
var _history: Array = []


static func _cell(a: Array) -> Vector2i:
	return Vector2i(int(a[1]), int(a[0]))


func load_level(d: Dictionary) -> void:
	width = int(d.w)
	height = int(d.h)
	rocks.clear()
	for r in d.rocks:
		rocks[_cell(r)] = true
	animals.clear()
	for a in d.animals:
		animals.append({"type": a.type, "den": _cell(a.den), "food": _cell(a.food)})
	row_targets = d.rows.map(func(v): return int(v))
	col_targets = d.cols.map(func(v): return int(v))
	givens.clear()
	for g in d.givens:
		givens[_cell(g.cell)] = g.type
	solution.clear()
	for t in d.solution:
		solution[t] = d.solution[t].map(func(c): return _cell(c))
	reset()


func reset() -> void:
	paths.clear()
	for a in animals:
		paths[a.type] = [a.den]
	marks.clear()
	active = ""
	hints_used = 0
	_history.clear()


# ---------- consultas ----------

func animal(t: String) -> Dictionary:
	for a in animals:
		if a.type == t:
			return a
	return {}


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


## Devolve {type, role:"den"/"food"} se a casa for uma toca ou comida.
func special(c: Vector2i) -> Dictionary:
	for a in animals:
		if a.den == c:
			return {"type": a.type, "role": "den"}
		if a.food == c:
			return {"type": a.type, "role": "food"}
	return {}


func occupant(c: Vector2i) -> String:
	for t in paths:
		if c in paths[t]:
			return t
	return ""


func is_complete(t: String) -> bool:
	var p: Array = paths[t]
	return p.back() == animal(t).food


func row_count(r: int) -> int:
	var n := 0
	for t in paths:
		for c in paths[t]:
			if c.y == r:
				n += 1
	return n


func col_count(col: int) -> int:
	var n := 0
	for t in paths:
		for c in paths[t]:
			if c.x == col:
				n += 1
	return n


func counts_ok() -> bool:
	for r in height:
		if row_count(r) != row_targets[r]:
			return false
	for c in width:
		if col_count(c) != col_targets[c]:
			return false
	return true


func givens_ok() -> bool:
	for g in givens:
		if not (g in paths[givens[g]]):
			return false
	return true


func all_complete() -> bool:
	for a in animals:
		if not is_complete(a.type):
			return false
	return true


func is_solved() -> bool:
	return all_complete() and counts_ok() and givens_ok()


## Casas para onde o animal `t` pode ir a partir do fim do seu caminho.
func valid_targets(t: String) -> Array:
	var out := []
	var p: Array = paths[t]
	if is_complete(t):
		return out
	for m in MOVES[t]:
		var n: Vector2i = p.back() + m
		if can_step(t, p.back(), n):
			out.append(n)
	return out


func can_step(t: String, from: Vector2i, to: Vector2i) -> bool:
	if not in_bounds(to) or rocks.has(to):
		return false
	if not (to - from in MOVES[t]):
		return false
	if occupant(to) != "":
		return false
	var s := special(to)
	if not s.is_empty() and (s.type != t or s.role != "food"):
		return false
	if givens.has(to) and givens[to] != t:
		return false
	if t == "raposa" and _crosses(from, to):
		return false
	return true


## Um movimento diagonal não pode cruzar outro em X.
func _crosses(from: Vector2i, to: Vector2i) -> bool:
	var a := Vector2i(from.x, to.y)
	var b := Vector2i(to.x, from.y)
	for t in paths:
		var p: Array = paths[t]
		for i in range(p.size() - 1):
			if (p[i] == a and p[i + 1] == b) or (p[i] == b and p[i + 1] == a):
				return true
	return false


# ---------- ações do jogador ----------

## Toque numa casa. Devolve "drag" (começou a arrastar), "mark" (casa vazia) ou "".
func press(c: Vector2i) -> String:
	if not in_bounds(c):
		return ""
	var s := special(c)
	if not s.is_empty() and s.role == "den":
		_snapshot()
		paths[s.type] = [c]
		active = s.type
		return "drag"
	var t := occupant(c)
	if t != "":
		var p: Array = paths[t]
		_snapshot()
		paths[t] = p.slice(0, p.find(c) + 1)
		active = t
		return "drag"
	if s.is_empty() and not rocks.has(c):
		return "mark"
	return ""


## Arrastar até uma casa. Devolve "step", "back", "complete" ou "".
func drag(c: Vector2i) -> String:
	if active == "":
		return ""
	var p: Array = paths[active]
	if c == p.back():
		return ""
	if p.size() >= 2 and c == p[p.size() - 2]:
		p.pop_back()
		return "back"
	if can_step(active, p.back(), c):
		marks.erase(c)
		p.append(c)
		return "complete" if c == animal(active).food else "step"
	return ""


func release() -> void:
	active = ""


func toggle_mark(c: Vector2i) -> void:
	_snapshot()
	if marks.has(c):
		marks.erase(c)
	else:
		marks[c] = true


func clear_all() -> void:
	_snapshot()
	for a in animals:
		paths[a.type] = [a.den]
	marks.clear()


func can_undo() -> bool:
	return not _history.is_empty()


func undo() -> void:
	if _history.is_empty():
		return
	var s: Dictionary = _history.pop_back()
	paths = s.paths
	marks = s.marks


func _snapshot() -> void:
	_history.append({"paths": paths.duplicate(true), "marks": marks.duplicate()})
	if _history.size() > 200:
		_history.pop_front()


## Dica: corrige o primeiro passo errado ou revela a próxima pegada certa.
## Devolve {kind: "fix"/"reveal"/"none", type, cell}.
func hint() -> Dictionary:
	for a in animals:
		var t: String = a.type
		var p: Array = paths[t]
		var sol: Array = solution[t]
		for i in range(1, p.size()):
			if i >= sol.size() or p[i] != sol[i]:
				_snapshot()
				paths[t] = p.slice(0, i)
				hints_used += 1
				return {"kind": "fix", "type": t, "cell": p[i]}
	for a in animals:
		var t: String = a.type
		var p: Array = paths[t]
		var sol: Array = solution[t]
		if p.size() < sol.size():
			# próxima casa ainda sem pista
			for i in range(p.size(), sol.size() - 1):
				var c: Vector2i = sol[i]
				if not givens.has(c):
					_snapshot()
					givens[c] = t
					marks.erase(c)
					_clear_others_at(c, t)
					hints_used += 1
					return {"kind": "reveal", "type": t, "cell": c}
	return {"kind": "none"}


func _clear_others_at(c: Vector2i, t: String) -> void:
	var o := occupant(c)
	if o != "" and o != t:
		var p: Array = paths[o]
		paths[o] = p.slice(0, p.find(c))


## Mensagem curta sobre o estado atual (para a linha de estado).
func status_text() -> String:
	if is_solved():
		return "Encontraste todos os caminhos!"
	if all_complete():
		if not counts_ok():
			return "Os números das bordas ainda não batem certo."
		return "Falta passar por uma das pegadas marcadas."
	return "Arrasta a partir da toca de cada animal."
