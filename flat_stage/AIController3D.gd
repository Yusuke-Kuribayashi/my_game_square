extends AIController3D

# 実際にキャラクタに与える動き
var move: float = 0.0

func get_obs() -> Dictionary:
	return {"obs":[]}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		# ２D平面内の移動のため、自由度は１
		"move" : {
			"size": 1,
			"action_type": "continuous"
		},
		## ジャンプモーション
		# "example_actions_discrete" : {
		# 	"size": 2,
		# 	"action_type": "discrete"
		# },
		}
	
func set_action(action) -> void:	
	move = clamp(action["move"][0], -1.0, 1.0)
