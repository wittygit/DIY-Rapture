extends Node3D

@export var monks:Array[Node]=[]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for monk in monks:
		monk.rapturing = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
