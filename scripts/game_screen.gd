extends Control
## Ecrã de jogo: barra de topo, regras do nível, tabuleiro e ações.

signal back_requested
signal next_requested(index: int)

## Todos os textos vêm de data/traducoes.csv (tr("CHAVE")).

var index := 0
var st := PuzzleState.new()
var elapsed := 0.0
var running := false
var _lines_ok := -1      # linhas + colunas certas (para o som "linha"); -1 ao começar
var _was_wrong := false
var daily := false          # a jogar o puzzle do dia
var bonus_hints := 0        # dicas extra ganhas com anúncios neste nível
var _dirty := 0.0           # segundos desde a última mudança por guardar (-1 = nada por guardar)

@onready var board: Board = %Board


func _ready() -> void:
	# contorno branco no título, para se ler bem em qualquer fundo (ex.: o do Nevão)
	for l in [%LevelLabel, %NameLabel]:
		l.add_theme_constant_override("outline_size", 12)
		l.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	%BackBtn.pressed.connect(func(): back_requested.emit())
	back_requested.connect(func(): _save_resume(false))
	%HelpBtn.pressed.connect(_show_rules)
	%UndoBtn.pressed.connect(func():
		st.undo()
		Sfx.play("desfazer")
		_after_change())
	%ClearBtn.pressed.connect(func():
		st.clear_all()
		Sfx.play("limpar")
		_after_change())
	%HintBtn.pressed.connect(_on_hint)
	Ads.rewarded_ready_changed.connect(_refresh)
	board.changed.connect(_refresh)
	board.path_completed.connect(func(_t): Game.vibrate(30))
	board.solved.connect(_on_solved)


func start(i: int) -> void:
	daily = false
	index = i
	st.load_level(Game.levels[i])
	board.setup(st)
	%LevelLabel.text = tr("LEVEL_N") % (i + 1)
	var tag := Game.level_tag(i)
	if tag != "":
		%NameLabel.text = tr("TAG_SUPER" if tag == "super" else "TAG_HARD")
		%NameLabel.add_theme_color_override("font_color", Game.TAG_COLORS[tag])
		%NameLabel.theme_type_variation = &"ChipTitle"
	else:
		%NameLabel.text = Game.level_name(i)
		%NameLabel.remove_theme_color_override("font_color")
		%NameLabel.theme_type_variation = &"Small"
	_begin()


func start_daily() -> void:
	daily = true
	index = -1
	st.load_level(Game.daily_level())
	board.setup(st)
	%LevelLabel.text = tr("DAILY_TITLE")
	%NameLabel.text = Time.get_date_string_from_system()
	%NameLabel.remove_theme_color_override("font_color")
	%NameLabel.theme_type_variation = &"Small"
	_begin()


func _begin() -> void:
	_dirty = -1.0
	bonus_hints = 0
	elapsed = 0.0
	running = true
	_restore()
	_lines_ok = -1
	_was_wrong = false
	_build_chips()
	_refresh()
	_intro.call_deferred()


## O que este nível ensina ou usa: os animais e as novidades de terreno.
func _items() -> Array:
	var out := []
	for a in st.animals:
		out.append(a.type)
	if not st.ice.is_empty():
		out.append("gelo")
	if st.has_hidden():
		out.append("nevao")
	return out


## Botão "voltar" do Android: fecha primeiro o painel, se houver.
func handle_back() -> void:
	if %Sheet.visible:
		%Sheet.dismiss()
	else:
		back_requested.emit()


func _process(dt: float) -> void:
	if running and not %Sheet.visible:
		elapsed += dt
	%TimerLabel.text = Game.format_time(elapsed)
	# guarda o nível em curso um segundo depois da última jogada
	if _dirty >= 0.0:
		_dirty += dt
		if _dirty > 1.0:
			_save_resume(true)


# ---------- retomar o nível a meio ----------

func _notification(what: int) -> void:
	# a app foi para segundo plano ou vai fechar: guarda já
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		_save_resume(true)


## open: reabrir este nível sozinho na próxima vez que a app abrir
## (falso quando o jogador sai para o menu de propósito).
func _save_resume(open: bool) -> void:
	_dirty = -1.0
	if not running or st.animals.is_empty():
		return
	var data := st.export_state()
	data.kind = "daily" if daily else "level"
	data.key = Game.daily_key() if daily else Game.level_id(index)
	data.elapsed = elapsed
	data.bonus = bonus_hints
	data.open = open
	Game.save_resume(data)


func _restore() -> void:
	var r: Dictionary = Game.progress.resume
	if r.is_empty() or r.get("kind") != ("daily" if daily else "level"):
		return
	if r.get("key") != (Game.daily_key() if daily else Game.level_id(index)):
		return
	if st.import_state(r):
		elapsed = float(r.get("elapsed", 0.0))
		bonus_hints = int(r.get("bonus", 0))
		board.queue_redraw()


func _build_chips() -> void:
	for c in %Chips.get_children():
		c.queue_free()
	var items := _items()
	for t in items:
		var card := RuleCard.new()
		card.item = t
		# com 4 ou mais cartões ficam todos compactos (sem nome), para caberem
		card.compact = items.size() >= 4
		%Chips.add_child(card)
	%PawIcon.texture = Game.texture("pegada_" + st.animals[0].type)
	%Chips.queue_sort()
	%PawIcon.modulate = Game.ANIMALS[st.animals[0].type].color


func _after_change() -> void:
	board.queue_redraw()
	_refresh()


func _refresh() -> void:
	if running and _dirty < 0.0:
		_dirty = 0.0
	for card in %Chips.get_children():
		if card is RuleCard:
			card.active = card.item == st.active
	%Status.text = tr(st.status_key())
	if st.active != "":
		%Status.text = Game.animal_text(st.active, "LEAD")
	%UndoBtn.disabled = not st.can_undo()
	%ClearBtn.disabled = not st.can_undo() and st.marks.is_empty()
	var left := hints_left()
	%HintBtn.badge = left
	# sem dicas: o botão fica ativo se houver um anúncio com prémio pronto
	%HintBtn.disabled = st.is_solved() or (left <= 0 and not Ads.rewarded_ready())
	%ProgressLabel.text = "%d/%d" % [st.complete_count(), st.animals.size()]
	%ProgressLabel.add_theme_color_override("font_color", Game.COLORS.ok if st.all_complete() else Game.COLORS.ink)
	_refresh_sounds()


## Som quando mais uma linha ou coluna bate certo, e um aviso suave quando
## todos chegaram à comida mas a solução está errada (só uma vez de cada vez).
func _refresh_sounds() -> void:
	var ok := 0
	for r in st.height:
		if st.row_targets[r] >= 0 and st.row_count(r) == st.row_targets[r]:
			ok += 1
	for c in st.width:
		if st.col_targets[c] >= 0 and st.col_count(c) == st.col_targets[c]:
			ok += 1
	var wrong := st.all_complete() and not st.is_solved()
	if _lines_ok >= 0:
		if wrong and not _was_wrong:
			Sfx.play("errado")
			board.shake()
			Game.vibrate(120)
		elif ok > _lines_ok and not st.is_solved():
			Sfx.play("linha", 1.0 + 0.04 * ok, 0.0)
	_lines_ok = ok
	_was_wrong = wrong


# ---------- introdução / regras ----------

func _intro() -> void:
	var queue := []
	if Game.progress.seen.is_empty():
		queue.append({"title": tr("HOW_TO_PLAY"), "body": tr("RULES_BODY"), "image": Game.texture("floco")})
	for t in _items():
		if not Game.has_seen(t):
			var s := {"title": Game.animal_text(t, "MEET"),
				"body": Game.animal_text(t, "DETAIL") + "\n\n[b]" + Game.animal_text(t, "LEAD") + "[/b]",
				"image": Game.texture(t)}
			if Game.ANIMALS.has(t):
				s.sound = "animal_" + t
			queue.append(s)
			Game.mark_seen(t)
	_show_queue(queue)


func _show_queue(queue: Array) -> void:
	if queue.is_empty():
		return
	var s: Dictionary = queue.pop_front()
	if s.has("sound"):
		Sfx.play(s.sound, 1.0, 0.0)
	var label := tr("GOT_IT") if queue.is_empty() else tr("NEXT")
	%Sheet.open(s.title, s.body, s.image, [{"text": label, "primary": true, "action": _show_queue.bind(queue)}],
		{"dismissable": false})


func _show_rules() -> void:
	var body := tr("RULES_BODY") + "\n"
	for t in _items():
		body += "\n[b]%s:[/b] %s %s" % [Game.animal_text(t, "NAME"), Game.animal_text(t, "DETAIL"),
			Game.animal_text(t, "LEAD")]
	%Sheet.open(tr("RULES_TITLE"), body, null, [{"text": tr("BACK_TO_LEVEL"), "primary": true}])


# ---------- dicas e vitória ----------

func hints_left() -> int:
	return Game.HINTS_PER_LEVEL + bonus_hints - st.hints_used


func _on_hint() -> void:
	if hints_left() <= 0:
		if Ads.rewarded_ready():
			%Sheet.open(tr("HINT_AD_TITLE"), tr("HINT_AD_BODY"), Game.texture("dica"), [
				{"text": tr("HINT_AD_WATCH"), "primary": true, "action": func(): Ads.show_rewarded(func():
					bonus_hints += 1
					_on_hint())},
				{"text": tr("CLOSE"), "plain": true}])
		return
	var h := st.hint()
	if h.kind != "none":
		Sfx.play("dica")
	match h.kind:
		"fix":
			# o passo errado pisca a vermelho e o caminho volta ao último passo certo
			board.flash([h.cell], true)
			_refresh()
			%Status.text = tr("HINT_FIX")
		"reveal":
			# os passos novos ficam desenhados e piscam a verde
			board.flash(h.cells)
			_refresh()
			%Status.text = tr("HINT_REVEAL") % Game.animal_text(h.type, "NAME")
			if h.complete:
				Sfx.play("chegou")
				Game.vibrate(30)
		_:
			_refresh()
			%Status.text = tr("HINT_NONE")
	board.queue_redraw()
	if st.is_solved():
		_on_solved()


## Imagem do painel de vitória: a festa de um dos animais do nível, se houver animação;
## senão, a ilustração de vitória.
func _win_image() -> Texture2D:
	var options := []
	for a in st.animals:
		var t := Game.festa(a.type)
		if t:
			options.append(t)
	return options.pick_random() if not options.is_empty() else Game.texture("vitoria")


func _on_solved() -> void:
	if not running:
		return
	running = false
	Game.clear_resume()
	_refresh()
	var got := Game.stars_for(st.hints_used)
	if daily:
		_on_daily_solved(got)
		return
	var had_best := Game.is_done(index)
	var record := Game.mark_done(index, elapsed, got)
	Game.vibrate(60)
	await board.play_win().finished
	Sfx.play("vitoria", 1.0, 0.0)
	var body := tr("WIN_TIME") % Game.format_time(elapsed)
	if record:
		body += "  ·  " + tr("WIN_RECORD")
	elif had_best:
		body += "  ·  " + tr("WIN_BEST") % Game.format_time(Game.best_time(index))
	if st.hints_used == 1:
		body += "\n" + tr("WIN_HINTS_1")
	elif st.hints_used > 1:
		body += "\n" + tr("WIN_HINTS_N") % st.hints_used
	else:
		body += "\n" + tr("WIN_NO_HINTS")
	var last := index >= Game.levels.size() - 1
	var buttons := []
	if last:
		body += "\n\n" + tr("WIN_ALL")
	else:
		buttons.append({"text": tr("NEXT_LEVEL"), "primary": true, "action": func(): _after_win(func(): next_requested.emit(index + 1))})
	buttons.append({"text": tr("SEE_LEVELS"), "primary": last, "action": func(): _after_win(func(): back_requested.emit())})
	%Sheet.open(tr("WIN_TITLE"), body, _win_image(), buttons,
		{"stars": got, "dismissable": false})


## Depois de ganhar: no fim do 1.º e do 3.º mundo pede uma avaliação (uma vez só);
## nos outros níveis pode aparecer um anúncio. Nunca os dois seguidos.
func _after_win(then: Callable) -> void:
	var w := Game.world_of(index)
	var last_of_world := index == Game.levels.size() - 1 or Game.world_of(index + 1) != w
	if last_of_world and w in [0, 2] and Review.ask("mundo%d" % (w + 1)):
		then.call()
		return
	Ads.level_finished(index, then)


func _on_daily_solved(got: int) -> void:
	Game.mark_daily(elapsed, got)
	Reminder.reschedule()
	Game.vibrate(60)
	await board.play_win().finished
	Sfx.play("vitoria", 1.0, 0.0)
	var body := tr("WIN_TIME") % Game.format_time(elapsed)
	var streak := Game.daily_streak()
	body += "\n" + (tr("DAILY_STREAK_1") if streak == 1 else tr("DAILY_STREAK_N") % streak)
	body += "\n\n" + tr("DAILY_COME_BACK")
	%Sheet.open(tr("WIN_TITLE"), body, _win_image(),
		[{"text": tr("SEE_LEVELS"), "primary": true, "action": func():
			if streak >= 7:
				Review.ask("serie7")
			back_requested.emit()}],
		{"stars": got, "dismissable": false})
