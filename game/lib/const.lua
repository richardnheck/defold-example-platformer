local const            = {}

----------------------
-- Collision
----------------------
const.GROUP   = {
	PLAYER     = hash("player"),
	-- ENEMY      = 2,
	-- TILE       = 4,
	-- ITEM       = 8,
	-- PROP       = 16,
	-- PARTICLES  = 32,
	-- SLOPE      = 64,
	-- PLATFORM   = 128,
	-- DIRECTIONS = 256,
	-- WATERFALL  = 512
}

----------------------
-- Messages
----------------------
const.MSG              = {
	-- Defold
	TRIGGER_RESPONSE     = hash("trigger_response"),

	-- Game
	PLAYER_SPAWN         = hash("player_spawn"),
	APPLY_IMPULSE        = hash("apply_impulse")
	-- RESTART              = hash("restart"),
	-- PLAYER_DIE           = hash("player_die"),
	-- GAME_PAUSE           = hash("game_pause"),
	-- LANDSCAPE_PAUSE      = hash("landscape_pause"),
	-- COLLECT              = hash("collect"),
	-- PLAYER_HEALTH_UPDATE = hash("player_health_update"),
	-- TOGGLE_AUDIO         = hash("toggle_audio"),

	
	-- PROXY
	-- PROXY_LOADED         = hash("proxy_loaded"),
	-- GUY_REMOVED          = hash("guy_removed"),
	-- ENABLE_GAME          = hash("enable_game"),
	-- LOAD_GAME            = hash("load_game"),
	-- DOWNLOAD_ARCHIVE     = hash("download_archive")
}

return const