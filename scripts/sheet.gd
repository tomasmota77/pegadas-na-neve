extends Control
## Painel que sobe do fundo do ecrã (regras, novo animal, vitória).

signal closed


## buttons: Array de {text, primary (bool), action (Callable, opcional)}
func open(title: String, body: String, image: Texture2D = null, buttons: Array = []) -> void:
	%Title.text = title
	%Body.text = "[center]%s[/center]" % body
	%Image.texture = image
	%Image.visible = image != null
	for c in %Buttons.get_children():
		c.queue_free()
	if buttons.is_empty():
		buttons = [{"text": "Percebi", "primary": true}]
	for b in buttons:
		var btn := Button.new()
		btn.text = b.text
		btn.custom_minimum_size.y = 96
		if b.get("primary", false):
			btn.theme_type_variation = &"PrimaryButton"
		btn.pressed.connect(_on_button.bind(b))
		%Buttons.add_child(btn)
	show()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	await get_tree().process_frame
	var y: float = %Panel.position.y
	%Panel.position.y = y + 90.0
	create_tween().tween_property(%Panel, "position:y", y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_button(b: Dictionary) -> void:
	hide()
	closed.emit()
	if b.has("action"):
		b.action.call()
