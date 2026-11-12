extends Node
## Autoload "Ads": anúncios AdMob (plugin da Poing Studios em addons/admob).
##
## - Pede o consentimento RGPD (UMP) ao abrir e só depois inicia os anúncios.
## - Anúncio de ecrã inteiro entre níveis, com pouca frequência (ver regras abaixo).
## - Anúncio com prémio: dá uma dica extra quando já não há dicas.
## - Fora do Android/iOS (editor, web) não faz nada.
##
## IDs: enquanto for uma compilação de teste usa os IDs de teste da Google.
## Antes de publicar, põe os teus IDs (AdMob → Apps → Blocos de anúncios) em REAL_IDS
## e o App ID (com "~") em Projeto → Ferramentas → AdMob Manager.

signal rewarded_ready_changed

const TEST_IDS := {
	"Android": {"interstitial": "ca-app-pub-3940256099942544/1033173712",
		"rewarded": "ca-app-pub-3940256099942544/5224354917"},
	"iOS": {"interstitial": "ca-app-pub-3940256099942544/4411468910",
		"rewarded": "ca-app-pub-3940256099942544/1712485313"},
}
const REAL_IDS := {
	"Android": {"interstitial": "ca-app-pub-9679077125515046/3895790543",
		"rewarded": "ca-app-pub-9679077125515046/4646745370"},
	"iOS": {"interstitial": "ca-app-pub-9679077125515046/6330382199",
		"rewarded": "ca-app-pub-9679077125515046/4850100361"},
}

## Regras do anúncio entre níveis: nunca nos primeiros níveis, no máximo um a cada
## LEVELS_BETWEEN níveis resolvidos e com pelo menos SECONDS_BETWEEN segundos de intervalo.
const FREE_LEVELS := 8
const LEVELS_BETWEEN := 3
const SECONDS_BETWEEN := 150.0

var enabled := false        # plataforma com anúncios e consentimento tratado
var _interstitial: InterstitialAd
var _rewarded: RewardedAd
var _levels_since := 0
var _last_ad_time := -INF
var _fullscreen_cb := FullScreenContentCallback.new()
var _after_ad: Callable = Callable()
var _showing := ""          # "interstitial" ou "rewarded"


func _ready() -> void:
	if not OS.get_name() in ["Android", "iOS"]:
		return
	_fullscreen_cb.on_ad_dismissed_full_screen_content = _on_ad_closed
	_fullscreen_cb.on_ad_failed_to_show_full_screen_content = func(_e): _on_ad_closed()
	_gather_consent()


# ---------- consentimento (RGPD) ----------

func _gather_consent() -> void:
	var request := ConsentRequestParameters.new()
	request.tag_for_under_age_of_consent = false
	UserMessagingPlatform.consent_information.update(request, _on_consent_updated, func(_e): _start())


func _on_consent_updated() -> void:
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(func(form: ConsentForm):
			if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
				form.show(func(_e): _start())
			else:
				_start(),
			func(_e): _start())
	else:
		_start()


## As definições mostram "Privacidade dos anúncios" só quando a lei o exige (UE, Reino Unido...).
func privacy_options_required() -> bool:
	if not OS.get_name() in ["Android", "iOS"]:
		return false
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_e): pass)


func _start() -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if status == ConsentInformation.ConsentStatus.REQUIRED:
		return  # o jogador fechou sem responder: sem anúncios desta vez
	enabled = true
	MobileAds.initialize()
	_load_interstitial()
	_load_rewarded()


# ---------- ids ----------

func _id(kind: String) -> String:
	var os := OS.get_name()
	var real: String = REAL_IDS.get(os, {}).get(kind, "")
	if OS.is_debug_build() or real == "":
		return TEST_IDS[os][kind]
	return real


# ---------- entre níveis ----------

func _load_interstitial() -> void:
	if _interstitial:
		_interstitial.destroy()
		_interstitial = null
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd):
		_interstitial = ad
		_interstitial.full_screen_content_callback = _fullscreen_cb
	cb.on_ad_failed_to_load = func(_e): get_tree().create_timer(60.0).timeout.connect(_load_interstitial)
	InterstitialAdLoader.new().load(_id("interstitial"), AdRequest.new(), cb)


## Chamado ao acabar um nível, antes de seguir. Mostra um anúncio se as regras
## deixarem e chama `then` quando ele fechar (ou logo, se não houver anúncio).
func level_finished(level_index: int, then: Callable) -> void:
	_levels_since += 1
	var now := Time.get_ticks_msec() / 1000.0
	var ok: bool = enabled and not Game.progress.get("no_ads", false) and _interstitial != null \
		and level_index >= FREE_LEVELS and _levels_since >= LEVELS_BETWEEN \
		and now - _last_ad_time >= SECONDS_BETWEEN
	if not ok:
		then.call()
		return
	_levels_since = 0
	_last_ad_time = now
	_after_ad = then
	_showing = "interstitial"
	Sfx.pause_music(true)
	_interstitial.show()


func _on_ad_closed() -> void:
	Sfx.pause_music(false)
	if _showing == "interstitial":
		_load_interstitial()
	else:
		_load_rewarded()
	_showing = ""
	if _after_ad.is_valid():
		var f := _after_ad
		_after_ad = Callable()
		f.call()


# ---------- com prémio (dica extra) ----------

func _load_rewarded() -> void:
	if _rewarded:
		_rewarded.destroy()
		_rewarded = null
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd):
		_rewarded = ad
		_rewarded.full_screen_content_callback = _fullscreen_cb
		rewarded_ready_changed.emit()
	cb.on_ad_failed_to_load = func(_e): get_tree().create_timer(60.0).timeout.connect(_load_rewarded)
	RewardedAdLoader.new().load(_id("rewarded"), AdRequest.new(), cb)


func rewarded_ready() -> bool:
	return enabled and _rewarded != null


## Mostra o anúncio com prémio; `on_reward` só é chamado se o jogador o vir até ao fim.
func show_rewarded(on_reward: Callable) -> void:
	if not rewarded_ready():
		return
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item): on_reward.call_deferred()
	var ad := _rewarded
	_rewarded = null
	rewarded_ready_changed.emit()
	_showing = "rewarded"
	Sfx.pause_music(true)
	ad.show(listener)
