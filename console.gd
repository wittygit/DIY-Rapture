extends Control
class_name Console
@onready var label: RichTextLabel = $RichTextLabel
var tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func SendMessage(message :String, duration :float = 3.0, newColor : Color = Color.BISQUE):
	label.text = message
	label.self_modulate = newColor
	if tween: tween.free()
	var tween = get_tree().create_tween()
	tween.tween_property(label, "self_modulate", Color.TRANSPARENT, duration).set_ease(Tween.EASE_IN)
