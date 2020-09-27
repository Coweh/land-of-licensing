extends Node

# Declare variables for the nodes that will be used in this script.
onready var tween = $"../Foreground/Tween"
onready var foreground_rect = $"../Foreground/ForegroundRect"
onready var game_logo = $"../Foreground/Game Logo"
onready var sih_logo = $"../Foreground/SIH Logo"

func _ready():
	# Wait for a moment to pass, queue free the Shapes in Hats logo, wait for 
	# another moment, make the game's logo appear, then queue it free.
	# The logos are freed from the scene tree instead of simply hiding 
	# themselves because they're no longer needed in the scene.
	yield(get_tree().create_timer(2.5), "timeout")
	sih_logo.queue_free()
	yield(get_tree().create_timer(1), "timeout")
	game_logo.show()
	yield(get_tree().create_timer(2.5), "timeout")
	game_logo.queue_free()
	yield(get_tree().create_timer(1.5), "timeout")
	# Use tweening to fade the foreground out.
	tween.interpolate_property(foreground_rect, "modulate", foreground_rect.color, Color(10.0, 10.0, 10.0, 0), 1)
	tween.start()

func _on_Tween_tween_all_completed():
	# Queue free the no longer needed Tween and ForegroundRect nodes.
	tween.queue_free()
	foreground_rect.queue_free()
