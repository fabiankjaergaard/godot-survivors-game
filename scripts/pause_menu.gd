extends CanvasLayer

@onready var resume_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/ResumeButton
@onready var achievements_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/AchievementsButton
@onready var restart_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/QuitButton

var is_paused: bool = false
var achievements_screen_scene = preload("res://scenes/achievements_screen.tscn")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Stay active when paused
	hide()

	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event):
	# Toggle pause with ESC key
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused

	if is_paused:
		show()
		get_tree().paused = true
		print("Game paused")
	else:
		hide()
		get_tree().paused = false
		print("Game resumed")

func _on_resume_pressed():
	toggle_pause()

func _on_achievements_pressed():
	# Show achievements screen
	var achievements_screen = achievements_screen_scene.instantiate()
	add_child(achievements_screen)
	print("Opening achievements screen")

func _on_restart_pressed():
	print("Restarting game...")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()
