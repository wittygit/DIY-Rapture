extends Node3D
var speed : float = 0.5
var rapturing : bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if rapturing:
		position.y+=speed*delta
		
		
	
