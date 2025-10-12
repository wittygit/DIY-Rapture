extends Node3D
class_name Crucifix

@onready var light= $SpotLight3D
@onready var cone = $Cone

var lit : bool = true
var light_energy : float
var usage_rate : float = 1

var light_cone_material : Material
var beamStrength : float

@export var noise1 : Noise
@export var noise2 : Noise

func _ready():
	light_energy = light.light_energy
	light_cone_material = cone.material_override

func _process(delta):
	if lit:
		beam()
		if beamStrength>.1:
			for enemy in enemies_within_area:
				enemy.Wither(3.0)
	else:
		light_cone_material.set("shader_parameter/energy", 0)

func beam():
	light.light_energy = beamStrength * 2
	light_cone_material.set("shader_parameter/energy", beamStrength)
	light_cone_material.set("shader_parameter/feather_intensity", .433+.5/beamStrength)
	light_cone_material.set("shader_parameter/feather_sharpness", 3*beamStrength)


var enemies_within_area = []
func _on_area_3d_body_entered(body):

	if body is Enemy:
		enemies_within_area.append(body)

func _on_area_3d_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	enemies_within_area.erase(body)
