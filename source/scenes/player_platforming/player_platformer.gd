extends KinematicBody2D

# Create an enum with a list of states.
enum States {NORMAL, WALL_SLIDE}

# Declare a variable that determines the player's current state.
var state = States.NORMAL

# Declare the velocity, which will be used to calculate movement speed.
var velocity = Vector2(0, 0)
var max_velocity = Vector2(250, 1000)

# Declare a variable that determines if the player is facing right.
var facing_right = false

# Declare constants that change how the mechanics work.
const WALK_SPEED = 100
const INIT_WALK_SPEED = 400
const RUN_SPEED = 700
const BRAKE_SPEED = 580
const JUMP_FORCE = 1200
const GRAVITY = 3000
const MAX_WALL_SLIDE_SPEED = 400

# Declare variables for nodes that will be used.
onready var run_timer = $"RunTimer"
onready var run_slowdown_timer = $"RunSlowdownTimer"
onready var jump_timer = $"JumpTimer"
onready var grounded_timer = $"GroundedTimer"

# Declare variables for nodes used in this script.
onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite

# Create a function for moving.
func move():
	velocity = move_and_slide(Vector2(velocity.x, velocity.y), Vector2(0, -1), true)

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

	if state == States.WALL_SLIDE:
		# Apply force to the wall, so the engine recognizes the player is
		# touching the wall.
		if facing_right:
			velocity.x += 10
		else:
			velocity.x -= 10
		# Make the player slide down the wall at increasing speeds.
		velocity.y += 100 * delta
		# Stop the player from sliding down faster than the max wall slide
		# speed.
		if velocity.y > MAX_WALL_SLIDE_SPEED:
			velocity.y = MAX_WALL_SLIDE_SPEED
		# If the player presses jump, exit the wall slide with a jump.
		if Input.is_action_just_pressed("jump"):
			if facing_right:
				velocity.x = -10
			else:
				velocity.x = 10
			move()
			# The player will get a longer jump if they're holding the run
			# button.
			if facing_right:
				if Input.is_action_pressed("run"):
					velocity.x = -500
				else:
					velocity.x = -300
			elif Input.is_action_pressed("run"):
				velocity.x = 500
			else:
				velocity.x = 300
			velocity.y = -JUMP_FORCE
			state = States.NORMAL
			return
		move()
		# If the player presses down, touches the floor, or is no longer on a
		# wall, simply cancel the wall jump without doing anything.
		if Input.is_action_just_pressed("down") or is_on_floor() or is_on_wall() == false:
			velocity.x = 0
			velocity.y = 0
			state = States.NORMAL

	if Input.is_action_pressed("run"):
		run_timer.start()
		max_velocity = Vector2(500, 1000)
	else:
		max_velocity = Vector2(250, 1000)

	if state == States.NORMAL:
		if Input.is_action_pressed("right"):
			# Increase right velocity if right is pressed. Also, gain right
			# velocity faster if the player has left velocity, to create "braking".
			if velocity.x < 0:
				velocity.x += BRAKE_SPEED * delta
			elif run_timer.time_left > 0:
				velocity.x += RUN_SPEED * delta
			elif velocity.x < 50:
				velocity.x += INIT_WALK_SPEED * delta
			else:
				velocity.x += WALK_SPEED * delta
			# Stop the player from gaining more right velocity than the maximum
			# amount.
			if velocity.x > max_velocity.x and run_slowdown_timer.time_left > 0:
				velocity.x -= 300 * delta
			elif run_timer.time_left > 0 and not Input.is_action_pressed("run"):
				run_slowdown_timer.start()
			elif velocity.x > max_velocity.x:
				velocity.x = max_velocity.x
		elif Input.is_action_pressed("left"):
			if velocity.x > 0:
				velocity.x -= BRAKE_SPEED * delta
			elif run_timer.time_left > 0:
				velocity.x -= RUN_SPEED * delta
			elif velocity.x > -50:
				velocity.x -= INIT_WALK_SPEED * delta
			else:
				velocity.x -= WALK_SPEED * delta
			# Stop the player from gaining more right velocity than the maximum
			# amount.
			if velocity.x < -max_velocity.x and run_slowdown_timer.time_left > 0:
				velocity.x -= 300 * delta
			elif run_timer.time_left > 0 and not Input.is_action_pressed("run"):
				run_slowdown_timer.start()
			elif velocity.x < -max_velocity.x:
				velocity.x = -max_velocity.x

		else:
			# This else block will be ran when neither right or left is pressed.

			# If the x velocity is between -10 and 10, simply set the x velocity
			# to 0.
			if not velocity.x > 10 and not velocity.x < -10:
				velocity.x = 0
			# If the player still has x velocity and it is not between -10 and 
			# 10, make them lose their speed..
			if velocity.x > 0:
				velocity.x -= BRAKE_SPEED * delta
			if velocity.x < 0:
				velocity.x += BRAKE_SPEED * delta
	
		# Indicate whether or not the player was grounded in the last 0.18
		# seconds.
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
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= 0.4
		# If jump was pressed in the last 0.18 seconds and the player was 
		# grounded in the last 0.18 seconds, jump.
		if grounded and jump_timer.time_left > 0:
			jump_timer.stop()
			grounded_timer.stop()
			velocity.y = -JUMP_FORCE
		# Stop the player from accumulating y velocity while on the ground.
		if grounded and velocity.y > 0:
			velocity.y = 0
		# Stop the player from falling faster than the maximum fall speed.
		if velocity.y > max_velocity.y:
			velocity.y = max_velocity.y
	
		# Flip the player when they change directions.
		if facing_right and velocity.x < 0:
			flip()
		if not facing_right and velocity.x > 0:
			flip()
	
		# Apply gravity to the player's y velocity.
		velocity.y += GRAVITY * delta
	
		if is_on_ceiling():
			# Set the player's y velocity to 0 when they hit a ceiling, so they'll
			# immediately start falling if they hit a ceiling.
			velocity.y = 0
		if is_on_wall():
			# If the player has x velocity and jumps into a wall, start a wall
			# slide/wall jump.
			if not grounded and not velocity.x == 0:
				velocity.x = 0
				velocity.y = 0
				state = States.WALL_SLIDE
			else:
				# Set the player's x velocity to 0 when they hit a wall, so 
				# they can't build up speed by running against a wall.
				velocity.x = 0
		# Move based on the current x and y velocity.
		move()
	
	# Play animations.
	if state == States.WALL_SLIDE:
		play_animation("wall slide")
	elif is_on_floor():
		if velocity.x == 0:
			play_animation("idle")
		elif Input.is_action_pressed("run"):
			play_animation("run")
		else:
			play_animation("walk")
	elif velocity.y < 0:
		play_animation("jump")
	else:
		play_animation("fall")
