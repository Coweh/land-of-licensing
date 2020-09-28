# This class is for mobs (outside of battles), such as enemies.
class_name MobPlatformer
extends KinematicBody2D

# Create an enum with a list of states.
enum States {NORMAL, DYING}
# Declare a variable that determines the mob's current state.
var state = States.NORMAL

# Declare the x and y velocity, which will be used to calculate movement speed.
var y_velocity = 0
var x_velocity = 0

# Declare a variable that determines if the mob is facing right.
var facing_right = false

# Create a function for moving.
func move():
# warning-ignore:return_value_discarded
	move_and_slide(Vector2(x_velocity, y_velocity), Vector2(0, -1), true)

# Create a function for flipping the mob. "sprite" is the path to the
# Sprite node the mob uses.
func flip(sprite):
	facing_right = not facing_right
	sprite.flip_h = not sprite.flip_h

# Check if the mob needs to be flipped, and if so, call flip(). "sprite" is,
# again, the path to the Sprite node the mob uses.
func check_flip(sprite):
	if facing_right and x_velocity < 0:
		flip(sprite)
	if not facing_right and x_velocity > 0:
		flip(sprite)

# Create a function for more easily playing animations. "animation_player" is a 
# path to the AnimationPlayer node the mob uses.
func play_animation(animation_player, animation_name):
	if animation_player.is_playing() and animation_player.current_animation == animation_name:
		return
	animation_player.play(animation_name)
