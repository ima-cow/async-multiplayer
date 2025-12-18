extends Node

const SERVER_PORT := 8080
signal game_start


func host_game() -> Error:
	var err: Error 
	
	print("starting server")
	var server_peer := ENetMultiplayerPeer.new()
	err = server_peer.create_server(SERVER_PORT) 
	if err:
		return err
	
	multiplayer.multiplayer_peer = server_peer
	
	err = multiplayer.peer_connected.connect(_on_peer_connected) as Error
	if err:
		return err
	err = multiplayer.peer_disconnected.connect(_on_peer_disconnected) as Error
	if err:
		return err
	
	game_start.emit()
	
	return OK


func join_game(ip_address: String) -> Error:
	print("starting client")
	var client_peer := ENetMultiplayerPeer.new()
	var err := client_peer.create_client(ip_address, SERVER_PORT)
	if err:
		return err
		
	multiplayer.multiplayer_peer = client_peer
	
	game_start.emit()
	
	return OK


func _on_peer_connected(id: int) -> void:
	print("player %s has joined" % id)


func _on_peer_disconnected(id: int) -> void:
	print("player %s has left" % id)
