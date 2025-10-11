extends Node3D
class_name Crucifix

@onready var light= $SpotLight3D
@onready var cone = $Cone

var lit : bool = true
var light_energy : float
var battery_level : float = 100
var usage_rate : float = 1


var light_cone_material : Material

@export var noise1 : Noise
@export var noise2 : Noise

func _ready():
	light_energy = light.light_energy
	light_cone_material = cone.material_override

func _process(delta):
	if lit:
		flicker(delta)
	pass

func flicker(delta : float):
	var energy = clamp(1-pow(noise2.get_noise_1d(Time.get_ticks_msec()/50.),2)+2*noise1.get_noise_1d(Time.get_ticks_msec()/50.),0,1)
	light.light_energy = energy
	light_cone_material.set("shader_parameter/energy", energy)
