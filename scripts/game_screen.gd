extends Control
## Ecrã de jogo: barra de topo, regras do nível, tabuleiro e ações.

signal back_requested
signal next_requested(index: int)

## Todos os textos vêm de data/traducoes.csv (tr("CHAVE")).

var index := 0
var st := PuzzleState.new()
var elapsed := 0.0
var running := false

@onready var board: Board = %Board


func _ready() -> void:
	%BackBtn.pressed.connect(func(): back_requested.emit())
	%HelpBtn.pressed.connect(_show_rules)
	%UndoBtn.pressed.connect(func():
		st.undo()
		_after_change())
	%ClearBtn.pressed.connect(func():
		st.clear_all()
		_after_change())
	%HintBtn.pressed.connect(_on_hint)
	board.changed.connect(_refresh)
	board.path_completed.connect(func(_t): Game.vibrate(30))
	board.solved.connect(_on_solved)


func start(i: int) -> void:
	index = i
	st.load_level(Game.levels[i])
	board.setup(st)
	%LevelLabel.text = tr("LEVEL_N") % (i + 1)
	%NameLabel.text = Game.level_name(i)
	elapsed = 0.0
	running = true
	_build_chips()
	_refresh()
	_intro.call_deferred()


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
	for a in st.animals:
		var info: Dictionary = Game.ANIMALS[a.type]
		var col: Color = info.color
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box := StyleBoxFlat.new()
		box.bg_color = col.lerp(Color.WHITE, 0.88)
		box.set_corner_radius_all(24)
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 10
		box.content_margin_bottom = 12
		box.anti_aliasing = true
		chip.add_theme_stylebox_override("panel", box)
		var col_box := VBoxContainer.new()
		col_box.add_theme_constant_override("separation", -6)
		col_box.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := TextureRect.new()
		icon.texture = Game.texture(a.type)
		icon.custom_minimum_size = Vector2(0, 60)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var name_lbl := Label.new()
		name_lbl.text = Game.animal_text(a.type, "NAME")
		name_lbl.theme_type_variation = &"ChipTitle"
		name_lbl.add_theme_color_override("font_color", col.darkened(0.2))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var rule := Label.new()
		rule.text = Game.animal_text(a.type, "RULE")
		rule.theme_type_variation = &"Small"
		rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col_box.add_child(icon)
		col_box.add_child(name_lbl)
		col_box.add_child(rule)
		chip.add_child(col_box)
		%Chips.add_child(chip)
	%PawIcon.texture = Game.texture("pegada_" + st.animals[0].type)
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


# ---------- introdução / regras ----------

func _intro() -> void:
	var queue := []
	if Game.progress.seen.is_empty():
		queue.append({"title": tr("HOW_TO_PLAY"), "body": tr("RULES_BODY"), "image": Game.texture("floco")})
	for a in st.animals:
		if not Game.has_seen(a.type):
			queue.append({"title": Game.animal_text(a.type, "MEET"),
				"body": Game.animal_text(a.type, "DETAIL"), "image": Game.texture(a.type)})
			Game.mark_seen(a.type)
	_show_queue(queue)


func _show_queue(queue: Array) -> void:
	if queue.is_empty():
		return
	var s: Dictionary = queue.pop_front()
	var label := tr("GOT_IT") if queue.is_empty() else tr("NEXT")
	%Sheet.open(s.title, s.body, s.image, [{"text": label, "primary": true, "action": _show_queue.bind(queue)}],
		{"dismissable": false})


func _show_rules() -> void:
	var body := tr("RULES_BODY") + "\n"
	for a in st.animals:
		body += "\n[b]%s:[/b] %s" % [Game.animal_text(a.type, "NAME"), Game.animal_text(a.type, "DETAIL")]
	%Sheet.open(tr("RULES_TITLE"), body, null, [{"text": tr("BACK_TO_LEVEL"), "primary": true}])


# ---------- dicas e vitória ----------

func _on_hint() -> void:
	var h := st.hint()
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
	var had_best := Game.is_done(index)
	var record := Game.mark_done(index, elapsed, got)
	Game.vibrate(60)
	await board.play_win().finished
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
