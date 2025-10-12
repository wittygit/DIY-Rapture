class_name Tile

var forward : int = -1
var right : int = -1
var back : int =-1
var left : int = -1
var up : int = -1
var down : int = -1

func _init(Forward = -1, Back = -1, Left = -1, Right = -1, Up = -1, Down = -1) -> void:
	forward = Forward
	back = Back
	left = Left
	right = Right
	up = Up
	down = Down

func Cement():
	if forward == -1: forward = 0
	if back == -1: back = 0
	if left == -1: left = 0
	if right == -1: right = 0
	if up == -1: up = 0
	if down == -1: down = 0

func Print():
	print(str(forward) + ' ' + str(back) + ' ' + str(left) + ' ' + str(right))

func Value()->int:
	return forward+1+(1+back*10)+(1+left*100)+(1+right*1000)+(1+up*10000)+(1+down*100000)
	
