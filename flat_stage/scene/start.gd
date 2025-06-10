extends StaticBody2D

# プレイヤーのリスボーン一を指定するマーカー
@onready var respawn_marker: Marker2D = $Marker2D

# プレイヤーの参照
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready():
	# プレイヤーノードを取得
	player = get_tree().get_first_node_in_group("player")
	# リスタート時のイベントを接続
	#SignalManager.on_player_hit.connect(_on_player_hit)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_player_hit():
	player.gobal_position = respawn_marker.global_position
	player.animated_sprite_2d.flip_h = false
	
