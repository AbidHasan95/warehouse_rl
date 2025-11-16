extends AIController2D
var bot

func _ready():
	bot = owner
	reset()
	
func _physics_process(_delta):
	n_steps += 1
	if n_steps > reset_after:
		needs_reset = true
		done = true

	if needs_reset:
		needs_reset = false
		reset()


func get_reward():
	return reward


func get_obs():
	#var relative = to_local(_player.get_fruit_position())
	#var distance = relative.length() / 1500.0
	#relative = relative.normalized()
	var distances_and_coordinates = bot.get_area_distances()
	var result := []
	result.append(((bot.position.x / bot.WIDTH) - 0.5) * 2)
	result.append(((bot.position.y / bot.HEIGHT) - 0.5) * 2)
	#result.append(relative.x)
	#result.append(relative.y)
	#result.append(distance)
	result.append_array(distances_and_coordinates)
	var raycast_obs = bot.raycast_sensor.get_observation()
	result.append_array(raycast_obs)

	return {
		"obs": result,
	}


func set_action(action):
	#print("action::",action)
	bot._action_move.x = action["move"][0]
	bot._action_move.y = action["move"][1]
	#_player._action_load= bool(action["action_load"])
	#_player._action_unload= bool(action["action_unload"])
	#_player._action_load= bool(action["action_load_unload"][0])
	#_player._action_unload= bool(action["action_load_unload"][1])
	bot._action_load= action["move"][2]>0
	bot._action_unload= action["move"][3]>0

#func get_action_space():
	#return {"move": {"size": 2, "action_type": "continuous"},"action_load": {"size": 1, "action_type": "discrete"}, "action_unload": {"size": 1, "action_type": "discrete"}}
	
func get_action_space():
	return {"move": {"size": 4, "action_type": "continuous"}}
	
#func get_action_space():
	#return {"move": {"size": 2, "action_type": "continuous"},"action_load_unload": {"size": 1, "action_type": "discrete"}}
