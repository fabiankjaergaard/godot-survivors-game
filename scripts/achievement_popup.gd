extends Control

# Achievement popup notification

@onready var icon_label = $Panel/HBox/IconLabel
@onready var name_label = $Panel/HBox/VBox/NameLabel
@onready var reward_label = $Panel/HBox/VBox/RewardLabel
@onready var panel = $Panel

var display_time: float = 3.0
var slide_in_time: float = 0.3
var slide_out_time: float = 0.3

func _ready():
	# Start off-screen (to the right)
	panel.position.x = size.x
	modulate.a = 0.0

func show_achievement(achievement):
	# Set content
	icon_label.text = achievement.icon
	name_label.text = achievement.name
	reward_label.text = "+%d coins" % achievement.reward_coins

	# Slide in animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:x", 0, slide_in_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, slide_in_time)

	# Wait, then slide out
	await get_tree().create_timer(display_time).timeout

	var tween_out = create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property(panel, "position:x", size.x, slide_out_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween_out.tween_property(self, "modulate:a", 0.0, slide_out_time)

	await tween_out.finished
	queue_free()
