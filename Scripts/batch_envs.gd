extends Node

@export_enum("1:1","2:2") var num_agents:int = 2
@export_enum("Static:0", "Slow:100", "Medium:150", "Fast:200", "Very Fast:300") var obstacle_1_speed: int = 100
@export_enum("1:1","0:0") var obstacles_present=0
