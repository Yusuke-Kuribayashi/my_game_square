extends AIController3D

# 実際にキャラクタに与える動き
var move: float = 0.0

# キャラクタの情報
@onready var monster: CharacterBody2D = $".."

# ゴール情報
@onready var goal: Area2D = $"../../Goal"

# 移動速度
@export var move_speed: float = 200.0

# 観測値の取得
func get_obs() -> Dictionary:
	# キャラクタとゴール位置を観測値とする
	var obs := [
		monster.position.x,
		monster.position.y,
		goal.position.x,
		goal.position.y,
	]
	
	return {"obs": obs}

# 報酬値の取得
func get_reward() -> float:	
	return reward
	
# 行動パターンの定義
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
	
# 行動の決定
func set_action(action) -> void:	
	move = clamp(action["move"][0]*move_speed, -move_speed, move_speed)
