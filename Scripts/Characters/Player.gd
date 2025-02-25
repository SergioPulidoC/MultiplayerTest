extends CharacterBody3D
class_name Player

@export var rotationSpeed: float = 0.1
@onready var playerCamera: Camera3D = $Camera3D
@onready var multiplayerManager: MultiplayerManager = $/root/Main/MultiplayerManager

func _ready():
	if multiplayer.get_unique_id() == get_multiplayer_authority():
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		playerCamera.current = true
		print("Camera activated for local player: ", multiplayer.get_unique_id())
	else:
		playerCamera.current = false
		print("Camera disabled for non-local player.")

func _unhandled_input(event):
	if is_multiplayer_authority() and event is InputEventMouseMotion:
		var delta_x = event.relative.x
		rotate_y(-deg_to_rad(delta_x * rotationSpeed))
		rpc("SyncRotation", rotation_degrees.y)
		
@rpc("any_peer", "unreliable")
func SyncRotation(newRotation: float):
	if !is_multiplayer_authority():
		rotation_degrees.y = newRotation
