extends AIController3D

@onready var cube: CharacterBody3D = $".."
@onready var target: Area3D = $"../../Target"

# 実際にキャラクタに反映させる変数
var move = Vector2.ZERO

# どのような値を観測値として用いるか
func get_obs() -> Dictionary:
	# キャラクタと目標位置を観測値とする
	var obs := [
		cube.position.x,
		cube.position.z,
		target.position.x,
		target.position.z,
	]
	return {"obs": obs}

func get_reward() -> float:	
	return reward
	
# どのような行動パターンとするか
func get_action_space() -> Dictionary:
	# 行動パターンをここで設定する(今回は平面移動のみ考慮する)
	# 連続値 or 離散値をとることができる
	return {
		"move" : {
			"size": 2,
			"action_type": "continuous"
		},
	}
	
# AIによって生成された行動をキャラクタへ反映させるための変数に格納
func set_action(action) -> void:	
	move.x = action["move"][0]
	move.y = action["move"][1]
	
