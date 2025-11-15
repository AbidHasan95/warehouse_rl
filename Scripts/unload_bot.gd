extends CharacterBody2D

@onready var wall := $"../WallArea2D"
@onready var innerObstacle1:Area2D = $"../innerObstacle1"
@onready var raycast_sensor = $RaycastSensor2D
@onready var ai_controller:= $AIController2D
@onready var world:= $".."
@onready var bot1_tray_obj_sprite:Sprite2D = $TrayObjectSprite

@onready var shelf1:Area2D = $"../shelf1"
@onready var shelf2:Area2D = $"../shelf2"
@onready var shelf3:Area2D = $"../shelf3"
@onready var loading_area:Area2D = $"../loadingArea"

# Stats Labels
@onready var loading_stat_label = $"../loadingArea/Label"
@onready var shelf1_stat_label = $"../shelf1/Label"
@onready var shelf2_stat_label = $"../shelf2/Label"
@onready var shelf3_stat_label = $"../shelf3/Label"

var successful_loads_unloads = {
	"loading_bay": 0,
	"shelf1": 0,
	"shelf2": 0,
	"shelf3": 0
}

var steps = 0
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
var _action_move := Vector2.ZERO
var _action_load := false
var _action_unload := false
var speed =  500
var friction = 0.18
var tray_item_index = 0 #0 for empty cart, otherwise 1,2 or 3
var best_distance = 2500

func gameover():
	#print("wallentered")
	_velocity = Vector2.ZERO
	position = getNewPosition()
	#innerObstacle1.global_position = getNewPosition_obstacle() #958,687
	world.get_node("innerObstacle1").position = getNewPosition_obstacle()
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
	ai_controller.reset()
	
func update_ui_successful_loads_unloads(action_type):
	if action_type=="load":
		successful_loads_unloads["loading_bay"]+=1
		loading_stat_label.text = str(successful_loads_unloads["loading_bay"])
	elif action_type=="unload":
		if tray_item_index==1:
			successful_loads_unloads["shelf1"]+=1
			shelf1_stat_label.text = str(successful_loads_unloads["shelf1"])
		elif tray_item_index==2:
			successful_loads_unloads["shelf2"]+=1
			shelf2_stat_label.text = str(successful_loads_unloads["shelf2"])
		elif tray_item_index==3:
			successful_loads_unloads["shelf3"]+=1
			shelf3_stat_label.text = str(successful_loads_unloads["shelf3"])
		
		
	
	
func load_item():
	if tray_item_index!=0 or bot_location["loading_bay"]==false:
		ai_controller.reward -= 2
		return
		
	ai_controller.reward += 10.0
	var item_obj = world.unload_load_bay()
	bot1_tray_obj_sprite.texture = item_obj["sprite"]
	tray_item_index = item_obj["index"]
	update_ui_successful_loads_unloads("load")
	best_distance = 2500
	
func unload_item():
	#print(tray_item_index,bot_location)
	if (tray_item_index==1 and bot_location["shelf1"]) or (tray_item_index==2 and bot_location["shelf2"]) or (tray_item_index==3 and bot_location["shelf3"]):		
		ai_controller.done = true
		ai_controller.reward+= 10.0
		update_ui_successful_loads_unloads("unload")
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
	
	
	
func _process(delta: float) -> void:
	steps += 1
	#print("bot location:",position, " loading bay position:", loading_area.position, "shelf1 location: ", shelf1.position)
	var direction = get_direction()
	if direction.length() > 1.0:
		direction = direction.normalized()
	var target_velocity = direction * speed
	_velocity += (target_velocity - _velocity) * friction
	set_velocity(_velocity)
	move_and_slide()
	_velocity = velocity
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
	ai_controller.reward -= 50.0
	gameover()
	
func onWallEnter(body)-> void:
	#print("Heloooo")
	wallHit()
	
func get_direction():
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
	#if steps % 100==0:
		#var raycast_obs = self.raycast_sensor.get_observation()
		#print("raycast:",raycast_obs)
	#ai_controller.reward += movement_progress_reward()
	#if steps % 100==0:
		#if steps>=10000:
			#steps=0
		#print("Reward: ",ai_controller.reward, " Shaping Reward:", shaping_reward1, " best_distance: ",best_distance, " load dist: ",pos2)
	
func sum(accum, number):
	return accum + number
	
func update_raycast_penalty() -> float:
	var raycast_obs = self.raycast_sensor.get_observation()
	var reward = raycast_obs.reduce(sum) / 10.0 * -1
	if steps % 100==0:
		print("raycast penalty",reward)
	return reward 
	
func update_exploration_reward() -> float:
	var cell = Vector2i(floor(position.x / 64.0), floor(position.y / 64.0))
	if not visited_cells.has(cell):
		print("exploration reward: ", cell)
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
		
	
	
