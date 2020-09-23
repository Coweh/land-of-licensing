extends Node

# Declare variables for the nodes that will be used in this script.
onready var fade = $"../Foreground/Fade"
onready var game_logo = $"../Foreground/Game Logo"
onready var sih_logo = $"../Foreground/SIH Logo"

# Wait for a moment to pass, queue free the Shapes in Hats logo, wait for another moment, make the game's logo appear, make it disappear, and then
func _ready():
	yield(get_tree().create_timer(2.5), "timeout")
	sih_logo.queue_free()
	yield(get_tree().create_timer(1), "timeout")
	game_logo.show()
	yield(get_tree().create_timer(2.5), "timeout")
	game_logo.queue_free()
	yield(get_tree().create_timer(1), "timeout")
	fade.play()

# Queue free the fade node once it isn't needed anymore.
func _on_Fade_animation_finished():
	fade.queue_free()
# uh
