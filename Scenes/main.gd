extends Node

var path = "C:/Users/GC Arcade Public/Downloads/Launcher/Arcade Launcher.exe"

var lastInputTime = 0
var maxTime = 45
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("Quit"):
		quit()
	else:
		lastInputTime = Time.get_ticks_msec()/1000
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Time.get_ticks_msec()/1000 - lastInputTime > maxTime:
		print("timeout")
		quit()
	

func quit():
	var args = []
	var blocking = false
	var pid = OS.create_process(path,args)
	get_tree().quit()
