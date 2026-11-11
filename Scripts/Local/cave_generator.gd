class_name CaveGenerator
extends Node2D
@export var room_scenes: Array[PackedScene] = [] 
@export var room_count = 10
@export var max_attempts := 10
@export var max_enemy := 80
@export var safe_distance := 1
@export var max_enemt_per_room := 10
@export var extra_rooms := 10
@export var cave_seed := 0

const ROOM_OFFSET = Vector2(576,0)

const UP = 1
const RIGHT = 2
const DOWN = 4
const LEFT = 8

const OPPOSITE = {
	UP: DOWN,
	RIGHT:LEFT,
	DOWN: UP,
	LEFT: RIGHT
}

const GRID_SIZE = Vector2i(576,324)
const DIRS = {UP: Vector2i.UP, RIGHT: Vector2i.RIGHT, DOWN: Vector2i.DOWN, LEFT: Vector2i.LEFT}
const DIRS_NAMES = {UP:"UP",RIGHT:"RIGHT",DOWN:"DOWN",LEFT:"LEFT"}
var spawned_grid = {} # Dictionary: Vector2i -> CaveRoom instance
var cell_exits = {}
var room_exits = {}
var room_distance = {}
var rng = RandomNumberGenerator.new()
var used_seed := 0

func generate_cave():
	used_seed = cave_seed if cave_seed != 0 else randi_range(1, 999999)
	rng.seed = used_seed
	print("Cave seed: ", used_seed)
	cache_exits()
	
	for attempts in max_attempts:
		clear_cave()
		build_cave()
		repair_cave()
		if check_connections():
			print("cave made on", attempts + 1)
			place_exit()
			place_enemies()
			return
		print("Attempt ", attempts + 1, "had holes re try" )

	push_error("Couldn't make a safe cave in " + str(max_attempts) + " tries")
			
func check_connections():
	var problems = 0
	for cell in spawned_grid:
		for dir in DIRS:
			if not (cell_exits[cell] & dir):
				continue
			var npos = cell + DIRS[dir]
			if not spawned_grid.has(npos):
				print("open to void", cell , " ",DIRS_NAMES[dir])
				problems += 1
	if problems == 0:
		print("Good cave generated")
	return problems == 0


func cache_exits():
	room_exits.clear()
	for scene in room_scenes:
		var r = scene.instantiate()
		if "exits" in r:
			room_exits[scene] = r.exits
		else:
			push_warning(scene.resource_path.get_file() + " has no caveroom.gd on it")
			room_exits[scene] = 0
		print(scene.resource_path.get_file(), " exits: ", exits_to_text(room_exits[scene]))
		r.free()
		
func _spawn(scene:PackedScene,cell:Vector2i):
	var room = scene.instantiate()
	room.position = Vector2(cell * GRID_SIZE) + ROOM_OFFSET
	add_child(room)
	spawned_grid[cell] = room
	cell_exits[cell] = room_exits[scene]
	print("ROOM SPAWNED AT: ", cell)
	
	
func pick_scene(pos:Vector2i, can_grow:bool):
	var required = 0
	var forbidden = 0
		
	for dir in DIRS:
		var npos = pos + DIRS[dir]
		if spawned_grid.has(npos):
			if cell_exits[npos] & OPPOSITE[dir]:
				required |= dir #neighbor has a door facing us
			else:
				forbidden |= dir #neighbor has a wall facing us
		elif not can_grow:
			forbidden |= dir #at room limit shut off the systems
	
	var options = []
	for scene in room_scenes:
		var e = room_exits[scene]
		if (e & required) == required and (e & forbidden) == 0 : #if we meet the reqs with nothing wrong
			options.append(scene)
			
	if can_grow:
		var branching = options.filter(func(s): return (room_exits[s] & ~required) !=0)
		if not branching.is_empty():
			options = branching	
	
	if options.is_empty():
		push_warning("No room fits at " + str(pos) + " - need a room WITH: " + exits_to_text(required)
		+ " and WITHOUT: " + exits_to_text(forbidden))
		return null
	return rng_pick(options)

func get_start_position() -> Vector2:
	return global_position + Vector2(GRID_SIZE) / 2.0

func clear_cave():
	for room in spawned_grid.values():
		room.free()
	spawned_grid.clear()
	cell_exits.clear()
	room_distance.clear()

func build_cave():
	var start_pos = Vector2i(0,0)
	_spawn(room_scenes[0],start_pos)
	room_distance[start_pos] = 0
	print("start room spawned in at: " ,start_pos)

	var queue = [start_pos]

	while not queue.is_empty():
		var pos = queue.pop_front()

		for dir in DIRS:
			if not (cell_exits[pos] & dir ):
				continue
			var npos = pos + DIRS[dir]
			if spawned_grid.has(npos):
				continue

			var can_grow = spawned_grid.size() < room_count
			
			if spawned_grid.size()  > room_count + extra_rooms:
				return
			var scene = pick_scene(npos,can_grow)
			if scene == null:
				continue #whats the worst that can happen
			_spawn(scene,npos)
			room_distance[npos] = room_distance[pos] + 1
			queue.append(npos)


func exits_to_text(e:int):
	var parts = []
	for dir in DIRS:
		if e & dir:
			parts.append(DIRS_NAMES[dir])
	return "none" if parts.is_empty() else ", ".join(parts)
	
func place_exit():
	var doors = []
	for cell in spawned_grid:
		for node in spawned_grid[cell].find_children("*","", true , false):
			if node.scene_file_path.ends_with("cave_entrance.tscn"):
				doors.append([node, room_distance[cell]])
	
	if doors.is_empty():
		push_warning("NO WAY TO ESCAPE, NO CAVE ENTRANCE")
		return # if there's no exits then there no reason to run the next part
	
	rng_shuffle(doors)
	doors.sort_custom(func(a,b): return a[1] > b[1])
	var keep = doors[0][0]
	
	for d in doors:
		if d[0] != keep:
			d[0].free()
	
	print("Exit kept ", doors[0][1], " rooms from start, removed ", doors.size() - 1)
		
func place_enemies():
	var kept = []
	var total = 0
	
	for cell in spawned_grid:
		var enemies_node = spawned_grid[cell].get_node_or_null("Enemies")
		if enemies_node == null:
			print("enemey node is null")
			continue			
		
		var room_enemy = enemies_node.get_children()
		total += room_enemy.size()
		rng_shuffle(room_enemy)
		
		for i in room_enemy.size():
			if room_distance[cell] < safe_distance or i >= max_enemt_per_room:
				room_enemy[i].free()
			else:
				kept.append(room_enemy[i])
	
	rng_shuffle(kept)
	for i in range(max_enemy, kept.size()):
		kept[i].free()	
	
	print("Enemies kept: ", min(kept.size(), max_enemy), " of ", total)	
		
func repair_cave():
	for pass_num in 5:
		var holes = find_hole_cells()
		if holes.is_empty():
			return		
		
		var fixed_any = false	
		for cell in holes:
			if not spawned_grid.has(cell):
				continue
			if try_swap_room(cell) or try_fill_neighbor(cell):
				fixed_any = true
		if not fixed_any:
			return # we have to retry now
		

func find_hole_cells():
	var holes = []		
	for cell in spawned_grid:
		for dir in DIRS:
			if (cell_exits[cell] & dir) and not spawned_grid.has(cell + DIRS[dir]):
				holes.append(cell)	
				break
	return holes	
			
func try_swap_room(cell:Vector2i):
	if cell == Vector2i.ZERO:
		return false #never touch the starting roome
	
	var required = 0
	var forbidden = 0
	
	for dir in DIRS:
		var npos = cell + DIRS[dir]
		if spawned_grid.has(npos) and (cell_exits[npos] & OPPOSITE[dir]):
			required |= dir
		else:
			forbidden |= dir
	
	var options = room_scenes.filter(func(s):
		return (room_exits[s] & required) == required and (room_exits[s] & forbidden) == 0)
	if options.is_empty():
		return false
	
	spawned_grid[cell].free()
	_spawn(rng_pick(options),cell)
	print("repaired ",cell, " by replacing room")
	return true

func try_fill_neighbor(cell:Vector2i):
	var filled_any = false
	
	for dir in DIRS:
		if not (cell_exits[cell] & dir):
			continue
		var npos = cell + DIRS[dir]
		if spawned_grid.has(npos):
			continue
					
		var required = 0
		var forbidden = 0
		for d in DIRS:
			var n2 = npos + DIRS[d]
			if spawned_grid.has(n2) and (cell_exits[n2] & OPPOSITE[d]):
				required |= d
			else:
				forbidden |= d
	
		var options = room_scenes.filter(func(s):
			return (room_exits[s] & required) == required and (room_exits[s] & forbidden) == 0)		
		if options.is_empty():
			continue
		
		_spawn(rng_pick(options), npos)
		room_distance[npos] = room_distance[cell] + 1
		print("fixed room at ",npos, " by filling it")
		filled_any = true
	
	return filled_any
		
func rng_pick(arr:Array):
	return arr[rng.randi_range(0, arr.size() -1)]

func rng_shuffle(arr:Array):
	for i in range(arr.size() -1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp		
		
		
	
