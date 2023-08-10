extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var fire_cast = $Camera3D/Staff/FireCast
@onready var ray =  $Camera3D/RayCast3D

var health = 3

const SPEED = 8.0
const JUMP_VELOCITY = 6.5

var Fireball = preload("res://fireball.tscn")
var instance

var gravity = 12.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	anim_player.play("idle")
	
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

#func _process(delta):
#	if ray.is_colliding:
#			var hit_player = ray.get_collider()
#			if hit_player:
#				hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority()) #call only for player being hit

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		# shoot fireball
		shoot.rpc()

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	fire_cast.restart()
	fire_cast.emitting = true

func receive_damage(damage, hurt_player):
	if hurt_player:
		hurt_player.take_and_emit_damage.rpc_id(hurt_player.get_multiplayer_authority()) #call only for player being hit

@rpc("any_peer")
func take_and_emit_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

@rpc("call_local")
func shoot():
	instance = Fireball.instantiate()
	instance.position = ray.global_position
	instance.transform.basis = ray.global_transform.basis
	get_parent().add_child(instance)
	instance.player_hit.connect(receive_damage)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
