extends Node3D


var map : Dictionary
var MAX_DEPTH : int = 5
const ROOM_WIDTH : int = 22
var spawn_rate: float = .1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMapLevel()
	await instantiateMap()
	spawn_rate +=.2
	MAX_DEPTH = 5
	generateMapLevel()
	await instantiateMap()
	MAX_DEPTH = 7
	spawn_rate +=.2
	generateMapLevel()
	await instantiateMap()
	MAX_DEPTH = 9
	spawn_rate +=.2
	generateMapLevel()
	await instantiateMap()
	generateChurch()


enum directions {
	FORWARD,
	BACK,
	LEFT,
	RIGHT,
	UP,
	DOWN
}
const DEAD_END = preload("uid://dmg46f186pfe4")
const RIGHT_BACK = preload("uid://d1nkqumaerivr")
const FORWARD_LEFT_RIGHT = preload("uid://cc5i1n1q0jxkm")
const FLOOR = preload("uid://drnavsturj7tx")
const FORWARD_BACK = preload("uid://decxof6mo5tym")
const STAIRS = preload("uid://bfrkqssu0yo6j")
const SOUL_EATER = preload("uid://bolotmbmoe3g8")

var RoomScenes : Dictionary = {
	Tile.new(1,1,0,0,0,0).Value(): [FORWARD_BACK,0],
	Tile.new(0,0,1,1,0,0).Value(): [FORWARD_BACK,PI/2],
	Tile.new(0,1,0,1,0,0).Value(): [RIGHT_BACK,0],
	Tile.new(1,0,0,1,0,0).Value(): [RIGHT_BACK,PI/2],
	Tile.new(1,0,1,0,0,0).Value(): [RIGHT_BACK,PI],
	Tile.new(0,1,1,0,0,0).Value(): [RIGHT_BACK,-PI/2],
	Tile.new(1,0,1,1,0,0).Value(): [FORWARD_LEFT_RIGHT,0],
	Tile.new(1,1,1,0,0,0).Value(): [FORWARD_LEFT_RIGHT,PI/2],
	Tile.new(0,1,1,1,0,0).Value(): [FORWARD_LEFT_RIGHT,PI],
	Tile.new(1,1,0,1,0,0).Value(): [FORWARD_LEFT_RIGHT,-PI/2],
	Tile.new(1,0,0,0,0,0).Value(): [DEAD_END,0],
	Tile.new(0,1,0,0,0,0).Value(): [DEAD_END,0],
	Tile.new(0,0,1,0,0,0).Value(): [DEAD_END,0],
	Tile.new(0,0,0,1,0,0).Value(): [DEAD_END,0],
	Tile.new(1,0,0,0,0,0,true).Value(): [STAIRS,PI],
	Tile.new(0,1,0,0,0,0,true).Value(): [STAIRS,0],
	Tile.new(0,0,1,0,0,0,true).Value(): [STAIRS,-PI/2],
	Tile.new(0,0,0,1,0,0,true).Value(): [STAIRS,PI/2]
}
const FINISH = preload("uid://de1n51pmw2tcw")

func generateChurch():
	var finish = FINISH.instantiate()
	add_child(finish)
	finish.position = Vector3(nextLevelSeed)*ROOM_WIDTH*Vector3(-1,.8,1)
	if(nextLevelOrientation.back ==1): 
		finish.rotation.y = PI/2
		finish.position+=Vector3(0,0,-1)*22
	if(nextLevelOrientation.forward ==1): 
		finish.rotation.y = -PI/2
		finish.position+=Vector3(0,0,1)*22
	if(nextLevelOrientation.left ==1): 
		finish.rotation.y = 0.0
		finish.position+=Vector3(1,0,0)*22
	if(nextLevelOrientation.right ==1): 
		finish.rotation.y = PI
		finish.position+=Vector3(-1,0,0)*22

func instantiateMap():
	for pos in map:
		var tile = map[pos]
		if pos == pastLevelSeed:
			continue;
		instantiateTile(tile, pos)
		await get_tree().process_frame
	map.clear()

func instantiateTile(tile : Tile, pos : Vector3i):
	var roomData = RoomScenes.get(tile.Value())
	if roomData == null:
		print(tile)
		return
	var room = roomData[0].instantiate()
	add_child(room)
	var floor = FLOOR.instantiate()
	add_child(floor)
	var newPos : Vector3 = Vector3(pos)*ROOM_WIDTH*Vector3(-1,.8,1)
	floor.position = newPos
	room.position = newPos
	room.rotation.y = roomData[1]+PI
	if randf_range(0,1)<spawn_rate:
		var soul_eater = SOUL_EATER.instantiate()
		add_child(soul_eater)
		soul_eater.position = newPos+Vector3(0,2,0)
	
var dead_end_count = 0
var staircase_instantiated : bool = false
var nextLevelSeed : Vector3i = Vector3i(0,0,-1)
var pastLevelSeed : Vector3i = Vector3i(0,0,-1)
var nextLevelOrientation : Tile = Tile.new(1,0,0,0,0,0)

func generateMapLevel():
	dead_end_count = 0
	staircase_instantiated = false
	var originTile : Tile = nextLevelOrientation
	originTile.Cement()
	map[nextLevelSeed] = originTile
	pastLevelSeed = nextLevelSeed
	generateSurrounding(nextLevelSeed,originTile,nextLevelSeed.y)
	if !staircase_instantiated:
		clearLevel()
		generateMapLevel()
	printMap(10,10,pastLevelSeed.y)

func clearLevel():
	var positions = map.keys()
	var level: int = positions[-1][1]
	for i in range(positions.size()):
		if positions[-1].y == level:
			var position = positions[-1]
			positions.remove_at(-1)
			map.erase(position)
		else:
			break
	print("level erased!")
		

func generateSurrounding(pos : Vector3i,tile : Tile, depth : int):
	var newTiles = []
	if tile.forward == 1:
		var newPos : Vector3i = pos + Vector3i(0,0,1)
		newTiles.append(newPos)
	if tile.back == 1:
		var newPos : Vector3i = pos + Vector3i(0,0,-1)
		newTiles.append(newPos)
	if tile.right == 1:
		var newPos : Vector3i = pos + Vector3i(1,0,0)
		newTiles.append(newPos)
	if tile.left == 1:
		var newPos : Vector3i = pos + Vector3i(-1,0,0)
		newTiles.append(newPos)
	if depth< MAX_DEPTH:
		for tilePosition in newTiles:
			if map.has(tilePosition): continue
			var newTile : Tile = generateTile(tilePosition)
			map[tilePosition] = newTile
			generateSurrounding(tilePosition, newTile, depth+1)
	else:
		for tilePosition in newTiles:
			if map.has(tilePosition): continue
			var newTile : Tile = generateDeadEnd(tilePosition)
			map[tilePosition] = newTile

func generateDeadEnd(tilePos : Vector3i) -> Tile:
	var tile : Tile = Tile.new()
	
	var fore_tile = map.get(tilePos+Vector3i(0,0,1))
	if(fore_tile != null):
		tile.forward = fore_tile.back
	
	var back_tile = map.get(tilePos+Vector3i(0,0,-1))
	if(back_tile != null):
		tile.back = back_tile.forward
	
	var right_tile = map.get(tilePos+Vector3i(1,0,0))
	if(right_tile != null):
		tile.right = right_tile.left
	
	var left_tile = map.get(tilePos+Vector3i(-1,0,0))
	if(left_tile != null):
		tile.left = left_tile.right
	if countOpenings(tile)==1:
		dead_end_count+=1
		if dead_end_count == 2 && !staircase_instantiated:
			tile.staircase = true
			nextLevelSeed = tilePos+Vector3i(0,1,0)
			staircase_instantiated = true
			if tile.forward == 1 : nextLevelOrientation = Tile.new(0,1,0,0,0,0)
			if tile.back == 1: nextLevelOrientation = Tile.new(1,0,0,0,0,0)
			if tile.left == 1: nextLevelOrientation = Tile.new(0,0,0,1,0,0)
			if tile.right == 1: nextLevelOrientation = Tile.new(0,0,1,0,0,0)
	tile.Cement()
	return tile


func generateTile(tilePos : Vector3i)-> Tile:
	var tile : Tile = Tile.new()
	
	var fore_tile = map.get(tilePos+Vector3i(0,0,1))
	if(fore_tile != null):
		tile.forward = fore_tile.back
	
	var back_tile = map.get(tilePos+Vector3i(0,0,-1))
	if(back_tile != null):
		tile.back = back_tile.forward
	
	var right_tile = map.get(tilePos+Vector3i(1,0,0))
	if(right_tile != null):
		tile.right = right_tile.left
	
	var left_tile = map.get(tilePos+Vector3i(-1,0,0))
	if(left_tile != null):
		tile.left = left_tile.right
	
	tile = randomizeTile(tile, tilePos)
	tile.Cement()
	return tile

func randomizeTile(tile : Tile, pos :Vector3i) -> Tile:
	var openings = randi_range(1,2)
	var iterations : int = 0
	while countOpenings(tile)<= openings && iterations < 6:
		var opening = pickRandomOpening(4)
		if opening == directions.FORWARD:
			if tile.forward == -1:
				tile.forward = 1
			else:
				iterations+=1
			continue;
		if opening == directions.BACK:
			if tile.back == -1 && pos.z>0:
				tile.back = 1
			else:
				iterations+=1
			continue;
		if opening == directions.LEFT:
			if tile.left == -1:
				tile.left = 1
			else:
				iterations+=1
			continue;
		if opening == directions.RIGHT:
			if tile.right == -1:
				tile.right = 1
			else:
				iterations+=1
			continue;
	return tile

func pickRandomOpening(range : int) -> int:
	return randi_range(0,range-1)

func countOpenings(tile: Tile) -> int:
	var openings : int =0
	if tile.back == 1: openings+=1
	if tile.forward == 1: openings+=1
	if tile.left == 1: openings+=1
	if tile.right == 1: openings+=1
	if tile.up == 1: openings+=4
	if tile.down == 1: openings+=4
	return openings

func printMap(height:int,width:int,level:int):
	for y in height:
		print('\n')
		var lineString :String = "| "
		for x in width:
			var pos : Vector3i = Vector3i(x-width/2, level, height-y-3)
			lineString+= printTile(pos)
			#print(pos)
			lineString+=" | "
		print(lineString)

func printTile(pos : Vector3i) -> String:
	var tile = map.get(pos)
	
	
	if tile == null:
		return "    "
	if tile.staircase == true:
		return "star"
	var tileString: String = ""
	if tile.left == 1: tileString+="←" 
	else: tileString+="_" 
	
	if tile.forward == 1: tileString+="↑"
	else: tileString+="_" 
	
	if tile.back == 1:  tileString+="↓"
	else: tileString+="_" 
	
	if tile.right == 1: tileString+="→"
	else:tileString+="_" 
	return tileString

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
