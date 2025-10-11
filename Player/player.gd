extends CharacterBody3D
@onready var tripod = $Tripod
@onready var cam = $Tripod/Camera3D

const FOV_MULT = 1.5

var speed = 4

var bobFreq = 2
var bobAmp = 0.06
var bobTime: float = 0
var baseFov = 80


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _process(delta):
	pass


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("exit"):
		get_tree().quit()

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (tripod.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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
	
