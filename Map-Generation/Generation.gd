extends Node3D


var map : Dictionary
const MAX_DEPTH : int = 15


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateMap()

enum directions {
	FORWARD,
	BACK,
	LEFT,
	RIGHT,
	UP,
	DOWN
}

func generateMap():
	var originTile : Tile = Tile.new()
	originTile.forward = 1
	map[Vector3i(0,0,-1)] = originTile
	originTile.Cement()
	generateSurrounding(Vector3i(0,0,-1),originTile,0)
	printMap(20,10,0)

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
