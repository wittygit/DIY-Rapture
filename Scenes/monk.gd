extends Node3D
var speed : float = 0.5
var rapturing : bool = false
var killAt: float = 25
var timeInitial: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeInitial = Time.get_ticks_msec()/1000


func _process(delta: float) -> void:
	if rapturing:
		position.y+=speed*delta
		if Time.get_ticks_msec()/1000-timeInitial>killAt:
			queue_free()
		
	
