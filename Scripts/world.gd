extends Node2D
@onready var wall2 = $WallArea2D
var loading_bay_items = []
var LOADING_BAY_SIZE = 3
@onready var innerObstacle1 = $innerObstacle1
var inner_obstacle1_speed = 100
var velocity = Vector2.RIGHT

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
	if innerObstacle1.position.x >= 1700:
		velocity = Vector2.LEFT
	if innerObstacle1.position.x <= 170:
		velocity = Vector2.RIGHT	
	#velocity = Vector2.RIGHT * inner_obstacle1_speed
	innerObstacle1.position += delta * velocity * inner_obstacle1_speed
#@onready var 
func _ready() -> void:
	reset_loading_bay()
	
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
		
	
func onWallCollision(body:CharacterBody2D):
	print("Hii")
