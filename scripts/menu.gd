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
	_add_wardrobe_button()
	Store.changed.connect(func():
		if %Sheet.visible and %Sheet.get_node("%Title").text == tr("SETTINGS"):
			_show_settings())
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
		banner.stretch_mode = TextureRect.STRETCH_SCALE
		# a faixa aparece inteira (sem cortes em cima nem em baixo): a altura acompanha a largura
		var ratio := float(banner_tex.get_width()) / banner_tex.get_height()
		banner.resized.connect(func():
			var h := roundf(banner.size.x / ratio)
			if absf(banner.custom_minimum_size.y - h) > 0.5:
				banner.custom_minimum_size.y = h)
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
	# com muitos ícones (mundos 7-12) ficam numa linha própria, por baixo do nome
	var icon_row := head
	if seen.size() > 4:
		icon_row = HBoxContainer.new()
		icon_row.add_theme_constant_override("separation", 2)
	for t in seen:
		var icon := TextureRect.new()
		icon.texture = Game.texture(t)
		icon.custom_minimum_size = Vector2(60, 60)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_row.add_child(icon)
	box.add_child(head)
	if icon_row != head:
		box.add_child(icon_row)

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
	var buttons := [
		{"text": tr("LANGUAGE_BTN") % Game.LANGS[Game.language()], "plain": true, "action": _show_languages},
		{"text": tr("SOUND_MENU"), "plain": true, "action": _show_sound},
		{"text": tr("REMINDER_BTN") % Reminder.hour_label(Game.progress.reminder_hour), "plain": true, "action": func():
			# percorre: desligado → 9:00 → 13:00 → 19:00 → 21:00 → desligado
			var hours: Array = Reminder.HOURS
			var k := hours.find(Game.progress.reminder_hour)
			Reminder.set_hour(hours[(k + 1) % hours.size()])
			_show_settings()},
	]
	if not Game.progress.no_ads and Store.available:
		buttons.append({"text": tr("REMOVE_ADS_BTN") % Store.price, "plain": true, "action": Store.buy})
	buttons.append_array([
		{"text": tr("PRIVACY_BTN"), "plain": true, "action": _show_privacy},
		{"text": tr("MORE_BTN"), "plain": true, "action": _show_more},
		{"text": tr("CLOSE"), "primary": true},
	])
	%Sheet.open(tr("SETTINGS"), tr("SETTINGS_STARS") % [Game.total_stars(), Game.levels.size() * 3], null, buttons)


func _show_sound() -> void:
	var vib := tr("VIBRATION_ON") if Game.progress.vibrate else tr("VIBRATION_OFF")
	%Sheet.open(tr("SOUND_MENU"), "", null, [
		{"text": tr("SOUNDS_ON") if Game.progress.sfx else tr("SOUNDS_OFF"), "plain": true, "action": func():
			Game.set_sfx(not Game.progress.sfx)
			_show_sound()},
		{"text": tr("MUSIC_ON") if Game.progress.music else tr("MUSIC_OFF"), "plain": true, "action": func():
			Game.set_music(not Game.progress.music)
			_show_sound()},
		{"text": vib, "plain": true, "action": func():
			Game.set_vibrate(not Game.progress.vibrate)
			_show_sound()},
		{"text": tr("BACK"), "primary": true, "action": _show_settings},
	])


func _show_more() -> void:
	var buttons := [{"text": tr("CREDITS_BTN"), "plain": true, "action": _show_credits}]
	if Store.available or OS.get_name() == "iOS":
		buttons.append({"text": tr("RESTORE_BTN"), "plain": true, "action": func():
			Store.restore()
			_show_more()})
	buttons.append({"text": tr("RESET"), "plain": true, "action": _confirm_reset})
	buttons.append({"text": tr("BACK"), "primary": true, "action": _show_settings})
	var body := tr("NO_ADS_THANKS") if Game.progress.no_ads else ""
	%Sheet.open(tr("MORE_BTN"), body, null, buttons)


# ---------- guarda-roupa: roupas dos animais compradas com estrelas ----------

func _add_wardrobe_button() -> void:
	if not Game.any_skin_exists():
		return
	var btn := Button.new()
	btn.theme_type_variation = &"SoftButton"
	btn.text = tr("WARDROBE")
	var tex := Game.texture("roupas")
	if tex:
		btn.icon = tex
		btn.expand_icon = true
	btn.custom_minimum_size = Vector2(0, 88)
	btn.pressed.connect(_show_wardrobe)
	var row := %SettingsBtn.get_parent()
	row.add_child(btn)
	row.move_child(btn, %SettingsBtn.get_index())


func _show_wardrobe() -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 18)
	for t in Game.ANIMALS:
		if not Game.has_seen(t):
			continue
		var skins := Game.SKINS.filter(func(sk): return Game.skin_exists(t, sk.id))
		if skins.is_empty():
			continue
		var name_lbl := Label.new()
		name_lbl.text = Game.animal_text(t, "NAME")
		name_lbl.theme_type_variation = &"H2"
		list.add_child(name_lbl)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_skin_card(t, {"id": "", "cost": 0}))
		for sk in skins:
			row.add_child(_skin_card(t, sk))
		list.add_child(row)
	if list.get_child_count() == 0:
		var none := Label.new()
		none.text = tr("WARDROBE_EMPTY")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(none)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = minf(get_viewport_rect().size.y * 0.55, 760.0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	%Sheet.open(tr("WARDROBE"), tr("WARDROBE_BODY") % Game.star_balance(), null,
		[{"text": tr("CLOSE"), "primary": true}], {"content": scroll})


## Um cartão da loja: imagem do animal com a roupa e o botão (comprar, vestir ou a usar).
func _skin_card(t: String, sk: Dictionary) -> Control:
	var id: String = sk.id
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size.x = 10
	box.add_theme_constant_override("separation", 6)
	var img := TextureRect.new()
	img.texture = Game.texture_raw(t if id == "" else "%s_%s" % [t, id])
	img.custom_minimum_size = Vector2(0, 120)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(img)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(10, 64)
	btn.clip_text = true
	btn.add_theme_font_size_override("font_size", 22)
	var worn: String = Game.progress.wear.get(t, "")
	if worn == id:
		var lbl := Label.new()
		lbl.text = tr("SKIN_WORN")
		lbl.theme_type_variation = &"Small"
		lbl.custom_minimum_size.y = 64
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(lbl)
		btn.queue_free()
		return box
	elif id == "" or Game.owns_skin(t, id):
		btn.text = tr("SKIN_WEAR")
		btn.theme_type_variation = &"SoftButton"
		btn.pressed.connect(func():
			Game.wear_skin(t, id)
			_show_wardrobe())
	else:
		btn.text = str(sk.cost)
		btn.icon = Game.texture("estrela")
		btn.expand_icon = false
		btn.add_theme_constant_override("icon_max_width", 26)
		btn.theme_type_variation = &"PrimaryButton"
		btn.disabled = Game.star_balance() < int(sk.cost)
		btn.pressed.connect(func():
			if Game.buy_skin(t, id, sk.cost):
				Sfx.play("estrela")
				Game.vibrate(40)
			_show_wardrobe())
	box.add_child(btn)
	return box


func _show_privacy() -> void:
	var buttons := [{"text": tr("PRIVACY_POLICY"), "plain": true, "action": func():
		OS.shell_open(Game.PRIVACY_URL % ("pt" if Game.language() == "pt" else "en"))
		_show_privacy()}]
	if Ads.privacy_options_required():
		buttons.append({"text": tr("AD_PRIVACY_BTN"), "plain": true, "action": Ads.show_privacy_options})
	buttons.append({"text": tr("BACK"), "primary": true, "action": _show_settings})
	%Sheet.open(tr("PRIVACY_BTN"), tr("PRIVACY_BODY"), null, buttons)


## Créditos e licenças (a licença do Godot tem de aparecer no jogo).
func _show_credits() -> void:
	# a licença vem com quebras de linha a meio das frases: junta cada parágrafo numa linha
	var lic := ""
	for para in Engine.get_license_text().strip_edges().split("\n\n"):
		lic += para.replace("\n", " ") + "\n"
	var body := tr("CREDITS_BODY") + "\n\n[font_size=16]" + lic.strip_edges() \
		+ "\n\nPortions of this software are copyright © The FreeType Project (www.freetype.org). All rights reserved.[/font_size]"
	%Sheet.open(tr("CREDITS_BTN"), body, null, [{"text": tr("BACK"), "primary": true, "action": _show_settings}])


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
