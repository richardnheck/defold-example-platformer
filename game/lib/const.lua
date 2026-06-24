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
-- Collectibles
----------------------
const.COLLECTIBLE = {
	BANANA     = hash("banana"),
	STRAWBERRY = hash("strawberry"),
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
	QUIT                 = hash("quit"),
	
	-- Game
	PLAYER_SPAWN         = hash("player_spawn"),
	APPLY_IMPULSE        = hash("apply_impulse"),
	KILL_PLAYER          = hash("kill_player"),
	STOMP_ENEMY          = hash("stomp_enemy"),
	CHECKPOINT_REACHED   = hash("checkpoint_reached"),
	ENDPOINT_REACHED     = hash("endpoint_reached"),
	COLLECTED            = hash("collected")

	
	-- RESTART              = hash("restart"),
	-- PLAYER_DIE           = hash("player_die"),
	-- GAME_PAUSE           = hash("game_pause"),
	-- LANDSCAPE_PAUSE      = hash("landscape_pause"),
	-- COLLECT              = hash("collect"),
	-- PLAYER_HEALTH_UPDATE = hash("player_health_update"),
	-- TOGGLE_AUDIO         = hash("toggle_audio"),
}

----------------------
-- URLs
----------------------
const.URLS             = {
	GUI              = "/common/view#game",

	MAIN_HANDLER     = "main:/handler",

	GAME_LOADER      = "game:/loader"

	-- CAMERA_CONTAINER = "/camera",
	-- CAMERA_ID        = "/camera#camera",
	-- MAP              = "",
	-- MAP_CONTANINER   = "",
	-- GAME             = "/script#game",
	-- BACKGROUND       = "/background",
	-- BACKGROUND_MODEL = "/background#model",
	-- GUI              = "/gui#game",
	-- MOBILE_GUI       = ""
}

----------------------
-- ACTIONs
----------------------
-- Actions defined in game.input_binding
const.ACTIONS             = {
	JUMP        = hash("jump"),
	TOUCH       = hash("touch"),
	UP          = hash("up"),
	DOWN        = hash("down"),
	ACTION      = hash("action"),
	EXIT        = hash("exit"),
}

----------------------
-- Audio
----------------------
const.AUDIO            = {
	UI_BEEP             = "beep"
	-- ON_GROUND        = "/fx#on_ground",
	-- JUMP             = "/fx#jump",
	-- RUN              = "/fx#run",
	-- TRAMPOLINE       = "/fx#trampoline",
	-- MUSIC            = "/audio#music",
	-- COLLECT          = "/fx#collect",
	-- WALL_JUMP        = "/fx#wall_jump",
	-- BOX_CRACK        = "/fx#box_crack",
	-- PIECE_DROP       = "/fx#piece_drop",
	-- FALLING_PLATFORM = "/fx#falling_platform",
	-- PLAYER_DEATH     = "/fx#death",
	-- PLAYER_DISAPPEAR = "/fx#disappear",
	-- PLAYER_APPEAR    = "/fx#appear",
	-- SQUEEZE          = "/fx#squeeze",
	-- FIRE             = "/fx#fire",
	-- CHECKPOINT       = "/fx#checkpoint",
	-- END              = "/fx#end",
}

return const