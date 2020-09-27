extends KinematicBody2D

# Declare variables for nodes that will be used.
onready var run_timer = $"RunTimer"
onready var run_slowdown_timer = $"RunSlowdownTimer"
onready var jump_timer = $"JumpTimer"
onready var grounded_timer = $"GroundedTimer"

# Declare the x and y velocity, which will be used to calculate movement speed.
var y_velocity = 0
var x_velocity = 0

# Declare constants that change how the mechanics work.
const WALK_SPEED = 100
const INIT_WALK_SPEED = 400
const RUN_SPEED = 700
const BRAKE_SPEED = 580
const JUMP_FORCE = 1200
const GRAVITY = 50
const MAX_FALL_SPEED = 1000

# Declare variables for nodes used in this script.
onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite

# Declare a variable that determines if the player is facing right.
var facing_right = false

# Create a function for flipping the player.
func flip():
	facing_right = not facing_right
	sprite.flip_h = not sprite.flip_h

# Create a function for playing animations.
func play_animation(animation_name):
	if animation_player.is_playing() and animation_player.current_animation == animation_name:
		return
	animation_player.play(animation_name)

func _physics_process(delta):
	# Declare variables for the minimum and maximum x velocity, so the player
	# can't just build up infinite velocity.
	var MAX_X_VELOCITY
	var MIN_X_VELOCITY

	if is_on_ceiling():
		# Set the player's y velocity to 0 when they hit a ceiling, so they'll
		# immediately start falling if they hit a ceiling.
		y_velocity = 0
	if is_on_wall():
		# Set the player's x velocity to 0 when they hit a wall, so they can't
		# build up speed by running against a wall.
		x_velocity = 0
	
	if Input.is_action_pressed("run"):
		run_timer.start()
		MAX_X_VELOCITY = 500
		MIN_X_VELOCITY = -500
	else:
		MAX_X_VELOCITY = 250
		MIN_X_VELOCITY = -250

	if Input.is_action_pressed("right"):
		# Increase right velocity if right is pressed. Also, gain right
		# velocity faster if the player has left velocity, to create "braking".
		if x_velocity < 0:
			x_velocity += BRAKE_SPEED * delta
		elif run_timer.time_left > 0:
			x_velocity += RUN_SPEED * delta
		elif x_velocity < 50:
			x_velocity += INIT_WALK_SPEED * delta
		else:
			x_velocity += WALK_SPEED * delta
		# Stop the player from gaining more right velocity than the maximum
		# amount.
		if x_velocity > MAX_X_VELOCITY and run_slowdown_timer.time_left > 0:
			x_velocity -= 300 * delta
		elif run_timer.time_left > 0 and not Input.is_action_pressed("run"):
			run_slowdown_timer.start()
		elif x_velocity > MAX_X_VELOCITY:
			x_velocity = MAX_X_VELOCITY
	elif Input.is_action_pressed("left"):
		# The same as above, but with left velocity, not right velocity.
		if x_velocity > 0:
			x_velocity -= BRAKE_SPEED * delta
		elif run_timer.time_left > 0:
			x_velocity -= RUN_SPEED * delta
		elif x_velocity > -50:
			x_velocity -= INIT_WALK_SPEED * delta
		else:
			x_velocity -= WALK_SPEED * delta
		if x_velocity < MIN_X_VELOCITY and run_slowdown_timer.time_left > 0:
			x_velocity += 300 * delta
		elif run_timer.time_left > 0 and not Input.is_action_pressed("run"):
			run_slowdown_timer.start()
		elif x_velocity < MIN_X_VELOCITY:
			x_velocity = MIN_X_VELOCITY

	else:
		# This else block will be ran when neither right or left is pressed.

		# If the x velocity is between -10 and 10, simply set the x velocity to 
		# 0.
		if not x_velocity > 10 and not x_velocity < -10:
			x_velocity = 0
		# If the player still has x velocity and it is not between -10 and 10,
		# make them slow down.
		if x_velocity > 0:
			x_velocity -= BRAKE_SPEED * delta
		if x_velocity < 0:
			x_velocity += BRAKE_SPEED * delta

	# Indicate whether or not the player was grounded in the last 0.18 seconds.
	var grounded
	if is_on_floor():
		grounded_timer.start()
	if grounded_timer.time_left > 0:
		grounded = true
	else:
		grounded = false
	if Input.is_action_just_pressed("jump"):
		jump_timer.start()
	# If jump is released while jumping, the jump height will be shorter
	# than if it had been held.
	if Input.is_action_just_released("jump") and y_velocity < 0:
		y_velocity *= 0.4
	# If jump was pressed in the last 0.18 seconds and the player was 
	# grounded in the last 0.18 seconds, jump.
	if grounded and jump_timer.time_left > 0:
		jump_timer.stop()
		grounded_timer.stop()
		y_velocity = -JUMP_FORCE
	# Stop the player from accumulating y velocity while on the ground.
	if grounded and y_velocity > 0:
		y_velocity = 0
	# Stop the player from falling faster than the maximum fall speed.
	if y_velocity > MAX_FALL_SPEED:
		y_velocity = MAX_FALL_SPEED

	# Flip the player when they change directions.
	if facing_right and x_velocity < 0:
		flip()
	if not facing_right and x_velocity > 0:
		flip()

	# Apply gravity to the player's y velocity.
	y_velocity += GRAVITY

	# Move based on the current x and y velocity.
# warning-ignore:return_value_discarded
	move_and_slide(Vector2(x_velocity, y_velocity), Vector2(0, -1), true)
	
	# Play animations.
	if grounded:
		if x_velocity == 0:
			play_animation("idle")
		elif Input.is_action_pressed("run"):
			play_animation("run")
		else:
			play_animation("walk")
	elif y_velocity < 0:
		play_animation("jump")
	else:
		play_animation("fall")
