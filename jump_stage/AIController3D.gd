extends AIController3D

# 実際にキャラクタに与える動き
var move: float = 0.0
# jump
var jump: int = 0

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

	var tilemap = get_node("../../Field")
	var tile_size = tilemap.tile_set.tile_size

	# 周囲8方向のタイルの有無(0 or 1)を観測に追加
	for dx in range(-4, 6):
		for dy in range(-5, 6):
			if dx == 0 and dy == 0:
				continue
			# 相対座標 → ワールド座標
			var world_pos = monster.position + Vector2(dx * tile_size.x, dy * tile_size.y)

			# ワールド座標 → タイル座標（整数）
			var tile_coords = tilemap.local_to_map(world_pos)

			# タイルID取得（レイヤー0）
			var tile_id = tilemap.get_cell_source_id(0, tile_coords)
			# タイルが存在するかどうかを観測値に追加
			# 存在する場合は1、存在しない場合は0
			# -1はタイルが存在しないことを示す
			# 0はタイルが存在することを示す
			obs.append(1 if tile_id != -1 else 0)

	
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
		# ジャンプモーション
		 "jump" : {
		 	"size": 1,
		 	"action_type": "continuous"
		 }
		}
	
# 行動の決定
func set_action(action) -> void:	
	#print(action)
	move = clamp(action["move"][0]*move_speed, -move_speed, move_speed)
	#move = action["move"][0]*move_speed
	jump = 1 if action["jump"][0] > 0.5 else 0
