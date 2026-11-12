extends Control
## Menu principal: continuar, escolher níveis por mundo e definições.

signal level_chosen(index: int)
signal daily_chosen


func _ready() -> void:
	# logótipo na língua atual (logo_pt.png, logo_en.png...); sem ele, o título em texto
	var logo := Game.texture_localized("logo")
	if logo:
		%Logo.texture = logo
		%Logo.visible = true
		%Title.visible = false
	var next := Game.first_unsolved()
	%PlayBtn.text = tr("PLAY_LEVEL") % (next + 1)
	if Game.is_done(next):
		%PlayBtn.text = tr("PLAY_AGAIN")
	%PlayBtn.pressed.connect(func(): level_chosen.emit(next))
	%SettingsBtn.pressed.connect(_show_settings)
	var stars := [Game.total_stars(), Game.levels.size() * 3]
	%StarsLabel.text = "%d/%d" % stars if Icons.has("estrela") else tr("STARS_N") % stars
	_add_daily_button()
	for w in Game.WORLDS.size():
		%Worlds.add_child(_world_card(w, next))


## Puzzle do dia: abre depois de resolver o mundo 1 (já se conhecem as regras base).
func _add_daily_button() -> void:
	if Game.daily_levels.is_empty():
		return
	var btn := Button.new()
	btn.theme_type_variation = &"SoftButton"
	btn.custom_minimum_size = Vector2(500, 100)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var unlocked := Game.is_done(Game.WORLDS[0].levels.back())
	var streak := Game.daily_streak()
	if not unlocked:
		btn.text = tr("DAILY_LOCKED")
		btn.disabled = true
	elif Game.daily_done():
		btn.text = tr("DAILY_DONE") % streak
	else:
		btn.text = tr("DAILY_PLAY") if streak == 0 else tr("DAILY_PLAY_STREAK") % streak
	var cal := Game.texture("calendario")
	if cal:
		btn.icon = cal
		btn.expand_icon = false
	btn.pressed.connect(func(): daily_chosen.emit())
	var parent := %PlayBtn.get_parent()
	parent.add_child(btn)
	parent.move_child(btn, %PlayBtn.get_index() + 1)


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
	# faixa ilustrada do mundo (mundo_<N>.png), se existir
	var banner_tex := Game.texture("mundo_%d" % (w + 1))
	if banner_tex:
		var banner := TextureRect.new()
		banner.texture = banner_tex
		banner.custom_minimum_size = Vector2(0, 150)
		banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		banner.clip_contents = true
		box.add_child(banner)
	var open: bool = Game.is_unlocked(levels[0])
	if not open:
		card.modulate = Color(1, 1, 1, 0.75)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -10)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var small := Label.new()
	small.text = tr("WORLD_N") % (w + 1)
	small.theme_type_variation = &"Small"
	var big := Label.new()
	big.text = Game.world_name(w)
	big.theme_type_variation = &"H2"
	names.add_child(small)
	names.add_child(big)
	head.add_child(names)
	# animais que aparecem neste mundo
	var seen := {}
	for i in levels:
		for a in Game.levels[i].animals:
			seen[a.type] = true
	for i in levels:
		if Game.levels[i].has("ice"):
			seen["gelo"] = true
		if null in Game.levels[i].rows or null in Game.levels[i].cols:
			seen["nevao"] = true
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
		tile.setup(i + 1, state, Game.stars(i), Game.level_tag(i))
		tile.custom_minimum_size = Vector2(0, 96)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.tooltip_text = Game.level_name(i) if state != "locked" else tr("TT_LOCKED") % i
		tile.pressed.connect(func(): level_chosen.emit(i))
		grid.add_child(tile)
	box.add_child(grid)
	if not open:
		var hint := Label.new()
		hint.text = tr("WORLD_LOCKED") % levels[0]
		hint.theme_type_variation = &"Small"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hint)
	return card


# ---------- definições ----------

func _show_settings() -> void:
	var vib := tr("VIBRATION_ON") if Game.progress.vibrate else tr("VIBRATION_OFF")
	%Sheet.open(tr("SETTINGS"), tr("SETTINGS_STARS") % [Game.total_stars(), Game.levels.size() * 3], null, [
		{"text": tr("LANGUAGE_BTN") % Game.LANGS[Game.language()], "plain": true, "action": _show_languages},
		{"text": tr("SOUNDS_ON") if Game.progress.sfx else tr("SOUNDS_OFF"), "plain": true, "action": func():
			Game.set_sfx(not Game.progress.sfx)
			_show_settings()},
		{"text": tr("MUSIC_ON") if Game.progress.music else tr("MUSIC_OFF"), "plain": true, "action": func():
			Game.set_music(not Game.progress.music)
			_show_settings()},
		{"text": vib, "plain": true, "action": func():
			Game.set_vibrate(not Game.progress.vibrate)
			_show_settings()},
		{"text": tr("RESET"), "plain": true, "action": _confirm_reset},
		{"text": tr("CLOSE"), "primary": true},
	])


func _show_languages() -> void:
	var buttons := []
	for code in Game.LANGS:
		buttons.append({"text": Game.LANGS[code], "primary": code == Game.language(), "plain": true, "action": func():
			Game.set_language(code)
			get_tree().reload_current_scene()})
	%Sheet.open(tr("LANGUAGE"), "", null, buttons)


func _confirm_reset() -> void:
	%Sheet.open(tr("RESET_TITLE"), tr("RESET_BODY"), null, [
		{"text": tr("RESET_CONFIRM"), "primary": true, "action": func():
			Game.reset_progress()
			get_tree().reload_current_scene()},
		{"text": tr("CANCEL"), "action": _show_settings},
	])
