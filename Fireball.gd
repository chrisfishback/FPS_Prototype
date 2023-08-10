extends Node3D

signal player_hit(dam, player_hurt)

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D
@onready var particles = $GPUParticles3D
@export var damage = 1

const SPEED = 40.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
	
	if ray.is_colliding():
		mesh.visible = false
		particles.emitting = true
		ray.enabled = true
		print("Collision is in group Player? %s" % str(ray.get_collider().is_in_group("player")))
		if ray.get_collider().is_in_group("player"):
			emit_signal("player_hit", damage, ray.get_collider())
		
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_timer_timeout():
	queue_free()
