class_name PuzzleState
extends RefCounted
## Estado e regras de um nível de Pegadas na Neve (sem nada de interface).
##
## Coordenadas: Vector2i(coluna, linha). O JSON guarda [linha, coluna].

const MOVES := {
	"ourico": [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)],
	"coelho": [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)],
	"raposa": [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)],
	# esquilo: salto em L, como o cavalo do xadrez (por cima de tudo)
	"esquilo": [Vector2i(2, 1), Vector2i(1, 2), Vector2i(-1, 2), Vector2i(-2, 1),
		Vector2i(-2, -1), Vector2i(-1, -2), Vector2i(1, -2), Vector2i(2, -1)],
	# coruja: voa em linha reta quantas casas quiser (ver moves_of)
}

var width := 0
var height := 0
var rocks := {}            # Vector2i -> true
var ice := {}              # Vector2i -> true (quem pousa no gelo repete o movimento)
var animals: Array = []    # [{type, den: Vector2i, food: Vector2i}]
var row_targets: Array = []
var col_targets: Array = []
var givens := {}           # Vector2i -> tipo de animal (pegadas visíveis)
var solution := {}         # tipo -> Array[Vector2i]

var paths := {}            # tipo -> Array[Vector2i] (começa sempre na toca)
var marks := {}            # Vector2i -> true (casas marcadas com X pelo jogador)
var active := ""           # animal a ser arrastado agora
var hints_used := 0
## Quantas casas uma dica desenha de uma vez.
const HINT_STEPS := 3
var _history: Array = []
var _grab := -1            # índice do caminho onde o dedo pegou (corte adiado até mexer)
var _gesture_steps := 0    # passos acrescentados neste gesto (a coruja estica o voo)
var _owl_moves: Array = []


static func _cell(a: Array) -> Vector2i:
	return Vector2i(int(a[1]), int(a[0]))


func load_level(d: Dictionary) -> void:
	width = int(d.w)
	height = int(d.h)
	rocks.clear()
	for r in d.rocks:
		rocks[_cell(r)] = true
	ice.clear()
	for r in d.get("ice", []):
		ice[_cell(r)] = true
	_owl_moves.clear()
	for k in range(1, maxi(width, height)):
		_owl_moves.append_array([Vector2i(k, 0), Vector2i(-k, 0), Vector2i(0, k), Vector2i(0, -k)])
	animals.clear()
	for a in d.animals:
		animals.append({"type": a.type, "den": _cell(a.den), "food": _cell(a.food)})
	# -1 = número tapado pelo nevão
	row_targets = d.rows.map(func(v): return -1 if v == null else int(v))
	col_targets = d.cols.map(func(v): return -1 if v == null else int(v))
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
	_grab = -1
	_gesture_steps = 0
	hints_used = 0
	_history.clear()


# ---------- consultas ----------

func moves_of(t: String) -> Array:
	return _owl_moves if t == "coruja" else MOVES[t]


func has_hidden() -> bool:
	return row_targets.has(-1) or col_targets.has(-1)


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
		if row_targets[r] >= 0 and row_count(r) != row_targets[r]:
			return false
	for c in width:
		if col_targets[c] >= 0 and col_count(c) != col_targets[c]:
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
	var tip := tip_of(t)
	if tip == animal(t).food:
		return out
	for m in moves_of(t):
		var n: Vector2i = tip + m
		if can_step(t, tip, n):
			out.append(n)
	return out


## Ponta atual do caminho (onde o dedo pegou, se ainda não mexeu).
func tip_of(t: String) -> Vector2i:
	if t == active and _grab >= 0:
		return paths[t][_grab]
	return paths[t].back()


func can_step(t: String, from: Vector2i, to: Vector2i) -> bool:
	if not in_bounds(to) or rocks.has(to):
		return false
	if from == animal(t).food:
		return false
	if not (to - from in moves_of(t)):
		return false
	# gelo: quem pousou no gelo tem de repetir o movimento com que lá chegou
	if ice.has(from):
		var p: Array = paths[t]
		var k := p.find(from)
		if k >= 1 and to - from != from - p[k - 1]:
			return false
	var o := occupant(to)
	if o != "" and not (o == t and t == active and _grab >= 0 and paths[t].find(to) > _grab):
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
		var last := p.size() - 1
		if t == active and _grab >= 0:
			last = _grab
		for i in range(last):
			if (p[i] == a and p[i + 1] == b) or (p[i] == b and p[i + 1] == a):
				return true
	return false


# ---------- ações do jogador ----------

## Toque numa casa. Devolve "drag" (pegou num caminho), "mark" (casa vazia) ou "".
## O caminho só é cortado quando o dedo se mexe: um toque sem arrastar não muda nada.
func press(c: Vector2i) -> String:
	if not in_bounds(c):
		return ""
	var s := special(c)
	var t := occupant(c)
	if t == "" and not s.is_empty() and s.role == "den":
		t = s.type
	if t != "":
		active = t
		_grab = paths[t].find(c)
		_gesture_steps = 0
		return "drag"
	if s.is_empty() and not rocks.has(c):
		return "mark"
	return ""


## Arrastar até uma casa. Devolve "step", "back", "complete" ou "".
func drag(c: Vector2i) -> String:
	if active == "":
		return ""
	var p: Array = paths[active]
	if _grab >= 0:
		if c == p[_grab]:
			return ""
		# primeiro movimento: guarda o estado e corta o caminho onde o dedo pegou
		var prev := p.slice(0, _grab + 1)
		var to_old_back: bool = _grab >= 1 and c == p[_grab - 1]
		if not to_old_back and not can_step(active, p[_grab], c):
			return ""
		_snapshot()
		paths[active] = prev
		p = prev
		_grab = -1
	if c == p.back():
		return ""
	if p.size() >= 2 and c == p[p.size() - 2]:
		p.pop_back()
		_gesture_steps = maxi(0, _gesture_steps - 1)
		return "back"
	# coruja: enquanto o dedo segue em linha reta, o voo estica (só pousa ao levantar o dedo)
	if active == "coruja" and _gesture_steps > 0 and p.size() >= 2:
		var a: Vector2i = p[p.size() - 2]
		var dir: Vector2i = (p.back() - a).sign()
		var off := c - a
		if off.sign() == dir and (off.x == 0 or off.y == 0) and c != p.back():
			var b: Vector2i = p.pop_back()
			if can_step(active, a, c):
				marks.erase(c)
				p.append(c)
				return "complete" if c == animal(active).food else "step"
			p.append(b)
	if can_step(active, p.back(), c):
		marks.erase(c)
		p.append(c)
		_gesture_steps += 1
		return "complete" if c == animal(active).food else "step"
	return ""


func release() -> void:
	active = ""
	_grab = -1
	_gesture_steps = 0


func toggle_mark(c: Vector2i) -> void:
	_snapshot()
	if marks.has(c):
		marks.erase(c)
	else:
		marks[c] = true


func clear_all() -> void:
	if marks.is_empty() and paths.values().all(func(p): return p.size() == 1):
		return
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
	# pistas reveladas por dicas ficam: tira-as dos caminhos de outros animais
	for g in givens:
		_clear_others_at(g, givens[g])


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
	# está tudo certo até aqui: avança o caminho do animal que vai mais atrasado
	# HINT_STEPS passos e deixa-os marcados com pegadas, para não se perderem
	var best := ""
	var best_left := 0
	for a in animals:
		var left: int = solution[a.type].size() - paths[a.type].size()
		if left > best_left:
			best = a.type
			best_left = left
	if best == "":
		return {"kind": "none"}
	_snapshot()
	var t := best
	var sol: Array = solution[t]
	var added := []
	for i in range(paths[t].size(), mini(paths[t].size() + HINT_STEPS, sol.size())):
		var c: Vector2i = sol[i]
		_clear_others_at(c, t)
		marks.erase(c)
		paths[t].append(c)
		added.append(c)
		if c != animal(t).food:
			givens[c] = t
	hints_used += 1
	return {"kind": "reveal", "type": t, "cell": added[0], "cells": added, "complete": is_complete(t)}


func _clear_others_at(c: Vector2i, t: String) -> void:
	var o := occupant(c)
	if o != "" and o != t:
		var p: Array = paths[o]
		paths[o] = p.slice(0, p.find(c))


func complete_count() -> int:
	var n := 0
	for a in animals:
		if is_complete(a.type):
			n += 1
	return n


## Pistas por onde o caminho do respetivo animal ainda não passa.
func missing_givens() -> Array:
	var out := []
	for g in givens:
		if not (g in paths[givens[g]]):
			out.append(g)
	return out


## Chave (em data/traducoes.csv) da mensagem curta sobre o estado atual.
func status_key() -> String:
	if is_solved():
		return "STATUS_SOLVED"
	if all_complete():
		if not counts_ok():
			return "STATUS_COUNTS"
		return "STATUS_GIVENS"
	if complete_count() == 0 and _history.is_empty():
		return "STATUS_START"
	return "STATUS_MARK"
