extends RigidBody3D
class_name CharacterObject

@export var base_mass: float = 1.0
@export var base_friction: float = 0.5

func _ready():
	mass = base_mass
	# Friction is usually defined in PhysicsMaterial, 
	# but we can ensure standard behavior here.
	if not physics_material_override:
		physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = base_friction
