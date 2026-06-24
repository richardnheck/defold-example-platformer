local M = {}

M.STATE_MENU = 1
M.STATE_CONTROLS = 2
M.STATE_CREDITS = 3
M.STATE_PLAYING = 4
M.STATE_PAUSE = 5
M.STATE_CLEAR = 6
M.STATE_GAMEOVER = 7
M.STATE_COMPLETE = 8

M.state = M.STATE_MENU

M.SCR_W = 0
M.SCR_H = 0
M.CANV_W = 0
M.CANV_H = 0
M.TILE_SIZE = 16
M.PIXEL_SIZE = 4
M.MAX_LEVELS = 3

M.level = 1 		  -- the current level
M.checkpoint = 0	  -- the identifier (number) of the current checkpoint reached
M.checkpoints = {}    -- identifier -> world position, populated by each checkpoint on load
M.time = 0

M.collected = {
	bananas = 0,
	strawberries = 0
}

M.offset = vmath.vector3(0)
M.scrollpos = vmath.vector3(0)
M.bounds = vmath.vector3(0)

local function reset_checkpoints()
	M.checkpoint = 0
	M.checkpoints = {}
end

-- Set the current level
function M.set_level(level)
	M.level = level
	reset_checkpoints()
	M.reset_collected()
end

-- Set the next level
function M.next_level()
	-- increment the level
	M.level = M.level + 1

	-- clear checkpoints
	reset_checkpoints()
	M.reset_collected()
end

-- Set the current checkpoint
function M.set_checkpoint(checkpoint_identifier)
	M.checkpoint = checkpoint_identifier
end

function M.clear_checkpoint()
	M.checkpoint = 0
end 

-- Determine if a checkpoint has been reached 
function M.checkpoint_reached()
	return M.checkpoint > 0 and M.checkpoints[M.checkpoint]
end

-- Get the position of current checkpoint reached (if any)
function M.get_checkpoint_pos()
	if M.checkpoint_reached() then
		return M.checkpoints[M.checkpoint]
	else
		return nil
	end
end

function M.collect_banana()
	M.collected.bananas = M.collected.bananas + 1	
end

function M.get_collected_bananas()
	return M.collected.bananas
end

function M.collect_strawberry()
	M.collected.strawberries = M.collected.strawberries + 1	
end

function M.get_collected_strawberries()
	return M.collected.strawberries
end

-- Reset all collected counts (level start / transition / new game)
function M.reset_collected()
	M.collected.bananas = 0
	M.collected.strawberries = 0
end

function M.world2tile(p)
	return vmath.vector3(math.floor((p.x + M.TILE_SIZE) / M.TILE_SIZE), math.floor((p.y + M.TILE_SIZE) / M.TILE_SIZE), p.z)
end

function M.tile2world(p)
	return vmath.vector3((p.x * M.TILE_SIZE) - (M.TILE_SIZE / 2), (p.y * M.TILE_SIZE) - (M.TILE_SIZE / 2), p.z)
end

function M.hex2rgba(hex)
	hex = hex:gsub("#","")
	local rgba = vmath.vector4(tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255, 1)
	return rgba
end

function M.onscreen(p, m)
	if p.x > M.scrollpos.x - m and
		p.x < M.scrollpos.x + m + M.CANV_W and
		p.y > M.scrollpos.y - m and
		p.y < M.scrollpos.y + m + M.CANV_H then
		return true
	else
		return false
	end
end

function M.capdt(dt)
	if dt > 1/30 then
		dt = 1/30
	end
	return dt
end

function M.ms2str(time)
	local day = math.floor(time / 86400)
	local rem = time % 86400
	local hr = math.floor(rem / 3600)
	rem = rem % 3600
	local min = math.floor(rem / 60)
	rem = rem % 60
	local sec = rem

	local str = ""
	if day > 0 then str = tostring(day) .. "d " end
	if hr > 0 or day > 0 then str = str .. tostring(hr) .. ":" end

	str = string.format("%s%02d:%02d", str, min, math.floor(sec))
	return str
end

function M.fullscreen(self)
	defos.toggle_fullscreen()
	defos.disable_window_resize()
	defos.disable_maximize_button()
	defos.set_cursor_visible(not defos.is_fullscreen())
end

return M
