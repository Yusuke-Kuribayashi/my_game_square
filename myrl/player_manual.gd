extends CharacterBody2D
class_name player

# 重力の設定
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# AI Agentからの入力
@onready var ai_controller:Node3D = $AIController3D

# 目標位置の情報
@onready var goal: Area2D = $"../Goal"
# キャラクタの初期位置
var init_position: Vector2
# キャラクタとゴールの位置
var prev_dist: float

# アニメーションスプライトの参照
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# 移動関連の設定
@export_group("move")
@export var move_speed: float = 200.0

# ジャンプ関連の設定
@export_group("jump")
@export var jump_force: float = 400.0
@export var max_y_velocity: float = 400.0
var can_jump: bool = false

# プレイヤー移動と状態管理
var direction: Vector2 = Vector2.ZERO
var state: PLAYER_STATE = PLAYER_STATE.IDLE

# waypoint報酬のパラメータ
var waypoints_passed: Dictionary = {}

# プレイ時間の設定
var episode_time: float = 0.0
@export var max_episode_time: float = 60.0  # 最大経過時間

# 行動の選択肢
enum PLAYER_STATE {
	IDLE,
	MOVE,
	JUMP,
	FALL,
}

# ロードしたときのデータを格納
func _ready():
	init_position = position
	prev_dist = position.distance_to(goal.position)

	waypoints_passed["waypoint1"] = false
	waypoints_passed["waypoint2"] = false

	print("start")	
	

func _physics_process(delta: float) -> void:
	episode_time += delta  # 時間を積算

	# 時間切れでリセット
	# if episode_time >= max_episode_time:
	# 	# 時間切れペナルティ
	# 	ai_controller.reward -= 1.0  
	# 	_reset_agent()
	# 	ai_controller.reset()

	# 重力
	apply_gravity(delta)
	# 入力の取得
	get_input()
	# 移動の適用
	apply_movement(delta)
	# set_reward(episode_time)
	# キャラクタの移動
	move_and_slide()
	# 状態の更新
	update_state()

func apply_gravity(delta: float) -> void:
	# 重力を適用
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_y_velocity)  # 最大落下速度を制限

# 報酬値の設定
func set_reward(eps_time:float):
	# 距離ベース
	var dist_now = position.distance_to(goal.position)
	ai_controller.reward += (prev_dist - dist_now) * 0.2
# 	#print(dist_now, ", ", (prev_dist - dist_now) * 0.1)
	
# 	# ポテンシャルシェービング
# 	#var potential = alpha*(position.x - init_position.x) + beta*max(0.0, init_position.y - position.y)
# 	#ai_controller.reward += potential - prev_potential
# 	#prev_potential = potential

# 	# 有意義なジャンプに対する報酬
# 	if jumped_flag:
# 		var height_gain = last_y_on_jump - position.y
# 		if height_gain > 10 and is_on_floor():
# 			ai_controller.reward += 0.01
# 			#print('in height')
# 		else:
# 			ai_controller.reward -= 5.0
# 		last_y_on_jump = position.y

# 	# 時間ペナルティ
# 	ai_controller.reward -= 0.05*eps_time
# 	prev_dist = dist_now

func get_input():
	# 左右移動
	direction.x = Input.get_axis("left"	, "right")

	# ジャンプ
	if Input.is_action_just_pressed("jump") and is_on_floor():
		can_jump = true

func apply_movement(_delta: float):
	
	# # ジャンプ
	# if ai_controller.jump and is_on_floor():
	# 	velocity.y = -jump_force
	# 	jumped_flag = true
	# 	#ai_controller.reward -= 50.0
	# else:
	# 	jumped_flag = false

	# # 左右移動
	# animated_sprite_2d.flip_h = ai_controller.move < 0
	# velocity.x = ai_controller.move
	if can_jump:
		velocity.y = -jump_force
		can_jump = false
	elif direction.x:
		animated_sprite_2d.flip_h = direction.x < 0
		velocity.x = direction.x * move_speed
	else:
		velocity.x = 0.0

# キャラクタの表示モーションを変更
func update_state():
	if is_on_floor():
		if velocity.x == 0:
			set_state(PLAYER_STATE.IDLE)
		else:
			set_state(PLAYER_STATE.MOVE)
	else:
		if velocity.y != 0:
			set_state(PLAYER_STATE.FALL)
		else:
			set_state(PLAYER_STATE.JUMP)

func set_state(new_state: PLAYER_STATE):
	# 状態が変更されていない場合は何もしない
	if new_state == state:
		return

	state = new_state
	match state:
		PLAYER_STATE.IDLE:
			animated_sprite_2d.play("idle")
		PLAYER_STATE.MOVE:
			animated_sprite_2d.play("move")
		PLAYER_STATE.JUMP:
			animated_sprite_2d.play("jump")
		PLAYER_STATE.FALL:
			animated_sprite_2d.play("fall")

# ステージから落ちるとスタート位置に戻る
func _on_wall_body_entered(_body):
	_reset_agent()
	#ai_controller.reward -= 100.0 # ステージ外に出ると報酬マイナス
	#ai_controller.reset()

## ゴールするとスタート位置に戻る
func _on_goal_body_entered(_body):
	_reset_agent()
	#ai_controller.reward += 10.0 # ゴールに到達すると報酬プラス
	#ai_controller.reset()

# スタート位置に戻る
func _reset_agent():
	# position = Vector2(-266, 96)
	position = init_position
	velocity = Vector2.ZERO
	#episode_time = 0.0

	## Waypoint 通過記録リセット
	#for key in waypoints_passed.keys():
		#waypoints_passed[key] = false


#func _on_waypoint_1_body_entered(body):
	##print("pass the waypoint1")
	#if body==self and !waypoints_passed["waypoint1"]:
		#ai_controller.reward = 1.0
		#waypoints_passed['waypoint1'] = true


#func _on_waypoint_2_body_entered(body):
	##print("pass the waypoint2")
	#if body==self and !waypoints_passed["waypoint2"]:
		#ai_controller.reward = 1.0
		#waypoints_passed['waypoint2'] = true
	
