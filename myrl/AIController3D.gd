extends AIController3D

# キャラクタの情報
@onready var monster: CharacterBody2D = $".."

# ゴール情報
@onready var goal: Area2D = $"../../Goal"

func get_obs() -> Dictionary:
	# キャラクタとゴール位置を観測値とする
	var obs := [
		monster.position.x,
		monster.position.y,
		goal.position.x,
		goal.position.y,
	]	
	
	return {"obs": obs}

func get_reward() -> float:	
	return 0.0
	
func get_action_space() -> Dictionary:
	return {
		"example_actions_continous" : {
			"size": 2,
			"action_type": "continuous"
		},
		"example_actions_discrete" : {
			"size": 2,
			"action_type": "discrete"
		},
		}
	
func set_action(action) -> void:	
	print(action)
	# move = clamp(action["move"][0]*move_speed, -move_speed, move_speed)
	#move = action["move"][0]*move_speed
	# jump = 1 if action["jump"][0] > 0.5 else 0
