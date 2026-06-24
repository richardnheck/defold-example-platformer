local const = require "game.lib.const"

local M = {}

-- Tracks the last play time per sound id (for debouncing).
M.gate = {}

-- Play a sound by id, debounced so the same sound can't be spammed.
function M.sound(id)
	-- Seconds since this id last played (0 if never).
	local t = M.gate[id] or 0
	t = os.clock() - t

	-- Per-id 50ms cooldown to avoid overlapping/machine-gun playback.
	if t > 0.05 then
		M.gate[id] = os.clock()
		local url = const.URLS.MAIN_SOUND..id
		sound.play(url)
	end
end

return M
