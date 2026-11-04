extends Control
## Menu principal: continuar, escolher níveis por mundo e definições.

signal level_chosen(index: int)


func _ready() -> void:
	var logo := Game.texture("logo")
	if logo:
		%Logo.texture = logo
		%Logo.visible = true
		%Title.visible = false
	var next := Game.first_unsolved()
	%PlayBtn.text = "Jogar nível %d" % (next + 1)
	if Game.is_done(next):
		%PlayBtn.text = "Jogar outra vez"
	%PlayBtn.pressed.connect(func(): level_chosen.emit(next))
	%SettingsBtn.pressed.connect(_show_settings)
	%StarsLabel.text = "%d/%d" % [Game.total_stars(), Game.levels.size() * 3]
	if not Icons.has("estrela"):
		%StarsLabel.text += " estrelas"
	for w in Game.WORLDS.size():
		%Worlds.add_child(_world_card(w, next))


## Botão "voltar" do Android: fecha o painel se estiver aberto. Devolve true se tratou.
func handle_back() -> bool:
	if %Sheet.visible:
		%Sheet.dismiss()
		return true
	return false


func _world_card(w: int, next: int) -> Control:
	var world: Dictionary = Game.WORLDS[w]
	var levels: Array = world.levels
	var card := PanelContainer.new()
	card.theme_type_variation = &"Card"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)
	var open: bool = Game.is_unlocked(levels[0])
	if not open:
		card.modulate = Color(1, 1, 1, 0.75)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -10)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var small := Label.new()
	small.text = "Mundo %d" % (w + 1)
	small.theme_type_variation = &"Small"
	var big := Label.new()
	big.text = world.name
	big.theme_type_variation = &"H2"
	names.add_child(small)
	names.add_child(big)
	head.add_child(names)
	# animais que aparecem neste mundo
	var seen := {}
	for i in levels:
		for a in Game.levels[i].animals:
			seen[a.type] = true
	for t in seen:
		var icon := TextureRect.new()
		icon.texture = Game.texture(t)
		icon.custom_minimum_size = Vector2(60, 60)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(icon)
	box.add_child(head)

	# barra de progresso
	var done := 0
	for i in levels:
		if Game.is_done(i):
			done += 1
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 14)
	var bar := ProgressBar.new()
	bar.max_value = levels.size()
	bar.value = done
	bar.show_percentage = false
	bar.custom_minimum_size.y = 14
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var count := Label.new()
	count.text = "%d/%d" % [done, levels.size()]
	count.theme_type_variation = &"Small"
	bar_row.add_child(bar)
	bar_row.add_child(count)
	box.add_child(bar_row)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for i in levels:
		var tile := LevelTile.new()
		var state := "locked"
		if Game.is_done(i):
			state = "done"
		elif i == next:
			state = "current"
		elif Game.is_unlocked(i):
			state = "open"
		tile.setup(i + 1, state, Game.stars(i))
		tile.custom_minimum_size = Vector2(0, 96)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.tooltip_text = Game.levels[i].name if state != "locked" else "Resolve o nível %d primeiro" % i
		tile.pressed.connect(func(): level_chosen.emit(i))
		grid.add_child(tile)
	box.add_child(grid)
	if not open:
		var hint := Label.new()
		hint.text = "Resolve o nível %d para abrir este mundo." % levels[0]
		hint.theme_type_variation = &"Small"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hint)
	return card


# ---------- definições ----------

func _show_settings() -> void:
	var vib := "Vibração: ligada" if Game.progress.vibrate else "Vibração: desligada"
	%Sheet.open("Definições", "Estrelas: [b]%d[/b] de %d" % [Game.total_stars(), Game.levels.size() * 3], null, [
		{"text": vib, "action": func():
			Game.set_vibrate(not Game.progress.vibrate)
			_show_settings()},
		{"text": "Apagar progresso", "action": _confirm_reset},
		{"text": "Fechar", "primary": true},
	])


func _confirm_reset() -> void:
	%Sheet.open("Apagar progresso?", "Os níveis resolvidos, as estrelas e os recordes vão ser apagados. Não dá para voltar atrás.", null, [
		{"text": "Apagar tudo", "primary": true, "action": func():
			Game.reset_progress()
			get_tree().reload_current_scene()},
		{"text": "Cancelar", "action": _show_settings},
	])
