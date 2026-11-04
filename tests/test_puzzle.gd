extends SceneTree
## Testes da lógica: godot --headless --path . -s tests/test_puzzle.gd

var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FALHOU: ", msg)

func _init() -> void:
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	for i in levels.size():
		var st := PuzzleState.new()
		st.load_level(levels[i])
		check(not st.is_solved(), "nível %d começa resolvido" % i)
		# jogar a solução arrastando
		for a in st.animals:
			var sol: Array = st.solution[a.type]
			check(st.press(sol[0]) == "drag", "nível %d: tocar na toca" % i)
			for k in range(1, sol.size()):
				var r := st.drag(sol[k])
				check(r == ("complete" if k == sol.size() - 1 else "step"), "nível %d %s passo %d deu '%s'" % [i, a.type, k, r])
			st.release()
		check(st.is_solved(), "nível %d não ficou resolvido" % i)
		# dicas a partir do zero levam à solução
		st.clear_all()
		var n := 0
		while n < 100:
			var h := st.hint()
			if h.kind == "none":
				break
			n += 1
		check(st.hints_used > 0 or levels[i].givens.size() > 0, "nível %d: dica não fez nada" % i)
		# desfazer volta ao estado anterior
		st.reset()
		var t: String = st.animals[0].type
		st.press(st.animals[0].den)
		st.drag(st.solution[t][1])
		check(st.paths[t].size() == 2, "nível %d: passo não registado" % i)
		st.release()
		st.undo()
		check(st.paths[t].size() == 1, "nível %d: desfazer falhou" % i)
	# regras de movimento
	var st := PuzzleState.new()
	st.load_level(levels[2])  # só coelho
	var den: Vector2i = st.animals[0].den
	st.press(den)
	check(st.drag(den + Vector2i(1, 0)) == "", "coelho não pode andar 1 casa")
	st.release()
	# tocar num caminho sem arrastar não muda nada nem enche o "desfazer"
	st.load_level(levels[0])
	var sol0: Array = st.solution["ourico"]
	st.press(sol0[0])
	for k in range(1, 4):
		st.drag(sol0[k])
	st.release()
	var hist := st._history.size()
	check(st.press(sol0[0]) == "drag", "tocar na toca pega no caminho")
	st.release()
	check(st.paths["ourico"].size() == 4, "toque na toca apagou o caminho")
	check(st._history.size() == hist, "toque sem arrastar criou passo de desfazer")
	# pegar a meio e arrastar para a frente/trás corta o caminho só nessa altura
	st.press(sol0[1])
	check(st.paths["ourico"].size() == 4, "pegar a meio cortou antes de mexer")
	check(st.drag(sol0[0]) == "back", "voltar atrás a partir do meio")
	st.release()
	check(st.paths["ourico"].size() == 1, "caminho não ficou cortado")
	# não se passa para lá da comida
	st.load_level(levels[0])
	st.press(sol0[0])
	for k in range(1, sol0.size()):
		st.drag(sol0[k])
	st.release()
	var food: Vector2i = sol0.back()
	st.press(food)
	for n in [food + Vector2i(1, 0), food + Vector2i(-1, 0), food + Vector2i(0, 1), food + Vector2i(0, -1)]:
		if n != sol0[sol0.size() - 2]:  # voltar à casa anterior é permitido
			check(st.drag(n) == "", "o caminho continuou depois da comida")
	st.release()
	check(st.is_complete("ourico"), "o caminho deixou de estar completo")
	# traduções: todas as línguas carregadas e com os textos principais
	for lang in ["pt", "en", "es", "fr", "de"]:
		TranslationServer.set_locale(lang)
		for key in ["LEVEL_N", "RULES_BODY", "NAME_RAPOSA", "WORLD_5", "STATUS_START"]:
			check(tr(key) != key, "tradução em falta: %s em %s" % [key, lang])
	TranslationServer.set_locale("pt")
	check(tr("LEVEL_N") % 3 == "Nível 3", "português errado")
	TranslationServer.set_locale("en")
	check(tr("LEVEL_N") % 3 == "Level 3", "inglês errado")
	print("Níveis testados: %d | falhas: %d" % [levels.size(), fails])
	quit(1 if fails > 0 else 0)
