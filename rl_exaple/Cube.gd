extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var ai_controller:Node3D =  $AIController3D

func _physics_process(delta):
	# 重力の設定
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = ai_controller.move.x
	velocity.z = ai_controller.move.y
	
	move_and_slide()


# 目標地点に到着すると初期位置にリセット
func _on_target_body_entered(_body: Node3D):
	position = Vector3(-2.652, 0.626, 0.0)
	ai_controller.reward += 1.0

# フィールドから落ちると初期位置にリセット
func _on_wall_body_entered(_body: Node3D):
	position = Vector3(-2.652, 0.626, 0.0)
	ai_controller.reward -= 1.0
	ai_controller.reset()
	
