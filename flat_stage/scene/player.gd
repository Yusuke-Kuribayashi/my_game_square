extends CharacterBody2D
class_name Player
	

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# アニメーションスプライトの参照
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# 移動関連の設定
@export_group("move")
@export var move_speed: float = 200.0

# プレイヤー移動と状態管理
var direction: Vector2 = Vector2.ZERO
var state: PLAYER_STATE = PLAYER_STATE.IDLE

enum PLAYER_STATE {
	IDLE,
	MOVE,
	JUMP,
	FALL
}

func _physics_process(delta: float) -> void:
	# 重力
	apply_gravity(delta)
	get_input()
	apply_movement(delta)
	move_and_slide()
	update_state()


func apply_gravity(delta: float) -> void:
	# 重力を適用
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, 400.0)  # 最大落下速度を制限
	else:
		velocity.y = 0.0

func get_input():
	# 左右移動
	direction.x = Input.get_axis("left"	, "right")

func apply_movement(delta: float):
	if direction.x:
		animated_sprite_2d.flip_h = direction.x < 0
		velocity.x = direction.x * move_speed
	else:
		velocity.x = 0.0

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
		# PLAYER_STATE.JUMP:
		# 	animated_sprite_2d.play("jump")
		# PLAYER_STATE.FALL:
		# 	animated_sprite_2d.play("fall")
