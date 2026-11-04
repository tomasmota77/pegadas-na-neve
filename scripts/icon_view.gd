class_name IconView
extends Control
## Mostra um ícone de assets/images (escondido enquanto a imagem não existir).

@export var icon_name := "":
	set(v):
		icon_name = v
		queue_redraw()
@export var color := Color("20304a"):
	set(v):
		color = v
		queue_redraw()


func _ready() -> void:
	# sem imagem não ocupa espaço
	visible = Icons.has(icon_name)


func _draw() -> void:
	var s := minf(size.x, size.y)
	Icons.draw_icon(self, icon_name, size * 0.5, s, color)
