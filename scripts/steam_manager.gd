extends Node

func _ready() -> void:
	var steamInitStatus := Steam.steamInitEx()
	assert(steamInitStatus["status"] == 0, "Failed to initialize steam: "+steamInitStatus["verbal"])
	Steam.initRelayNetworkAccess()
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined)
	#Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.p

	

func _process(_delta: float) -> void:
	Steam.run_callbacks()
