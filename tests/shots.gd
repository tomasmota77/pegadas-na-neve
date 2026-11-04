extends Node
## Tira capturas de ecrã automáticas: godot --path . -- --shots

var out := "user://shots/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")
	print("shot ", name)

func _play(g, cells_by_type: Dictionary) -> void:
	var st: PuzzleState = g.st
	for t in cells_by_type:
		var cells: Array = cells_by_type[t]
		st.press(cells[0])
		for c in cells.slice(1):
			st.drag(c)
		st.release()
	g.board.queue_redraw()
	g._refresh()

func _run() -> void:
	var main = get_parent()
	await _wait(40)
	await _shot("01_menu")
	main.start_level(3)
	await _wait(30)
	await _shot("02_tutorial")
	main._current.get_node("%Sheet").hide()
	await _wait(5)
	var g = main._current
	var sol: Dictionary = g.st.solution
	await _shot("03_inicio")
	_play(g, {"ourico": sol.ourico, "coelho": sol.coelho.slice(0, 3)})
	g.st.press(sol.coelho[2])
	g.st.active = "coelho"
	await _wait(5)
	await _shot("04_a_meio")
	g.st.release()
	_play(g, {"coelho": sol.coelho.slice(2)})
	g._on_solved()
	await _wait(40)
	await _shot("05_vitoria_anim")
	await get_tree().create_timer(1.6).timeout
	await _shot("06_vitoria")
	main.start_level(10)
	await _wait(30)
	main._current.get_node("%Sheet").hide()
	g = main._current
	sol = g.st.solution
	_play(g, {"ourico": sol.ourico.slice(0, 6), "raposa": sol.raposa.slice(0, 4), "coelho": sol.coelho})
	g.st.marks[Vector2i(0, 0)] = true
	g.board.queue_redraw()
	await _wait(5)
	await _shot("07_nivel11")
	g._show_rules()
	await _wait(30)
	await _shot("08_regras")
	main.show_menu()
	await _wait(30)
	await _shot("09_menu_depois")
	get_tree().quit()
