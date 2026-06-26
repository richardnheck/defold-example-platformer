-- Centralised game navigation / level-flow control.
--
-- Owns every "where do we go next" decision so individual scripts (player, HUD,
-- pause, clear, complete screens) don't each duplicate the level bookkeeping and
-- message routing. Callers just express intent: nav.next_level(), nav.quit_to_menu(), etc.
--
-- shared_state = 1 makes this module a singleton shared across all scripts, and
-- it posts only to absolute URLs, so these functions work from any caller.

local data = require "main.data"
local const = require "game.lib.const"

local M = {}

-- Return to the main menu. Restores normal time step first so quitting from a
-- paused state (time step 0) doesn't leave the menu running stopped.
function M.quit_to_menu()
	msg.post(const.URLS.MAIN_HANDLER, const.MSG.SET_TIME_STEP, {factor = 1, mode = 0})
	msg.post(const.URLS.MAIN_SOUND, "stop_sound")
	msg.post(const.URLS.MAIN_HANDLER, const.MSG.SHOW_MENU)
end

-- Advance to the next level, if there is one.
function M.goto_next_level()
	if data.next_level() then
		msg.post(const.URLS.GAME_LOADER, const.MSG.NEW_LEVEL)
	end
end

-- Go back to the previous level, if there is one.
function M.goto_previous_level()
	if data.previous_level() then
		msg.post(const.URLS.GAME_LOADER, const.MSG.NEW_LEVEL)
	end
end

-- Reload the current level, keeping any reached checkpoint and collected items.
function M.reload_level()
	msg.post(const.URLS.GAME_LOADER, const.MSG.RELOAD_LEVEL)
end

-- Restart the current level from the beginning, clearing checkpoint and collected items.
function M.restart_level()
	data.restart_level()
	msg.post(const.URLS.GAME_LOADER, const.MSG.RELOAD_LEVEL)
end

return M
