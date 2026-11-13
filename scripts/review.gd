extends Node
## Autoload "Review": pede uma avaliação com a janela nativa da loja
## (plugin In-app Review, em addons/InappReviewPlugin). A loja decide se a mostra
## (o Google e a Apple limitam quantas vezes aparece), por isso pedimos só em
## momentos bons e cada momento uma vez.

var _review: InappReview


func _ready() -> void:
	if not OS.get_name() in ["Android", "iOS"]:
		return
	_review = InappReview.new()
	add_child(_review)
	_review.review_info_generated.connect(func(): _review.launch_review_flow())


## moment: "mundo1", "mundo3", "serie7"... Só pede uma vez por momento.
## Devolve true se pediu (para não mostrar um anúncio logo a seguir).
func ask(moment: String) -> bool:
	if moment in Game.progress.review_asked:
		return false
	Game.progress.review_asked.append(moment)
	Game._save()
	if _review == null:
		return false
	_review.generate_review_info()
	return true
