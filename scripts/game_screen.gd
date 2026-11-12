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

@onready var board: Board = %Board


func _ready() -> void:
	%BackBtn.pressed.connect(func(): back_requested.emit())
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
	elapsed = 0.0
	running = true
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


func _build_chips() -> void:
	for c in %Chips.get_children():
		c.queue_free()
	var items := _items()
	for t in items:
		var col: Color = Game.item_color(t)
		var is_animal := Game.ANIMALS.has(t)
		# com 3 ou mais cartões, os que o jogador já conhece ficam compactos (só imagem e nome)
		var compact := items.size() >= 3 and Game.has_seen(t)
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# cartão com a cor do animal e uma borda mais escura em baixo, para ter relevo
		var box := StyleBoxFlat.new()
		box.bg_color = col.lerp(Color.WHITE, 0.84)
		box.set_corner_radius_all(26)
		box.border_width_bottom = 5
		box.border_color = col.lerp(Color.WHITE, 0.5)
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 4 if compact else 8
		box.content_margin_bottom = 4 if compact else 8
		box.anti_aliasing = true
		chip.add_theme_stylebox_override("panel", box)
		var col_box := VBoxContainer.new()
		col_box.add_theme_constant_override("separation", -8)
		col_box.alignment = BoxContainer.ALIGNMENT_CENTER
		# o animal, com a sua comida numa bolha no canto
		var icon: Control
		if is_animal:
			icon = AnimalBadge.new()
			icon.animal = t
		else:
			icon = TextureRect.new()
			icon.texture = Game.texture(t)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(0, 56 if compact else 84)
		var name_lbl := Label.new()
		name_lbl.text = Game.animal_text(t, "NAME")
		name_lbl.theme_type_variation = &"ChipTitle"
		name_lbl.add_theme_font_size_override("font_size", 30)
		name_lbl.add_theme_color_override("font_color", col.darkened(0.25))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var rule := Label.new()
		rule.visible = not compact
		rule.text = Game.animal_text(t, "RULE")
		rule.theme_type_variation = &"Small"
		rule.add_theme_font_size_override("font_size", 23)
		rule.add_theme_color_override("font_color", col.darkened(0.45).lerp(Game.COLORS.ink_soft, 0.5))
		rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col_box.add_child(icon)
		col_box.add_child(name_lbl)
		col_box.add_child(rule)
		chip.add_child(col_box)
		%Chips.add_child(chip)
	%PawIcon.texture = Game.texture("pegada_" + st.animals[0].type)
	%Chips.queue_sort()
	%PawIcon.modulate = Game.ANIMALS[st.animals[0].type].color


func _after_change() -> void:
	board.queue_redraw()
	_refresh()


func _refresh() -> void:
	%Status.text = tr(st.status_key())
	if st.active != "":
		%Status.text = Game.animal_text(st.active, "LEAD")
	%UndoBtn.disabled = not st.can_undo()
	%ClearBtn.disabled = not st.can_undo() and st.marks.is_empty()
	var left := Game.HINTS_PER_LEVEL - st.hints_used
	%HintBtn.badge = left
	%HintBtn.disabled = left <= 0 or st.is_solved()
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

func _on_hint() -> void:
	var h := st.hint()
	if h.kind != "none":
		Sfx.play("dica")
	match h.kind:
		"fix":
			board.flash(h.cell)
			_refresh()
			%Status.text = tr("HINT_FIX")
		"reveal":
			board.flash(h.cell)
			_refresh()
			%Status.text = tr("HINT_REVEAL")
		_:
			_refresh()
			%Status.text = tr("HINT_NONE")
	board.queue_redraw()


func _on_solved() -> void:
	if not running:
		return
	running = false
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
		buttons.append({"text": tr("NEXT_LEVEL"), "primary": true, "action": func(): next_requested.emit(index + 1)})
	buttons.append({"text": tr("SEE_LEVELS"), "primary": last, "action": func(): back_requested.emit()})
	%Sheet.open(tr("WIN_TITLE"), body, Game.texture("vitoria"), buttons,
		{"stars": got, "dismissable": false})


func _on_daily_solved(got: int) -> void:
	Game.mark_daily(elapsed, got)
	Game.vibrate(60)
	await board.play_win().finished
	Sfx.play("vitoria", 1.0, 0.0)
	var body := tr("WIN_TIME") % Game.format_time(elapsed)
	var streak := Game.daily_streak()
	body += "\n" + (tr("DAILY_STREAK_1") if streak == 1 else tr("DAILY_STREAK_N") % streak)
	body += "\n\n" + tr("DAILY_COME_BACK")
	%Sheet.open(tr("WIN_TITLE"), body, Game.texture("vitoria"),
		[{"text": tr("SEE_LEVELS"), "primary": true, "action": func(): back_requested.emit()}],
		{"stars": got, "dismissable": false})
