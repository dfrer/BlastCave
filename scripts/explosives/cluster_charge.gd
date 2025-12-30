extends ExplosiveBase
class_name ClusterCharge

## Cluster charge that splits into multiple smaller explosions
## Creates a spread pattern for area coverage

@export var cluster_count: int = 5
@export var cluster_spread: float = 3.0
@export var cluster_delay: float = 0.1
@export var sub_blast_force: float = 6.0
@export var sub_blast_radius: float = 2.5

var _clusters_spawned: int = 0

func _ready() -> void:
	explosive_type = "ClusterCharge"
	# Main blast is smaller
	blast_force = 5.0
	blast_radius = 3.0
	falloff_power = 1.5
	upward_bias = 0.1

func explode() -> void:
	# First, do a smaller main explosion
	super.explode()
	
	# Then spawn cluster sub-explosions with delays
	_spawn_clusters()

func _spawn_clusters() -> void:
	for i in range(cluster_count):
		var delay := cluster_delay * float(i)
		get_tree().create_timer(delay).timeout.connect(_spawn_single_cluster.bind(i))

func _spawn_single_cluster(index: int) -> void:
	# Calculate position in a ring around the main explosion
	var angle := (float(index) / float(cluster_count)) * TAU
	var offset := Vector3(
		cos(angle) * cluster_spread,
		randf_range(-0.5, 0.5),
		sin(angle) * cluster_spread
	)
	var cluster_pos := global_position + offset
	
	# Create mini explosion at this position
	_do_mini_explosion(cluster_pos)

func _do_mini_explosion(pos: Vector3) -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = sub_blast_radius
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, pos)
	query.collide_with_areas = true
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider:
			var dir = collider.global_position - pos
			var dist = dir.length()
			
			if dist < sub_blast_radius and dist > 0.001:
				var strength = (1.0 - (dist / sub_blast_radius)) * sub_blast_force
				var impulse = dir.normalized() * strength
				
				var response = 1.0
				if "blast_response" in collider:
					response = collider.blast_response
				
				var final_impulse = impulse * response
				if collider is RigidBody3D:
					collider.apply_central_impulse(final_impulse)
				elif collider.has_method("apply_blast_impulse"):
					collider.apply_blast_impulse(final_impulse)
	
	# Spawn smaller visual effect
	if ParticleLibrary.instance:
		ParticleLibrary.instance.spawn_explosion(get_parent(), pos, "ClusterCharge")
	
	if AudioManager.instance:
		AudioManager.instance.play_explosion(pos, "ClusterCharge", -6.0)
	
	FXHelper.screen_shake(self, 0.1)
