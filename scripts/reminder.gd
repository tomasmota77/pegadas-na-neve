extends Node
## Autoload "Reminder": notificação diária "O puzzle de hoje está pronto"
## (plugin Notification Scheduler, em addons/NotificationSchedulerPlugin).
## A hora escolhe-se nas definições (Game.progress.reminder_hour; -1 = desligado).
## Se o puzzle do dia já estiver feito, o lembrete de hoje salta para amanhã.

const HOURS := [-1, 9, 13, 19, 21]
const NOTIFICATION_ID := 1
const CHANNEL_ID := "puzzle_do_dia"

var _sched: NotificationScheduler


func _ready() -> void:
	if not OS.get_name() in ["Android", "iOS"]:
		return
	_sched = NotificationScheduler.new()
	add_child(_sched)
	_sched.initialization_completed.connect(_on_ready)
	_sched.initialize()


func _on_ready() -> void:
	var ch := NotificationChannel.new()
	ch.set_id(CHANNEL_ID).set_name(tr("DAILY_TITLE")).set_description(tr("REMINDER_CHANNEL")) \
		.set_importance(NotificationChannel.Importance.DEFAULT)
	_sched.create_notification_channel(ch)
	reschedule()


## Muda a hora (vinda das definições). Pede autorização para notificações se preciso.
func set_hour(h: int) -> void:
	Game.progress.reminder_hour = h
	Game._save()
	if _sched and h >= 0 and not _sched.has_post_notifications_permission():
		_sched.request_post_notifications_permission()
	reschedule()


## Volta a marcar o lembrete: hoje à hora escolhida, ou amanhã se já passou
## ou se o puzzle de hoje já está feito. Depois repete todos os dias.
func reschedule() -> void:
	if _sched == null:
		return
	_sched.cancel(NOTIFICATION_ID)
	var h: int = Game.progress.reminder_hour
	if h < 0:
		return
	var now := Time.get_datetime_dict_from_system()
	var secs_now: int = now.hour * 3600 + now.minute * 60 + now.second
	var delay := h * 3600 - secs_now
	if delay <= 60 or Game.daily_done():
		delay += 86400
	var n := NotificationData.new()
	n.set_id(NOTIFICATION_ID).set_channel_id(CHANNEL_ID).set_title(tr("REMINDER_TITLE")) \
		.set_content(tr("REMINDER_BODY")).set_small_icon_name("ic_notificacao") \
		.set_delay(delay).set_interval(86400)
	_sched.schedule(n)


func hour_label(h: int) -> String:
	return tr("OFF") if h < 0 else "%d:00" % h
