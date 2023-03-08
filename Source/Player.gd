extends CharacterBody2D

## A 2D Platform Player Controller
## 
## The player can move, jump and wall jump. A set of variables are used to
## make the moviment more fluid and customizable to every need.

## Detects if there is a wall to the right of the player
@onready var ray_r : RayCast2D = $RayR
## Detects if there is a wall to the left of the player
@onready var ray_l : RayCast2D = $RayL

## Set of variables to control the player
@export_category("Player Config.")
@export_group("Movement")
## Max. speed on x axis
@export var max_speed = 400.0
## Acceleration on the x axis
@export var acceleration = 800.0
## Desacceleration on the x axis
@export var deceleration = 800.0
## Desacceleration when turning
@export var decel_turning = 1600.0
## Desacceleration when turning in the air
@export var decel_turning_air = 2400.0

@export_group("Jump")
@export_subgroup("Acceleration")
## Upward speed at the moment of the jump
@export var jump_impulse = -400.0
## Gravity when the player is going up
@export var gravity_up = 735.0
## Gravity when the player is at the apex of the jump
@export var gravity_apex = 490.0
## Gravity when the player is going down
@export var gravity_down = 980.0
## Gravity when the player cancel the jump
@export var gravity_cancel = 1960.0
@export_subgroup("Speed")
## Max. fall speed
@export var max_fall_speed = 600.0
## Max. fall speed on the wall. When set to 0.0, the player will not fall off the wall.
@export var max_fall_speed_wall = 100.0
## Defines the range from which the jump parabola will be considered as the apex.
## When set to 0.0, only the exact moment when the player stops rising to fall
## will be considered the apex (Will likely be ignored, since velocity.y can go
## from a negative number to a positive number in one frame).
@export var max_apex_vel = 30.0

## Holds the current gravity value
var gravity = 0
## If True, player canceled the jump before the apex
var jump_canceled = false

## Time in which the player can jump after leaving the floor. In other words,
## if the player presses the jump button a few frames after leaving the floor
## or falling, the jump will still be performed
var coyote_time = 0.1
## Serves as Coyote Timer
var coyote_counter = 0.0

## Time in which the player can jump before touching the floor. In other words,
## if the player presses the jump button a few frames before touching the floor,
## the jump will be executed as soon as he touches the ground.
var jump_buffer_time = 0.1
## Serves as Jump Buffer Timer
var jump_buffer_counter = 0.0

func _physics_process(delta):
	# Reset flags/timer
	if is_on_floor():
		coyote_counter = coyote_time
		jump_canceled = false
	elif ray_r.is_colliding() or ray_l.is_colliding():
		jump_canceled = false
	
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction: # Moving
		if (direction > 0 and velocity.x < 0) or (direction < 0 and velocity.x > 0): # Turning
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, decel_turning * delta)
			else: # Turn faster when in the air
				velocity.x = move_toward(velocity.x, 0, decel_turning_air * delta)
		else: # Speed up
			velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else: # Stoping
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump"): # Player pressed jump button
		jump_buffer_counter = jump_buffer_time
	if jump_buffer_counter > 0:
		if coyote_counter > 0: # Jump
			velocity.y = jump_impulse
			coyote_counter = 0
			jump_buffer_counter = 0
		elif (ray_r.is_colliding() or ray_l.is_colliding()) and not is_on_floor(): # Wall Jump
			velocity.x = -max_speed if ray_r.is_colliding() else max_speed
			velocity.y = jump_impulse
			jump_buffer_counter = 0
	if Input.is_action_just_released("jump") and velocity.y < 0: # Jump canceled
		jump_canceled = true
	
	# Calculate gravity
	if velocity.y > -max_apex_vel and velocity.y < max_apex_vel:
		gravity = gravity_apex
	elif velocity.y < 0: # Going up
		gravity = gravity_cancel if jump_canceled else gravity_up
	else: # vel.y >= 0 - Going down
		gravity = gravity_down
	# Apply gravity
	if (ray_r.is_colliding() or ray_l.is_colliding()) and not is_on_floor(): # If is_on_wall
		velocity.y = move_toward(velocity.y, max_fall_speed_wall, gravity * delta)
	else:
		velocity.y = move_toward(velocity.y, max_fall_speed, gravity * delta)
	
	# Update timers
	coyote_counter -= delta
	jump_buffer_counter -= delta
	
	move_and_slide()
