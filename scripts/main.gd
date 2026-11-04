extends Control
## Raiz: aplica o tema, neve de fundo e troca entre menu e jogo.

const MENU := preload("res://scenes/menu.tscn")
const GAME := preload("res://scenes/game.tscn")

var _current: Control


func _ready() -> void:
	theme = UITheme.build()
	_make_snow()
	# todos os botões fazem um "toque" suave ao carregar
	get_tree().node_added.connect(func(n: Node):
		if n is BaseButton and not n.pressed.is_connected(_on_any_button):
			n.pressed.connect(_on_any_button))
	Sfx.refresh_music()
	_fit_screen()
	show_menu()
	if "--shots" in OS.get_cmdline_user_args():
		add_child(load("res://tests/shots.gd").new())


func _on_any_button() -> void:
	Sfx.play("toque")


func show_menu() -> void:
	var m := MENU.instantiate()
	m.level_chosen.connect(start_level)
	_swap(m)


func start_level(i: int) -> void:
	Game.current = i
	var g := GAME.instantiate()
	_swap(g)
	g.start(i)
	g.back_requested.connect(show_menu)
	g.next_requested.connect(start_level)


func _swap(node: Control) -> void:
	if _current:
		_current.queue_free()
	_current = node
	$Screen.add_child(node)
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, 0.22)


## Largura máxima do jogo. Num ecrã largo (browser no computador, tablet deitado)
## o jogo fica centrado com esta largura, em vez de esticar os botões para os lados.
const MAX_WIDTH := 760.0


func _fit_screen() -> void:
	var w := minf(size.x, MAX_WIDTH)
	$Screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$Screen.position = Vector2((size.x - w) * 0.5, 0)
	$Screen.size = Vector2(w, size.y)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_fit_screen()
	# botão "voltar" do Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _current:
		if _current.has_signal("back_requested"):
			_current.handle_back()
		elif not _current.handle_back():
			get_tree().quit()


func _make_snow() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32
	tex.height = 32
	var p := CPUParticles2D.new()
	p.texture = tex
	p.amount = 46
	p.lifetime = 24.0
	p.preprocess = 24.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(420, 4)
	p.position = Vector2(360, -20)
	p.direction = Vector2(0.15, 1)
	p.spread = 12.0
	p.gravity = Vector2(0, 4)
	p.initial_velocity_min = 38.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	p.color = Color(1, 1, 1, 0.9)
	$Snow.add_child(p)
