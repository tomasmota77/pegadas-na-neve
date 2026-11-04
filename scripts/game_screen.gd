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
	# ícones: usados só quando existirem em assets/images; senão o botão mostra texto
	_icon(%BackBtn, "voltar", "Níveis")
	_icon(%HelpBtn, "ajuda", "Regras")
	_icon(%UndoBtn, "desfazer", "")
	_icon(%ClearBtn, "limpar", "")
	_icon(%HintBtn, "dica", "")
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
	board.path_completed.connect(func(_t): Input.vibrate_handheld(30))
	board.solved.connect(_on_solved)


func _icon(btn: Button, name: String, fallback_text: String) -> void:
	var tex := Game.texture(name)
	btn.icon = tex
	if tex == null and fallback_text != "":
		btn.text = fallback_text
		btn.custom_minimum_size.x = 0


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


func _process(dt: float) -> void:
	if running and not %Sheet.visible:
		elapsed += dt
	%TimerLabel.text = Game.format_time(elapsed)


func _build_chips() -> void:
	for c in %Chips.get_children():
		c.queue_free()
	for a in st.animals:
		var info: Dictionary = Game.ANIMALS[a.type]
		var chip := PanelContainer.new()
		chip.theme_type_variation = &"Chip"
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon := TextureRect.new()
		icon.texture = Game.texture(a.type)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var lbl := Label.new()
		lbl.text = info.rule
		lbl.theme_type_variation = &"Small"
		lbl.add_theme_color_override("font_color", info.color.darkened(0.15))
		row.add_child(icon)
		row.add_child(lbl)
		chip.add_child(row)
		%Chips.add_child(chip)


func _after_change() -> void:
	board.queue_redraw()
	_refresh()


func _refresh() -> void:
	%Status.text = st.status_text()
	%UndoBtn.disabled = not st.can_undo()
	var left := Game.HINTS_PER_LEVEL - st.hints_used
	%HintBtn.text = "Dica %d" % left
	%HintBtn.disabled = left <= 0 or st.is_solved()


# ---------- introdução / regras ----------

func _intro() -> void:
	var queue := []
	if Game.progress.seen.is_empty():
		queue.append({"title": "Como se joga", "body": RULES, "image": Game.texture("floco")})
	for a in st.animals:
		if not Game.has_seen(a.type):
			var info: Dictionary = Game.ANIMALS[a.type]
			queue.append({"title": "Conhece o %s" % info.name, "body": info.detail, "image": Game.texture(a.type)})
			Game.mark_seen(a.type)
	_show_queue(queue)


func _show_queue(queue: Array) -> void:
	if queue.is_empty():
		return
	var s: Dictionary = queue.pop_front()
	%Sheet.open(s.title, s.body, s.image, [{"text": "Percebi", "primary": true, "action": _show_queue.bind(queue)}])


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
			%Status.text = "Este passo estava errado. Continua a partir daqui."
		"reveal":
			board.flash(h.cell)
			%Status.text = "Revelei mais uma pegada."
		_:
			%Status.text = "Os caminhos estão certos. Leva-os até à comida."
	board.queue_redraw()
	var left := Game.HINTS_PER_LEVEL - st.hints_used
	%HintBtn.text = "Dica %d" % left
	%HintBtn.disabled = left <= 0
	%UndoBtn.disabled = not st.can_undo()


func _on_solved() -> void:
	if not running:
		return
	running = false
	_refresh()
	Game.mark_done(index, elapsed)
	Input.vibrate_handheld(60)
	await board.play_win().finished
	var body := "Nível %d em [b]%s[/b]" % [index + 1, Game.format_time(elapsed)]
	if st.hints_used > 0:
		body += "\nUsaste %d %s" % [st.hints_used, "dica" if st.hints_used == 1 else "dicas"]
	var last := index >= Game.levels.size() - 1
	var buttons := []
	if last:
		body += "\n\nResolveste todos os níveis do protótipo."
	else:
		buttons.append({"text": "Próximo nível", "primary": true, "action": func(): next_requested.emit(index + 1)})
	buttons.append({"text": "Ver níveis", "primary": last, "action": func(): back_requested.emit()})
	%Sheet.open("Caminhos descobertos!", body, Game.texture("estrela"), buttons)
