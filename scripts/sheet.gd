extends Control
## Painel que sobe do fundo do ecrã (regras, novo animal, vitória, definições).

signal closed

var _buttons: Array = []
var _dismissable := true
var _tween: Tween
var _seq := 0


func _ready() -> void:
	%Dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if _dismissable:
				dismiss())
	resized.connect(_place)


## buttons: Array de {text, primary (bool), plain (bool), action (Callable, opcional)}
## opts: {stars: int (mostra 3 estrelas), dismissable: bool (fecha ao tocar fora; por omissão true),
##        content: Control (conteúdo extra entre o texto e os botões)}
func open(title: String, body: String, image: Texture2D = null, buttons: Array = [], opts := {}) -> void:
	%Title.text = title
	%Body.text = "[center]%s[/center]" % body
	%Image.texture = image
	%Image.visible = image != null
	# animação (festa de um animal) um pouco maior do que uma ilustração parada
	%Image.custom_minimum_size.y = 280.0 if image is AnimatedTexture else 180.0
	%Stars.visible = opts.has("stars")
	_dismissable = opts.get("dismissable", true)
	# conteúdo extra (ex.: a grelha da loja), entre o texto e os botões
	var holder: Node = %Buttons.get_parent()
	var old := holder.get_node_or_null("Extra")
	if old:
		holder.remove_child(old)
		old.queue_free()
	if opts.has("content"):
		var extra: Control = opts.content
		extra.name = "Extra"
		holder.add_child(extra)
		holder.move_child(extra, %Buttons.get_index())
	for c in %Buttons.get_children():
		c.queue_free()
	if buttons.is_empty():
		buttons = [{"text": tr("GOT_IT"), "primary": true}]
	_buttons = buttons
	for b in buttons:
		var btn := Button.new()
		btn.text = b.text
		btn.custom_minimum_size.y = 100
		# primary: laranja; plain: branco (listas de opções); senão: azul suave
		btn.theme_type_variation = &"PrimaryButton" if b.get("primary", false) else (&"Button" if b.get("plain", false) else &"SoftButton")
		btn.pressed.connect(_on_button.bind(b))
		%Buttons.add_child(btn)
	show()
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	# fixa a largura e espera que o conteúdo novo seja medido antes de posicionar
	%Panel.size = Vector2(size.x, 0)
	_seq += 1
	var my := _seq
	await get_tree().process_frame
	if not visible or my != _seq:
		return
	_place()
	if opts.has("stars"):
		%Stars.play(int(opts.stars))
	Sfx.play("painel")
	var y: float = %Panel.position.y
	%Panel.position.y = y + 120.0
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.tween_property(%Panel, "position:y", y, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Fecha como se fosse o botão "voltar": se não puder fechar, usa o último botão.
func dismiss() -> void:
	if not visible:
		return
	if _dismissable:
		_close()
	elif not _buttons.is_empty():
		_on_button(_buttons.back())


func _place() -> void:
	# o painel encolhe e cresce com o conteúdo, sempre encostado ao fundo
	var h: float = %Panel.get_combined_minimum_size().y
	h = minf(h, size.y - 40.0)
	%Panel.size = Vector2(size.x, h)
	%Panel.position = Vector2(0, size.y - h)


func _close() -> void:
	if _tween:
		_tween.kill()
	hide()
	closed.emit()


func _on_button(b: Dictionary) -> void:
	_close()
	if b.has("action"):
		b.action.call()
