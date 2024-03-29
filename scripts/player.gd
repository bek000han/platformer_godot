extends CharacterBody2D

@export var movement_data : PlayerMovementData

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var air_jump = false

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var coyote_jump_timer = $CoyoteJumpTimer

func _physics_process(delta):
	apply_gravity(delta)
	handle_jump()
	var input_axis = Input.get_axis("move_left", "move_right")
	handle_acceleration(input_axis, delta)
	handle_air_acceleration(input_axis, delta)
	handle_wall_jump()
	apply_friction(input_axis, delta)
	apply_air_resistance(input_axis, delta)
	update_animations(input_axis)
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0
	if (just_left_ledge):
		coyote_jump_timer.start()
	if Input.is_action_just_pressed("powerup"):
		movement_data = load("res://scripts/resources/FastMovement.tres")

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * movement_data.gravity_scale * delta 

func handle_wall_jump():
	if is_on_wall():
		if not is_on_floor():
			air_jump = true
			
		var wall_normal = get_wall_normal()
		var left_angle = abs(wall_normal.angle_to(Vector2.LEFT))
		var right_angle = abs(wall_normal.angle_to(Vector2.RIGHT))
		
		if Input.is_action_just_pressed("move_left") and (wall_normal.is_equal_approx(Vector2.LEFT) or left_angle < 10.0):
			velocity.x = wall_normal.x * movement_data.speed
			velocity.y = movement_data.jump_velocity * 0.8
		
		if Input.is_action_just_pressed("move_right") and (wall_normal.is_equal_approx(Vector2.RIGHT) or right_angle < 10.0):
			velocity.x = wall_normal.x * movement_data.speed
			velocity.y = movement_data.jump_velocity * 0.8

func handle_jump():
	if is_on_floor():
		air_jump = true
	
	if is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_just_pressed("jump_key") or Input.is_action_just_pressed("jump_key2"):
			velocity.y = movement_data.jump_velocity
			
	if not is_on_floor():
		if Input.is_action_just_released("jump_key") and velocity.y < movement_data.jump_velocity / 2:
			velocity.y = movement_data.jump_velocity / 2
		
		if movement_data.can_air_jump and Input.is_action_just_pressed("jump_key") and air_jump:
			velocity.y = movement_data.jump_velocity * 0.8
			air_jump = false

func handle_acceleration(input_axis, delta):
	if not is_on_floor(): return
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.acceleration * delta)

func handle_air_acceleration(input_axis, delta):
	if is_on_floor(): return
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.air_acceleration * delta)

func apply_friction(input_axis, delta):
	if input_axis == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)

func apply_air_resistance(input_axis, delta):
	if input_axis == 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)

func update_animations(input_axis):
	if input_axis != 0:
		animated_sprite_2d.flip_h = (input_axis < 0);
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
	
	if not is_on_floor():
		animated_sprite_2d.play("jump_mid")
