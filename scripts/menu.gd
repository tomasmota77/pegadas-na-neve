extends Control
## Menu principal: continuar e escolher níveis por mundo.

signal level_chosen(index: int)


func _ready() -> void:
	var next := Game.first_unsolved()
	%PlayBtn.text = "Jogar nível %d" % (next + 1)
	%PlayBtn.pressed.connect(func(): level_chosen.emit(next))
	for w in Game.WORLDS.size():
		%Worlds.add_child(_world_card(w, next))


func _world_card(w: int, next: int) -> Control:
	var world: Dictionary = Game.WORLDS[w]
	var card := PanelContainer.new()
	card.theme_type_variation = &"Card"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -8)
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
	for i in world.levels:
		for a in Game.levels[i].animals:
			seen[a.type] = true
	for t in seen:
		var icon := TextureRect.new()
		icon.texture = Game.texture(t)
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(icon)
	var done := 0
	for i in world.levels:
		if Game.is_done(i):
			done += 1
	var count := Label.new()
	count.text = "%d/%d" % [done, world.levels.size()]
	count.theme_type_variation = &"Muted"
	count.custom_minimum_size.x = 64
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(count)
	box.add_child(head)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for i in world.levels:
		var b := Button.new()
		b.text = str(i + 1)
		b.custom_minimum_size = Vector2(80, 80)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.theme_type_variation = &"LevelButtonDone" if Game.is_done(i) else &"LevelButton"
		if i == next and not Game.is_done(i):
			b.add_theme_color_override("font_color", Game.ANIMALS["coelho"].color)
		b.tooltip_text = Game.levels[i].name
		b.pressed.connect(func(): level_chosen.emit(i))
		grid.add_child(b)
	box.add_child(grid)
	return card
