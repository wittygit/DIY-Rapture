extends CharacterBody3D
class_name Player
@onready var crucifix_pivot = $Tripod/crucifixPivot
@onready var bell: AudioStreamPlayer = $AudioStreamPlayer
@onready var hurt: AudioStreamPlayer = $AudioStreamPlayer2

@onready var crucifix : Crucifix = $Tripod/crucifixPivot/crucifix

@onready var crucifix_active_pos = $Tripod/crucifixActivePos
var crucifix_base_pos : Vector3
@onready var console: Console = $"../../Console"

@export var sens : Vector2 = Vector2(3, 2)

@export var maxCamTilt : float = 50
@export var minCamTilt : float = -50
@export var crucifix_snapiness : float = 8
@export var crucifix_speed : float = 6
@export var look_snapiness : float = 5
const RESTART = preload("uid://bbsqxsle31m3d")

@onready var tripod = $Tripod
@onready var cam = $Tripod/Camera3D
@onready var color_rect: ColorRect = $"../.."

const FOV_MULT: float = 1.5
var gravity : Vector3 = Vector3(0,-9.8,0)
var speed : float = 4
var walking_speed: float = 4
var crucifixing_speed : float = 1.5
var is_moving : bool = false
var is_crucifixing : bool = false

var bobFreq = 2
var bobAmp = 0.06
var bobTime: float = 0
var baseFov = 80

var messages = ["The Rapture begins.","Alas, I have been Foresaken.","I must ascend through the darkness to reach The Light.","Climb to the fifth floor to Rapture yourself and rejoin your Order.", "Use the left button to move forward and hold the right button to defend yourself."]
var current_message = 0
var message_duration : float = 6
var time : float = 0
var crucifix_global_goal_rot : Vector3 = Vector3.FORWARD
var health: float = 20
var health_smoothed : float

var look_force : Vector2
var rapturing: bool = false

const RAY_LENGTH : float = 2
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ambience: AudioStreamPlayer = $AudioStreamPlayer3

var current_floor : int = 1

func _ready():
	crucifix_base_pos = crucifix_pivot.position
	await get_tree().create_timer(30).timeout
	ambience.play()


func rapture():
	rapturing = true
	collision_layer = 5
	collision_mask = 5
	collision_shape.disabled = true
	ambience.stop()
	

func _physics_process(delta):
	health_smoothed = lerp(health_smoothed,health,delta*20)
	color_rect.material.set("shader_parameter/radius", 1-health_smoothed/20)
	color_rect.material.set("shader_parameter/speed", 1-health_smoothed/20)
	time += delta
	health+=delta/2
	health = min(health,20)
	if time > message_duration:
		if current_message<messages.size():
			console.SendMessage(messages[current_message], message_duration, Color.BLACK)
			current_message+=1
			time = 0

	
	
	handleInput()
	crucifix_global_goal_rot.y += look_force.x*delta*sens.x
	crucifix_global_goal_rot.x += -look_force.y*delta*sens.y
	
	crucifix_global_goal_rot.x = clamp(crucifix_global_goal_rot.x, deg_to_rad(minCamTilt), deg_to_rad(maxCamTilt))
	
	aimCrucifix(delta)
	aimHead(delta)
	if rapturing:
		velocity+=Vector3(0,1,0)*.3*delta
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity += gravity * delta

	if Input.is_action_pressed("exit"):
		get_tree().quit()

	var direction
	if (is_moving): direction = (transform.basis * Vector3.FORWARD).normalized()
	else:
		direction = Vector3.ZERO
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2)
		 
	#bob time!!!!!
	bobTime += delta * velocity.length() * float(is_on_floor()) # basically the bool in a float will give 0 or 1 super clever solution by LegionGames
	cam.transform.origin = head_bob(bobTime)
	
	#fov stuff
	var clampedVelocity = clamp (velocity.length(), 0.5, speed * 2)
	var targetFov = baseFov + FOV_MULT * clampedVelocity
	cam.fov = lerp(cam.fov, targetFov, delta * 7)
	
	move_and_slide()

func head_bob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bobFreq) * bobAmp
	pos.x = cos(time * bobFreq/2) * bobAmp
	return pos

func NextFloor():
	current_floor +=1
	console.SendMessage("Floor "+str(current_floor), 5)
	bell.playing = true

func Damage( impulse : Vector3):
	health-=5
	if health >= -5: 
		hurt.playing = true
		velocity+=impulse*3
	if health< 0 && health>-5: Die()
	
func Die():
	
	health = -100
	bell.playing = true
	console.SendMessage("Left behind, forgotten.", 3.0, Color.DARK_RED)
	await get_tree().create_timer(4).timeout
	get_tree().change_scene_to_file("res://Scenes/restart.tscn")

	
func handleInput():
	look_force.x = Input.get_axis("lookRight", "lookLeft")
	look_force.y = Input.get_axis("lookUp", "lookDown")
	
	if Input.is_action_pressed("forward"):
		is_moving = true
	else:
		is_moving = false
	if Input.is_action_pressed("crucifix"):
		is_crucifixing = true
	else:
		is_crucifixing = false


func aimCrucifix(delta):
	crucifix_pivot.global_rotation.y = (lerp_angle(crucifix_pivot.global_rotation.y,crucifix_global_goal_rot.y, crucifix_snapiness*delta))
	crucifix.global_rotation.x = (lerp_angle(crucifix.global_rotation.x, crucifix_global_goal_rot.x, crucifix_snapiness*delta))
	
	if (is_crucifixing):
		crucifix_pivot.position = (lerp(crucifix_pivot.position, crucifix_active_pos.position, crucifix_snapiness * delta))
		crucifix.beamStrength = (lerp(crucifix.beamStrength,1.0, crucifix_snapiness * delta))
		cam.fov = (lerp(cam.fov,baseFov/10., crucifix_snapiness/3 *delta))
		speed = crucifixing_speed
	else:
		crucifix_pivot.position = (lerp(crucifix_pivot.position, crucifix_base_pos, crucifix_snapiness*delta))
		crucifix.beamStrength = (lerp(crucifix.beamStrength,0.0, crucifix_snapiness * delta))
		cam.fov = (lerp(cam.fov,float(baseFov), crucifix_snapiness * delta))
		speed = walking_speed

func aimHead(delta : float):
	global_rotation.y = (lerp_angle(global_rotation.y ,crucifix_global_goal_rot.y, look_snapiness*delta))
	cam.global_rotation.x = (lerp_angle(cam.global_rotation.x, crucifix_global_goal_rot.x, look_snapiness*delta))

func raycast() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var origin = crucifix.global_position
	var end = origin -crucifix.get_global_transform().basis.z*RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	return space_state.intersect_ray(query)
