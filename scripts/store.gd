extends Node
## Autoload "Store": compra única "remover anúncios" (plugin godot-iap, em addons/godot-iap).
##
## O produto tem de existir nas lojas com o id PRODUCT_ID:
## - Google Play Console → Monetizar → Produtos → Produtos na app
## - App Store Connect → Monetização → Compras na app (tipo "Não consumível")
## Fora do Android/iOS não faz nada.

signal changed

const Types = preload("res://addons/godot-iap/types.gd")
const PRODUCT_ID := "remover_anuncios"

var price := ""        # preço mostrado pela loja, ex.: "2,99 €"
var available := false # ligação à loja feita e produto encontrado
var _iap: Node


func _ready() -> void:
	if not OS.get_name() in ["Android", "iOS"]:
		return
	_iap = get_node_or_null("/root/GodotIapPlugin")
	if _iap == null:
		return
	_iap.purchase_updated.connect(func(p: Dictionary): _handle_purchase(p))
	_iap.purchase_error.connect(func(_e): changed.emit())
	_iap.products_fetched.connect(_on_products_fetched)
	if not _iap.init_connection():
		return
	_check_owned()
	var req := Types.ProductRequest.new()
	req.skus = [PRODUCT_ID] as Array[String]
	req.type = Types.ProductQueryType.IN_APP
	for product in _iap.fetch_products(req):
		_set_product(product.id, product.display_price)


func _on_products_fetched(result: Dictionary) -> void:
	for p in result.get("products", []):
		_set_product(str(p.get("id", "")), str(p.get("displayPrice", "")))


func _set_product(id: String, display_price: String) -> void:
	if id == PRODUCT_ID:
		price = display_price
		available = true
		changed.emit()


## Já foi comprado antes (reinstalação, outro telemóvel com a mesma conta)?
func _check_owned() -> void:
	for p in _iap.get_available_purchases():
		_handle_purchase(p)


func buy() -> void:
	if not available:
		return
	var props := Types.RequestPurchaseProps.new()
	props.request = Types.RequestPurchasePropsByPlatforms.new()
	props.request.google = Types.RequestPurchaseAndroidProps.new()
	props.request.google.skus = [PRODUCT_ID] as Array[String]
	props.request.apple = Types.RequestPurchaseIosProps.new()
	props.request.apple.sku = PRODUCT_ID
	props.type = Types.ProductQueryType.IN_APP
	_iap.request_purchase(props)


## "Restaurar compras": obrigatório na App Store para compras não consumíveis.
func restore() -> void:
	if _iap == null:
		return
	_iap.restore_purchases()
	_check_owned()
	changed.emit()


func _handle_purchase(purchase) -> void:
	var id: String = purchase.product_id if purchase is Object else str(purchase.get("productId", ""))
	var state = purchase.purchase_state if purchase is Object else purchase.get("purchaseState", "")
	var bought: bool = state == Types.PurchaseState.PURCHASED or str(state).to_lower() == "purchased"
	if id != PRODUCT_ID or not bought:
		return
	if not Game.progress.no_ads:
		Game.set_no_ads(true)
	# confirma a compra (no Android, sem isto a Google devolve o dinheiro ao fim de 3 dias)
	var input: Types.PurchaseInput
	if purchase is Object:
		input = Types.PurchaseInput.new()
		input.product_id = purchase.product_id
		input.purchase_token = purchase.purchase_token if "purchase_token" in purchase else ""
		input.id = purchase.id if "id" in purchase else ""
	else:
		input = Types.PurchaseInput.from_dict(purchase)
	_iap.finish_transaction(input, false)
	changed.emit()
