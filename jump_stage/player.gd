extends CharacterBody2D
class_name Player

# 重力の設定
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# AI Agentからの入力
@onready var ai_controller:Node3D = $AIController3D
# 目標位置の情報
@onready var goal: Area2D = $"../Goal"
# キャラクタの初期位置
var init_position: Vector2 = position
# キャラクタとゴールの位置
#var prev_dist: float = position.distance_to(goal.position)
var prev_dist: float = INF

# アニメーションスプライトの参照
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# 移動関連の設定
@export_group("move")
@export var move_speed: float = 200.0

# ジャンプ関連の設定
@export_group("jump")
@export var jump_force: float = 300.0
@export var max_y_velocity: float = 400.0
var can_jump: bool = false

# プレイヤー移動と状態管理
var direction: Vector2 = Vector2.ZERO
var state: PLAYER_STATE = PLAYER_STATE.IDLE

enum PLAYER_STATE {
	IDLE,
	MOVE,
	JUMP,
	FALL,
}

func _physics_process(delta: float) -> void:
	# 重力
	apply_gravity(delta)
	#get_input()
	apply_movement(delta)
	set_reward()
	move_and_slide()
	update_state()

func apply_gravity(delta: float) -> void:
	# 重力を適用
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_y_velocity)  # 最大落下速度を制限

# 報酬値の設定
func set_reward():
	# 距離ベース
	var dist_now = position.distance_to(goal.position)
	if prev_dist < INF:
		ai_controller.reward += (prev_dist - dist_now) * 0.05

	# 時間ペナルティ
	ai_controller.reward -= 0.001

func get_input():
	# 左右移動
	# direction.x = Input.get_axis("left"	, "right")
	direction.x = ai_controller.move

	# ジャンプ
	if Input.is_action_just_pressed("jump") and is_on_floor():
		can_jump = true

func apply_movement(_delta: float):
	can_jump = ai_controller.jump
	if can_jump:
		velocity.y = -jump_force
		can_jump = false
	# elif direction.x:
	# 	animated_sprite_2d.flip_h = direction.x < 0
	# 	#velocity.x = direction.x * move_speed
	# 	velocity.x = ai_controller.move
	# else:
	# 	velocity.x = 0.0
	else:
		animated_sprite_2d.flip_h = ai_controller.move < 0
		velocity.x = ai_controller.move

# キャラクタの表示モーションを変更
func update_state():
	if is_on_floor():
		if velocity.x == 0:
			set_state(PLAYER_STATE.IDLE)
		else:
			set_state(PLAYER_STATE.MOVE)
	else:
		if velocity.y > 0:
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
	ai_controller.reward -= 1.0 # ステージ外に出ると報酬マイナス
	_reset_agent()
	ai_controller.reset()

# ゴールするとスタート位置に戻る
func _on_goal_body_entered(_body):
	ai_controller.reward += 1.0 # ゴールに到達すると報酬プラス
	_reset_agent()
	ai_controller.reset()

# スタート位置に戻る
func _reset_agent():
	# position = Vector2(-266, 96)
	position = init_position
	velocity = Vector2.ZERO
