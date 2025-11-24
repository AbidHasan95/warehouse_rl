extends CharacterBody2D

@onready var wall := $"../WallArea2D"
@onready var innerObstacle1:Area2D = $"../innerObstacle1"
@onready var raycast_sensor = $RaycastSensor2D
@onready var ai_controller:= $AIController2D
@onready var world:= $".."
@onready var bot1_tray_obj_sprite:Sprite2D = $TrayObjectSprite
@onready var bot_sprite: Sprite2D = $Sprite2D


@onready var shelf1:Area2D = $"../shelf1"
@onready var shelf2:Area2D = $"../shelf2"
@onready var shelf3:Area2D = $"../shelf3"
@onready var loading_area:Area2D = $"../loadingArea"

# Stats Labels
@onready var bot_stats_label1:Label = $"../StatsLabel1"
@onready var bot_stats_label2:Label = $"../StatsLabel2"
@onready var loading_stat_label = $"../loadingArea/Label"
@onready var shelf1_stat_label = $"../shelf1/Label"
@onready var shelf2_stat_label = $"../shelf2/Label"
@onready var shelf3_stat_label = $"../shelf3/Label"

# Sync Node
@onready var sync_node = $"../../Sync"

# Graph2D
@onready var graph_2d = $"../Graph2D"
var line_series = LineSeries.new(Color.SEA_GREEN,2.0)
var prev_reward = 0
var reward_diff = 0

## Graph using GraphEdit
#@onready var plot_line = $"../GraphEdit/GraphNode/Line2D"
var plot_series_array = []
var plot_series_array_avg = []

# Bot stats - start
var steps = 0
var is_success = false

var stats_loads_unloads = {
	"loading": 0,
	"unloading_shelf1": 0,
	"unloading_shelf2": 0,
	"unloading_shelf3": 0,
	"failures": 0,
	"unloading": 0
}
# Bot stats -end

var bot_location = {
	"loading_bay": false,
	"shelf1": false,
	"shelf2": false,
	"shelf3": false
}
var visited_cells = {}
var item_sprites = [
	{"name": "obj1", "index":1 ,"sprite":preload("res://Assets/Obj-1.png")},
	{"name": "obj2", "index":2, "sprite":preload("res://Assets/Obj-2.png")},
	{"name": "obj3", "index":3, "sprite":preload("res://Assets/Obj-3.png")},
]

const WIDTH = 1920
const HEIGHT = 1080

var _velocity := Vector2.ZERO

# actions - RL
var _action_move := Vector2.ZERO
var _action_load := false
var _action_unload := false
var _action_can_move := 1

var speed =  500
var friction = 0.18
var tray_item_index = 0 #0 for empty cart, otherwise 1,2 or 3
var best_distance = 2500

func gameover():
	#print("wallentered")
	_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	_action_move = Vector2.ZERO
	position = getNewPosition()
	#innerObstacle1.global_position = getNewPosition_obstacle() #958,687
	world.get_node("innerObstacle1").position = getNewPosition_obstacle()
	#print("velocity after hit:",velocity, _velocity)
	# Old logic
	#tray_item_index = 0
	#bot1_tray_obj_sprite.texture = null
	# New Logic
	tray_item_index = randi_range(0,3)
	if tray_item_index == 0:
		bot1_tray_obj_sprite.texture = null
	else:
		bot1_tray_obj_sprite.texture = item_sprites[tray_item_index-1]["sprite"]
	
	#ai_controller.done = true
	#best_distance = position.distance_to(loading_area.position)
	best_distance = 2500
	ai_controller.done = true
	update_stats_count("failures")
	#ai_controller.reset()
	#reset_stats_count()
	
func load_item():
	#print("load item by", self.name)
	if tray_item_index!=0 or bot_location["loading_bay"]==false:
		ai_controller.reward -= 2
		return
		
	ai_controller.reward += 120
	var item_obj = world.unload_load_bay()
	bot1_tray_obj_sprite.texture = item_obj["sprite"]
	tray_item_index = item_obj["index"]
	world.update_ui_successful_loads_unloads("load", tray_item_index)
	update_stats_count("loading")
	best_distance = 2500
	
func is_holding_item():
	if tray_item_index!=0:
		return 1
	else:
		return 0
		
func reset_stats_count():
	stats_loads_unloads = {
		"loading": 0,
		"unloading_shelf1": 0,
		"unloading_shelf2": 0,
		"unloading_shelf3": 0,
		"failures": 0
	}

func update_stats_count(key):
	stats_loads_unloads[key]+= 1
	#print("stats_updated ->",key,"updated stats", stats_loads_unloads)
	
# Ends the episode
func reset_bot_stats():
	steps = 0
	reset_stats_count()
	is_success = false
	
	
func unload_item():
	#print("unload item by", self.name)
	#print(tray_item_index,bot_location)
	if (tray_item_index==1 and bot_location["shelf1"]) or (tray_item_index==2 and bot_location["shelf2"]) or (tray_item_index==3 and bot_location["shelf3"]):		
		
		#ai_controller.done = true
		if stats_loads_unloads["unloading"] < 6:
			print("unloading - ", stats_loads_unloads["unloading"])
			ai_controller.done = true
		elif stats_loads_unloads["unloading"] >= 6 and stats_loads_unloads["unloading"] % 2 == 0:
			print("unloading >10 - ", stats_loads_unloads["unloading"])
			ai_controller.done = true
		else:
			print("Not DONE ->",stats_loads_unloads["unloading"])
		update_stats_count("unloading_shelf%d" % tray_item_index)
		update_stats_count("unloading")
		ai_controller.reward+= 120
		world.update_ui_successful_loads_unloads("unload", tray_item_index)
		bot1_tray_obj_sprite.texture = null
		tray_item_index = 0
		best_distance = position.distance_to(loading_area.position)
	else:
		ai_controller.reward -= 2
		return
	
func _ready() -> void:
	ai_controller.init(self)
	raycast_sensor.activate()
	wall.body_entered.connect(onWallEnter)
	innerObstacle1.body_entered.connect(onWallEnter)
	if name == "Unload_Bot2":
		bot_sprite.self_modulate = Color(0.2,0.53,0.85,1.0)
	elif name == "Unload_Bot1":
		bot_sprite.self_modulate = Color(0.41, 0.54, 0.32, 1)
	#Update bot location
	# Entry
	loading_area.body_entered.connect(update_bot_location.bind(true,"loading_bay"))
	shelf1.body_entered.connect(update_bot_location.bind(true,"shelf1"))
	shelf2.body_entered.connect(update_bot_location.bind(true,"shelf2"))
	shelf3.body_entered.connect(update_bot_location.bind(true,"shelf3"))
	#Exit
	loading_area.body_exited.connect(update_bot_location.bind(false,"loading_bay"))
	shelf1.body_exited.connect(update_bot_location.bind(false,"shelf1"))
	shelf2.body_exited.connect(update_bot_location.bind(false,"shelf2"))
	shelf3.body_exited.connect(update_bot_location.bind(false,"shelf3"))
	
	# Graph2D
	graph_2d.add_series(line_series)
	#var myarray = [1,4,8,2,0,7,12,2]
	#plot_series(myarray)
	
func calculate_mean(data_array: Array) -> float:
	if data_array.is_empty():
		return 0.0 # Or handle error for empty array
	var sum := 0.0
	for value in data_array:
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			sum += float(value)
		else:
			# Handle non-numerical elements, e.g., skip or raise error
			pass 
	return sum / data_array.size()
	
#func plot_series(series):
	#plot_line.clear_points()
	#for i in range(series.size()):
		#plot_line.add_point(Vector2(i*5, -series[i]))
		
var ema := 0.0
const ALPHA := 0.2   # smaller = smoother default-0.1

func get_ema(value: float) -> float:
	ema = ALPHA * value + (1.0 - ALPHA) * ema
	return ema
	
func _process(delta: float) -> void:
	steps += 1
	#print("bot location:",position, " loading bay position:", loading_area.position, "shelf1 location: ", shelf1.position)
	var direction = get_direction()
	if direction.length() > 1.5:
		direction = direction.normalized()
	var target_velocity = direction * speed * _action_can_move
	_velocity += (target_velocity - _velocity) * friction
	set_velocity(_velocity)
	move_and_slide()
	_velocity = velocity
	prev_reward = ai_controller.reward
	if ai_controller.heuristic=="model":
		if _action_load:
			load_item()
		if _action_unload:
			unload_item()
	else:
		if Input.is_action_just_pressed("action_load"):
			load_item()
		if Input.is_action_just_pressed("action_unload"):
			unload_item()
	
	update_reward()
	reward_diff = ai_controller.reward - prev_reward
	var smoothed = get_ema(reward_diff)
	
	#plot_series_array.append(Vector2(steps,smoothed))
	plot_series_array.append(reward_diff * 3)
	
	#plot_series_array.append(reward_diff)
	if plot_series_array.size() >= 80:
		plot_series_array.pop_front()

	if steps % 80==0:
		var avg = calculate_mean(plot_series_array)
		if sync_node.control_mode ==2:
			if line_series.data.size() >= 15:
				for idx in range(line_series.data.size()):
					line_series.data[idx][0] -= 1
			line_series.add_point(line_series.data.size(),avg)
			if line_series.data.size()>15:
				line_series.remove_point_at(0)
		if name == "Unload_Bot1":
			bot_stats_label1.text = "Reward: %.1f" % ai_controller.reward
		elif name== "Unload_Bot2":
			bot_stats_label2.text = "Reward: %.1f" % ai_controller.reward
	
func getNewPosition():
	#return Vector2i(960, 540)
	var x_coord = randi_range(305,1800)
	var y_coord = randi_range(95,700)
	return Vector2i(x_coord, y_coord)

func get_normalized_distance(node2d):
	var res = []
	var temp = to_local(node2d.global_position)
	#var distance = temp.normalized()
	var distance1 = temp.length() / 2500.0 
	temp = temp.normalized()
	res.append(temp.x)
	res.append(temp.y)
	res.append(distance1)
	return res
	
func getNewPosition_obstacle():
	var x_coord = randi_range(200,1744)
	var y_coord = randi_range(400,760)
	return Vector2i(x_coord, y_coord)
	
	
func get_area_distances():
	var dist_array = []
	dist_array.append_array(get_normalized_distance(shelf1))
	dist_array.append_array(get_normalized_distance(shelf2))
	dist_array.append_array(get_normalized_distance(shelf3))
	dist_array.append_array(get_normalized_distance(loading_area))
	
	# Location flags
	for area_name in bot_location:
		dist_array.append(int(bot_location[area_name]))
	
	# Tray item type (one-hot: empty, type1, type2, type3)
	for i in range(4):
		dist_array.append(int(tray_item_index == i))
	return dist_array
	
func wallHit():
	#ai_controller.done = true
	#print("wall hit by ",self.name)
	world.update_collision_stats()
	#update_stats_count("failures")
	ai_controller.reward -= 80.0
	gameover()
	
func onWallEnter(body)-> void:
	if body != self:
		return
	#print("Heloooo")
	wallHit()
	
func get_direction():
	#print("action_move:", _action_move, " length-> " ,_action_move.length(), " normalized: ", _action_move.normalized())
	#if abs(_action_move.x) < 0.2:
		#_action_move.x = 0.0
	#if abs(_action_move.y) < 0.2:
		#_action_move.y = 0.0
	if ai_controller.heuristic == "model":
		return _action_move
	var direction := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	return direction

func bot_wrong_action_penalty():
	if ((bot_location["shelf1"] and tray_item_index==1) or (bot_location["shelf2"] and tray_item_index==2) or (bot_location["shelf3"] and tray_item_index==3)) and _action_unload==false:
		return -5
	if bot_location["loading_bay"] and tray_item_index==0 and _action_load==false:
		return -5
	return 0
	
func update_bot_location(body,is_entered:bool, location_name: String):
	if body != self:
		return
	bot_location[location_name] = is_entered
	#print("Entered:",is_entered,"Location:",location_name)
	
func update_reward():
	ai_controller.reward -= 0.01  # step penalty
	var shaping_reward1 = update_navigation_shaping_reward()
	#var pos2 = position.distance_to(loading_area.position)
	ai_controller.reward += shaping_reward1
	ai_controller.reward += bot_wrong_action_penalty()
	ai_controller.reward += update_exploration_reward()
	ai_controller.reward += update_raycast_penalty()
	#ai_controller.reward += movement_progress_reward() # bot gets stuck in the other side of obstacle when destination is just beyond the obstacle
	if steps % 100==0:
		var raycast_obs = raycast_sensor.get_observation()
		#print(name, " raycast:",raycast_obs)
	
	#if steps % 100==0:
		#if steps>=10000:
			#steps=0
		#print("Reward: ",ai_controller.reward, " Shaping Reward:", shaping_reward1, " best_distance: ",best_distance, " load dist: ",pos2)
	
func sum(accum, number):
	return accum + number
	
func update_raycast_penalty() -> float:
	var ray_collisions = []
	for ray_obj in raycast_sensor.rays:
		if ray_obj.get_collider() != null:
			ray_collisions.append(ray_obj.get_collider().collision_layer)
		else:
			ray_collisions.append(0)
	var raycast_obs = raycast_sensor.get_observation()
	#var reward = raycast_obs.reduce(sum) / raycast_sensor.n_rays  * -1
	var penalty = raycast_obs.reduce(sum)  * -1
	#if steps % 100==0:
		#print("raycast collisions: ",ray_collisions, " obs -", raycast_obs)
	return penalty 
	
func update_exploration_reward() -> float:
	var cell = Vector2i(floor(position.x / 64.0), floor(position.y / 64.0))
	if not visited_cells.has(cell):
		#print("exploration reward: ", cell)
		visited_cells[cell] = true
		return 0.1
	return 0.0
	
func update_navigation_shaping_reward():
	var s_reward = 0.0
	var destination_distance = 0.0
	if tray_item_index==0:
		destination_distance = position.distance_to(loading_area.position)
	elif tray_item_index==1:
		destination_distance = position.distance_to(shelf1.position)
	elif tray_item_index==2:
		destination_distance = position.distance_to(shelf2.position)
	elif tray_item_index==3:
		destination_distance = position.distance_to(shelf3.position)
	
	if destination_distance < best_distance:
		s_reward += (best_distance - destination_distance) * 0.005 
		best_distance = destination_distance
	elif destination_distance > best_distance:
		s_reward += (best_distance - destination_distance) * 0.005
	
	#s_reward/= 100.0
	return s_reward

func movement_progress_reward():
	if _velocity.length() < 5.0:
		return 0.0  # basically idle, no reward

	var target_position = Vector2.ZERO
	if tray_item_index == 0:
		target_position = loading_area.position
	elif tray_item_index == 1:
		target_position = shelf1.position
	elif tray_item_index == 2:
		target_position = shelf2.position
	elif tray_item_index == 3:
		target_position = shelf3.position

	var to_target = (target_position - position).normalized()
	var move_dir = _velocity.normalized()

	# Dot product: 1 = perfectly aligned, 0 = perpendicular, -1 = opposite
	var alignment = move_dir.dot(to_target)
	if alignment > 0.1:  # moving at least somewhat toward target
		return alignment * 0.02  # small continuous reward
	return 0.0
