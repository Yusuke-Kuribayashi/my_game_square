extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# 重力の設定
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var ai_controller:Node3D =  $AIController3D
@onready var target: Area3D = $"../Target"

var prev_dist: float = INF

func _physics_process(delta):
 	# 重力の反映
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = ai_controller.move.x
	velocity.z = ai_controller.move.y
	
	# 距離ベース shaping
	var dist_now  = position.distance_to(target.position)
	if prev_dist < INF:
		ai_controller.reward += (prev_dist - dist_now) * 0.05
		
	prev_dist = dist_now

	# 時間ペナルティ (速くゴールさせる)
	ai_controller.reward -= 0.001	
	move_and_slide()


func _on_target_body_entered(_body):
	ai_controller.reward += 1.0
	_reset_agent()                     # 位置や速度をリセット
	ai_controller.reset()	

func _on_wall_body_entered(_body):
	ai_controller.reward -= 1.0	
	_reset_agent()
	ai_controller.reset()

func _reset_agent():
	position     = Vector3(-2.652, 0.626, 0.0)
	velocity     = Vector3.ZERO
	
