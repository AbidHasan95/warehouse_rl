extends Node2D

# Nodes
@onready var wall2 = $WallArea2D
@onready var innerObstacle1 = $innerObstacle1
@onready var batch_envs_node = $".."

# Loading and Shelf labels
@onready var loading_stat_label = $"loadingArea/Label"
@onready var shelf1_stat_label = $"shelf1/Label"
@onready var shelf2_stat_label = $"shelf2/Label"
@onready var shelf3_stat_label = $"shelf3/Label"

# Num Collisions Label
var num_collisions = 0
@onready var num_collisions_label = $NumResetsLabel

## Bots
@onready var unload_bot1: CharacterBody2D = $Unload_Bot1
@onready var unload_bot2: CharacterBody2D = $Unload_Bot2
@onready var unload_bot3: CharacterBody2D = $Unload_Bot3
var max_unload_bots = 3

var loading_bay_items = []
var LOADING_BAY_SIZE = 3

var inner_obstacle1_speed = 0
var inner_obstacle1_velocity = Vector2.RIGHT
var obstacle_1_type = ""
var num_agents = 0
var num_obstacles_present = 0

var successful_loads_unloads = {
	"loading_bay": 0,
	"shelf1": 0,
	"shelf2": 0,
	"shelf3": 0
}

var item_sprites = [
	{"name": "obj1", "index":1 ,"sprite":preload("res://Assets/Obj-1.png")},
	{"name": "obj2", "index":2, "sprite":preload("res://Assets/Obj-2.png")},
	{"name": "obj3", "index":3, "sprite":preload("res://Assets/Obj-3.png")},
]
@onready var loading_area_sprite_nodes:Array[Sprite2D] = [
	$loadingArea/VBoxContainer/loadingArea_Item3/Sprite2D,
	$loadingArea/VBoxContainer/loadingArea_Item2/Sprite2D,
	$loadingArea/VBoxContainer/loadingArea_Item1/Sprite2D
]
func _process(delta: float) -> void:
	if inner_obstacle1_speed!= 0:
		if innerObstacle1.position.x >= 1700:
			inner_obstacle1_velocity = Vector2.LEFT
		if innerObstacle1.position.x <= 170:
			inner_obstacle1_velocity = Vector2.RIGHT	
		innerObstacle1.position += delta * inner_obstacle1_velocity * inner_obstacle1_speed
#@onready var 
func _ready() -> void:
	# Number of inner obstacles
	num_obstacles_present = batch_envs_node.obstacles_present
	if num_obstacles_present == 0:
		innerObstacle1.process_mode = Node.PROCESS_MODE_DISABLED
		innerObstacle1.visible = false
	else:
		# Inner_obstacle speed
		inner_obstacle1_speed = batch_envs_node.obstacle_1_speed
	num_agents = batch_envs_node.num_agents
	#if num_agents == 1:
		#unload_bot2.process_mode = Node.PROCESS_MODE_DISABLED
		#unload_bot2.visible = false
	disable_unload_bots()
	reset_loading_bay()
	
func disable_unload_bots():
	print("world.num_agents -",batch_envs_node.num_agents)
	for i in range(batch_envs_node.num_agents+1,max_unload_bots+1):
		var node = get_node("Unload_Bot%d" % i)
		node.process_mode = Node.PROCESS_MODE_DISABLED
		node.visible = false
		
#func update_loading_area_item_sprite(slot_index:int, item_texture_index):
	#loading_area_sprite_nodes[slot_index].texture = item_sprites[item_texture_index]["sprite"]

func reset_loading_bay():
	for i in range(LOADING_BAY_SIZE):
		loading_bay_items.append(randi() % LOADING_BAY_SIZE)
	update_loading_area_item_sprites()
	
	
func update_loading_area_item_sprites():
	for i in range(LOADING_BAY_SIZE):
		var item_texture_index = loading_bay_items[i]
		loading_area_sprite_nodes[i].texture = item_sprites[item_texture_index]["sprite"]
	
func unload_load_bay():
	var front_item = loading_bay_items.pop_front()
	loading_bay_items.append(randi() % LOADING_BAY_SIZE)
	update_loading_area_item_sprites()
	return item_sprites[front_item]
	
func update_ui_successful_loads_unloads(action_type, tray_item_index):
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
		
func update_collision_stats():
	num_collisions+=1
	num_collisions_label.text = "Collisions: %d" % num_collisions
	
func onWallCollision(body:CharacterBody2D):
	print("Hii")
