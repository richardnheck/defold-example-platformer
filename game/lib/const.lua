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
	LOAD                   = hash("load"),
	UNLOAD                 = hash("unload"),
	PROXY_LOADED           = hash("proxy_loaded"),
	PROXY_UNLOADED         = hash("proxy_unloaded"),
	SET_TIME_STEP          = hash("set_time_step"),
	ENABLE                 = hash("enable"),
	DISABLE                = hash("disable"),
	EXIT                   = hash("exit"),

	-- Game Controls and GUI
	SHOW_GAME            = hash("show_game"),
	SHOW_MENU            = hash("show_menu"),
	RELOAD_LEVEL         = hash("reload_level"),
	NEW_LEVEL            = hash("new_level"),
	QUIT                 = hash("quit"),
	SHOW                 = hash("show"),
	MUSIC_PLAY           = hash("music_play"),
	MUSIC_STOP           = hash("music_stop"),
	INPUT                = hash("input"),
	
	-- Game
	POINT                = hash("point"),                  -- for the view camera
	RESET                = hash("reset"),                  -- for the view camera
	PLAYER_SPAWN         = hash("player_spawn"),
	APPLY_IMPULSE        = hash("apply_impulse"),
	KILL_PLAYER          = hash("kill_player"),
	STOMP_ENEMY          = hash("stomp_enemy"),
	CHECKPOINT_REACHED   = hash("checkpoint_reached"),
	ENDPOINT_REACHED     = hash("endpoint_reached"),
	COLLECTED            = hash("collected"),
	PLAYER_DIED          = hash("player_died"),
	PLAYER_DEATH_COMPLETE = hash("player_death_complete"), -- player → level: death animation finished
	LEVEL_COMPLETE       = hash("level_complete")          -- player → level: endpoint reached + celebrated
}

----------------------
-- URLs
----------------------
const.URLS             = {
	PLAYER           = "/common/player",
	GUI              = "/common/view#game",
	GAMEOVER         = "/common/view#gameover",
	CLEAR            = "/common/view#clear",
	COMPLETE         = "/common/view#complete",
	CAMERA_SCRIPT    = "/common/view#script",
	LEVEL            = "/level#level",   -- the level script; the level GO id is "level" in every level collection

	MAIN_HANDLER     = "main:/handler",
	MAIN_SOUND       = "main:/sound",

	GAME_LOADER      = "game:/loader"
}

----------------------
-- ACTIONs
----------------------
-- Actions defined in game.input_binding
const.ACTIONS             = {
	JUMP                = hash("jump"),
	TOUCH               = hash("touch"),
	UP                  = hash("up"),
	DOWN                = hash("down"),
	LEFT                = hash("left"),
	RIGHT               = hash("right"),
	CONFIRM             = hash("action"),
	START               = hash("start"),
	EXIT                = hash("exit"),
	FULLSCREEN          = hash("fullscreen"),
	DEBUG               = hash("debug")
}

----------------------
-- Audio
----------------------
const.AUDIO            = {
	-- UI
	BEEP             = "#beep",
	SELECT           = "#select",

	-- PLAYER SFX
	JUMP             = "#jump",
	AIR_JUMP         = "#air-jump",
	DIE              = "#die",
	LAND             = "#land",
	SPAWN            = "#spawn",

	-- GAME SFX
	THUD             = "#thud",
	CANNON_SHOOT     = "#cannon-shoot",
	CANNON_BALL_EXPLOSION = "#cannon-ball-explosion",
	BOMB_TICK        = "#bomb-tick",
	BOMB_EXPLOSION   = "#bomb-explosion",
	SPRING           = "#spring",
	TRIGGER          = "#trigger",
	CHECKPOINT       = "#checkpoint",
	COMPLETE         = "#complete",
	COLLECT          = "#collect",
	FIRE             = "#fire",
	STOMP            = "#stomp",

	-- MUSIC
	MUSIC_TITLE      = "#music-title",
	MUSIC_LEVEL      = "#music-level",	-- Path for level music is created based on this and the level number

	-- MUSIC SETTINGS
	MUSIC_GAIN       = 0.3,		-- The gain for music. It is set here as it is required for fading music in and out
	FADE_TIME        = 0.6,		-- The time in seconds to fade in and out music
	
	GROUP_MASTER     = hash("master"),

	
}

return const