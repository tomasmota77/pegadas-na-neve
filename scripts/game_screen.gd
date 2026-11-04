extends Control
## Ecrã de jogo: barra de topo, regras do nível, tabuleiro e ações.

signal back_requested
signal next_requested(index: int)

const RULES := "[b]Leva cada animal da toca até à sua comida.[/b] Arrasta o dedo a partir do animal.\n\nOs [b]números[/b] nas bordas dizem quantas casas são pisadas em cada linha e coluna.\n\nNinguém pisa a mesma casa duas vezes. As [b]pegadas já marcadas[/b] fazem parte do caminho daquele animal.\n\nToca numa casa vazia para a marcar com um X."

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
	var data: Dictionary = Game.levels[i]
	st.load_level(data)
	board.setup(st)
	%LevelLabel.text = "Nível %d" % (i + 1)
	%NameLabel.text = data.name
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
		name_lbl.text = info.name
		name_lbl.theme_type_variation = &"ChipTitle"
		name_lbl.add_theme_color_override("font_color", col.darkened(0.2))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var rule := Label.new()
		rule.text = info.rule
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
	%Status.text = st.status_text()
	if st.active != "":
		var info: Dictionary = Game.ANIMALS[st.active]
		var who: String = ("a " if st.active == "raposa" else "o ") + info.name
		%Status.text = "Leva %s até %s." % [who, _food_article(info.food)]
	%UndoBtn.disabled = not st.can_undo()
	%ClearBtn.disabled = not st.can_undo() and st.marks.is_empty()
	var left := Game.HINTS_PER_LEVEL - st.hints_used
	%HintBtn.badge = left
	%HintBtn.disabled = left <= 0 or st.is_solved()
	%ProgressLabel.text = "%d/%d" % [st.complete_count(), st.animals.size()]
	%ProgressLabel.add_theme_color_override("font_color", Game.COLORS.ok if st.all_complete() else Game.COLORS.ink)


static func _food_article(food: String) -> String:
	return {"cogumelo": "ao cogumelo", "cenoura": "à cenoura", "mirtilos": "aos mirtilos"}.get(food, "à comida")


# ---------- introdução / regras ----------

func _intro() -> void:
	var queue := []
	if Game.progress.seen.is_empty():
		queue.append({"title": "Como se joga", "body": RULES, "image": Game.texture("floco")})
	for a in st.animals:
		if not Game.has_seen(a.type):
			var info: Dictionary = Game.ANIMALS[a.type]
			queue.append({"title": "Conhece o %s" % info.name if a.type != "raposa" else "Conhece a Raposa",
				"body": info.detail, "image": Game.texture(a.type)})
			Game.mark_seen(a.type)
	_show_queue(queue)


func _show_queue(queue: Array) -> void:
	if queue.is_empty():
		return
	var s: Dictionary = queue.pop_front()
	var label := "Percebi" if queue.is_empty() else "Seguinte"
	%Sheet.open(s.title, s.body, s.image, [{"text": label, "primary": true, "action": _show_queue.bind(queue)}],
		{"dismissable": false})


func _show_rules() -> void:
	var body := RULES + "\n"
	for a in st.animals:
		var info: Dictionary = Game.ANIMALS[a.type]
		body += "\n[b]%s:[/b] %s" % [info.name, info.detail]
	%Sheet.open("Regras", body, null, [{"text": "Voltar ao nível", "primary": true}])


# ---------- dicas e vitória ----------

func _on_hint() -> void:
	var h := st.hint()
	match h.kind:
		"fix":
			board.flash(h.cell)
			_refresh()
			%Status.text = "Este passo estava errado. Continua a partir daqui."
		"reveal":
			board.flash(h.cell)
			_refresh()
			%Status.text = "Revelei mais uma pegada."
		_:
			_refresh()
			%Status.text = "Os caminhos estão certos. Leva-os até à comida."
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
	var body := "Tempo: [b]%s[/b]" % Game.format_time(elapsed)
	if record:
		body += "  ·  novo recorde!"
	elif had_best:
		body += "  ·  recorde %s" % Game.format_time(Game.best_time(index))
	if st.hints_used > 0:
		body += "\nUsaste %d %s" % [st.hints_used, "dica" if st.hints_used == 1 else "dicas"]
	else:
		body += "\nSem dicas!"
	var last := index >= Game.levels.size() - 1
	var buttons := []
	if last:
		body += "\n\nResolveste todos os níveis do protótipo."
	else:
		buttons.append({"text": "Próximo nível", "primary": true, "action": func(): next_requested.emit(index + 1)})
	buttons.append({"text": "Ver níveis", "primary": last, "action": func(): back_requested.emit()})
	%Sheet.open("Caminhos descobertos!", body, Game.texture("vitoria"), buttons,
		{"stars": got, "dismissable": false})
