local const            = {}

----------------------
-- Collision
----------------------
const.GROUP   = {
	PLAYER     = hash("player"),
	WORLD      = hash("world"),
	ONE_WAY_PLATFORM = hash("one_way_platform"),
	BOUNDARY     = hash("boundary"),
	ENEMY      = hash("enemy"),
	TRAP       = hash("trap"),
	ITEM       = hash("item")
}

----------------------
-- Messages
----------------------
const.MSG              = {
	-- Defold
	TRIGGER_RESPONSE       = hash("trigger_response"),
	CONTACT_POINT_RESPONSE = hash("contact_point_response"),
	COLLISION_RESPONSE     = hash("collision_response"),
	PROXY_LOADED           = hash("proxy_loaded"),
	PROXY_UNLOADED         = hash("proxy_unloaded"),

	-- Game Control
	SHOW_GAME            = hash("show_game"),
	SHOW_MENU            = hash("show_menu"),
	RELOAD_LEVEL         = hash("reload_level"),
	NEW_LEVEL            = hash("new_level"),
	
	-- Game
	PLAYER_SPAWN         = hash("player_spawn"),
	APPLY_IMPULSE        = hash("apply_impulse"),
	KILL_PLAYER          = hash("kill_player"),
	STOMP_ENEMY          = hash("stomp_enemy"),
	CHECKPOINT_REACHED   = hash("checkpoint_reached"),
	ENDPOINT_REACHED     = hash("endpoint_reached"),

	
	-- RESTART              = hash("restart"),
	-- PLAYER_DIE           = hash("player_die"),
	-- GAME_PAUSE           = hash("game_pause"),
	-- LANDSCAPE_PAUSE      = hash("landscape_pause"),
	-- COLLECT              = hash("collect"),
	-- PLAYER_HEALTH_UPDATE = hash("player_health_update"),
	-- TOGGLE_AUDIO         = hash("toggle_audio"),
}

return const