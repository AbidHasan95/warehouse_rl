extends Node

@export_enum("1:1","2:2", "3:3") var num_agents:int = 1
@export_enum("Static:0", "Slow:100", "Medium:150", "Fast:200", "Very Fast:300") var obstacle_1_speed: int = 100
@export_enum("1:1","0:0") var obstacles_present=1
@export_enum("1:1","4:4", "16:16") var camera_view_preset:int = 1
@export_enum("1:1","4:4","8:8","16:16","32:32") var num_worlds:int = 32

var MAX_WORLDS = 32

var camera_zoom_map = {
	1: Vector2(1,     1),
	4: Vector2(0.5,   0.5),
	16: Vector2(0.25, 0.25)
}

@onready var camera2d = $Camera2D

func _ready() -> void:
	camera2d.zoom = camera_zoom_map[camera_view_preset]
	disable_unnecessary_worlds_and_agents()
			
func disable_unnecessary_worlds_and_agents():
	for i in range(num_worlds+1,MAX_WORLDS+1):
		var world_node:Node = get_node("World%d" % i)
		world_node.process_mode = Node.PROCESS_MODE_DISABLED
		var ai_controller_nodes:Array[Node] = world_node.find_children("AIController2D")
		for ai_controller_node in ai_controller_nodes:
			ai_controller_node.remove_from_group("AGENT")
