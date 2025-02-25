extends Node
class_name MultiplayerManager

@export var playerPrefab: PackedScene
@export var seats: Array[Seat]
@onready var serverCamera: Camera3D = $/root/Main/Camera3D

func _ready():
	var args = OS.get_cmdline_args()
	if "--server" in args:
		StartServer()
		serverCamera.current = true
	else:
		StartClient("127.0.0.1", 12345)
		if serverCamera:
			serverCamera.current = false

func StartServer():
	var server := ENetMultiplayerPeer.new()
	server.create_server(12345, 4)
	multiplayer.multiplayer_peer = server
	print("Server started.")
	multiplayer.peer_connected.connect(OnPeerConnected)

func StartClient(ip, port):
	var client := ENetMultiplayerPeer.new()
	client.create_client(ip, port)
	multiplayer.multiplayer_peer = client
	print("Connected to server.")

func OnPeerConnected(peerId):
	SpawnPlayer(peerId)
	for existingPeerId in multiplayer.get_peers():
		if existingPeerId != peerId:  # Avoid telling the new peer about itself
			rpc_id(peerId, "RemoteSpawnPlayer", existingPeerId)  # Send existing players to the new peer
	rpc("RemoteSpawnPlayer", peerId)  # Inform all clients to spawn the new player

@rpc("any_peer")
func RemoteSpawnPlayer(peerId):
	SpawnPlayer(peerId)

func SpawnPlayer(peerId):
	var availableSeat: Seat = null
	for seat in seats:
		if !seat.occupier:
			availableSeat = seat
			break
	if !availableSeat:
		print("No available seats for player ", peerId)
		return
	var player: Player = playerPrefab.instantiate()
	player.set_multiplayer_authority(peerId)
	add_child(player)
	player.global_transform.origin = availableSeat.spawnPoint.global_transform.origin
	player.global_transform.basis = availableSeat.spawnPoint.global_transform.basis
	availableSeat.occupier = player

	## Debug authority information
	#print("Spawned player ", peerId, " at ", availableSeat.name)
	#print("Player spawned on peer ", multiplayer.get_unique_id())
	#print("Is this the server? ", multiplayer.is_server())
	#print("Player authority assigned to: ", player.get_multiplayer_authority())
