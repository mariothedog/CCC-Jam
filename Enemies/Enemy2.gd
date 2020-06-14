extends KinematicBody2D

onready var anim_sprite = get_node("AnimatedSprite")
onready var raycast = get_node("RayCast2D")
onready var right_raycast = get_node("Right Raycast")
onready var left_raycast = get_node("Left Raycast")
onready var up_raycast = get_node("Up Raycast")


var velocity = Vector2()  
const RIGHT = 1
const LEFT = -1
var dir = [RIGHT, LEFT][global.random_int(0, 2)]

var dead = false

func _ready():
	raycast.position.x *= dir

func _physics_process(delta):
	if not dead:
		movement(delta)
		animate()

func movement(delta):
	if is_on_floor():
		velocity.x = global.enemy_max_speed.real_value * dir
	else:
		velocity.x = 0
	velocity.y += global.gravity.real_value * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if not raycast.is_colliding() and is_on_floor():
		dir *= LEFT
		raycast.position.x *= LEFT
	
	if is_on_wall():
		dir *= LEFT
		raycast.position.x *= LEFT
	# If trapped (may be due to the falling tiles).
	if right_raycast.is_colliding() and left_raycast.is_colliding() and up_raycast.is_colliding():
		die()

func animate():
	if abs(velocity.x) > 0:
		anim_sprite.flip_h = velocity.x < 0
		anim_sprite.frames.set_animation_loop("Walk", true)
		anim_sprite.play("Walk")
	else:
		anim_sprite.frames.set_animation_loop("Walk", false)

func die():
	$"Death SFX".play()
	visible = false
	dead = true
	yield($"Death SFX", "finished")
	queue_free()

func _on_Die_Zone_body_entered(body):
	if body.has_method("knockback") and not dead:
		body.knockback(global.player_damage_bounce.real_value, Vector2.UP)
		die()

func _on_Kill_Zone_body_entered(body):
	if body.name == "Player" and not dead:
		body.hurt(1)


func _on_ViewPort_body_shape_entered(body_id, body, body_shape, area_shape):
	velocity.x = global.enemy_max_speed.real_value * body.position.x
