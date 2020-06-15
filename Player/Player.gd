extends KinematicBody2D

onready var anim_sprite = get_node("AnimatedSprite")
onready var left_raycast = get_node("Left RayCast")
onready var middle_raycast = get_node("Middle RayCast")
onready var right_raycast = get_node("Right RayCast")
onready var raycasts = [left_raycast, middle_raycast, right_raycast]
onready var collision_shape = get_node("CollisionShape2D")

var velocity = Vector2()
var jump_pressed = false

export (Curve) var acc_curve
export (Curve) var friction_curve
export (Curve) var anim_speed_curve

const rotation_weight = 0.2

const COYOTE_MAX_TIME = 0.1
var coyote_timer = 0
var can_jump = false

var pressedTime = 0.3 #in seconds, anti input frustration value
var jumpPressedTimer=10

var input_velocity = 0

func _physics_process(delta):
	input_velocity = 0
	get_input()
	movement(delta)
	check_if_in_void()
	animate()
	set_player_scale()
	Engine.time_scale = global.time_scale.real_value

func set_player_scale():
	$AnimatedSprite.scale = 3 * Vector2(global.player_size.real_value, global.player_size.real_value)
	$CollisionShape2D.shape.extents = Vector2(20, 29) * global.player_size.real_value
	$"Left RayCast".position = Vector2(-16, 0) * global.player_size.real_value
	$"Right RayCast".position = Vector2(16, 0) * global.player_size.real_value
	for raycast in raycasts:
		raycast.cast_to = Vector2(0, 80) * global.player_size.real_value

func get_input():
	# Movement
	if Input.is_action_pressed("move_right"):
		input_velocity += 1
	if Input.is_action_pressed("move_left"):
		input_velocity -= 1
	
	if global.player_max_speed.real_value != 0:
		var normalized_speed = range_lerp(velocity.x, 0, global.player_max_speed.real_value, 0, 1)
		var acc = acc_curve.interpolate(abs(normalized_speed)) * global.player_max_acc.real_value
		velocity.x += input_velocity * acc
	
	jump_pressed = false
	if Input.is_action_just_pressed("jump") if not global.player_fly.real_value else Input.is_action_just_pressed("jump"):
		jump_pressed = true

func movement(delta):
	if not is_on_floor() if global.gravity.real_value > 0 else true:
		if global.gravity.real_value > 0:
			velocity.y += global.gravity.real_value * delta
		elif global.gravity.real_value < 0:
			velocity.y -= global.gravity.real_value * delta
	# Friction
	if global.player_max_speed.real_value != 0:
		var normalized_speed = range_lerp(velocity.x, 0, global.player_max_speed.real_value, 0, 1)
		var friction = friction_curve.interpolate(abs(normalized_speed)) * global.player_max_friction.real_value
		velocity.x -= sign(velocity.x) * friction
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.name == "Spikes":
			die()
	
	if is_on_floor():
		can_jump = true
		coyote_timer = 0
	else:
		coyote_timer += delta
		jumpPressedTimer+=delta
	
	if coyote_timer > COYOTE_MAX_TIME:
		can_jump = false
	
	if jump_pressed:
		jumpPressedTimer=0
	
	if (can_jump || global.player_fly.real_value) and jump_pressed and jumpPressedTimer<=pressedTime:
		jump()

func jump():
	jumpPressedTimer=1000
	velocity.y -= global.player_jump_speed.real_value if not global.player_fly.real_value else global.player_fly_speed.real_value
	$"Jump SFX".play()

func check_if_in_void():
	if position.y >= 1000:
		global.restart()

func animate():
	var moving = abs(velocity.x) > 0
	if moving:
		anim_sprite.flip_h = velocity.x < 0
	
	var normal = get_average_normal()
	var angle
	if normal != Vector2.ZERO:
		angle = lerp(anim_sprite.rotation, normal.angle() + TAU/4, rotation_weight)
	else:
		angle = lerp(anim_sprite.rotation, 0, rotation_weight)
	anim_sprite.rotation = angle
	collision_shape.rotation = angle
	
	if not any_raycasts_colliding():
		if velocity.y < 0:
			anim_sprite.play("Jump")
		else:
			anim_sprite.play("Fall")
		
		return
	
	if input_velocity != 0 and moving:
		var speed_scale = anim_speed_curve.interpolate(abs(velocity.x)/1000)
		anim_sprite.speed_scale = speed_scale
		anim_sprite.frames.set_animation_loop("Walk", true)
		anim_sprite.play("Walk")
	else:
		anim_sprite.play("Idle")

func hurt(damage):
	global.player_health.value = str(int(global.player_health.value) - damage)
	if global.player_health.real_value < 0:
		die()

func die():
	if get_tree().reload_current_scene() != OK:
		print_debug("An error occured while attempting to reload the current scene.")

func any_raycasts_colliding():
	for raycast in raycasts:
		if raycast.is_colliding():
			return true
	return false

func all_raycasts_colliding():
	for raycast in raycasts:
		if not raycast.is_colliding():
			return false
	return true

func get_average_normal():
	if all_raycasts_colliding():
		return (left_raycast.get_collision_normal() + middle_raycast.get_collision_normal() + right_raycast.get_collision_normal())/3
	return Vector2.ZERO

func knockback(amount, dir):
	velocity += Vector2(amount, 0).rotated(dir.angle())
