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

M.offset = vmath.vector3(0)
M.scrollpos = vmath.vector3(0)
M.bounds = vmath.vector3(0)

-- Maximum number of levels
M.MAX_LEVELS = 3

local level = 1 		  -- the current level
local checkpoint = 0	  -- the identifier (number) of the current checkpoint reached
local checkpoints = {}    -- identifier -> world position, populated by each checkpoint on load

-- Collected items
local collected = {
	bananas = 0,
	strawberries = 0
}

-- Reset current checkpoint and registered checkpoints
local function reset_checkpoints()
	checkpoint = 0
	checkpoints = {}
end

-- Get the current level
function M.get_level()
	return level
end

-- Set the current level
function M.set_level(new_level)
	if new_level > 0 and new_level <= M.MAX_LEVELS then
		level = new_level
		reset_checkpoints()
		M.reset_collected()
	end
end

-- Restart a level by clearing checkpoints reached and items collected
function M.restart_level()
	M.clear_checkpoint()
	M.reset_collected()
end

-- Set the next level
function M.next_level()
	local next_level = level + 1
	M.set_level(next_level)
	return level == next_level   -- returns true if next level is a valid level
end

-- Set the previous level
function M.previous_level()
	local previous_level = level - 1
	M.set_level(previous_level)
	return level == previous_level	-- returns true if previous level is a valid level
end

-- Has a next level
function M.has_next_level()
	return level < M.MAX_LEVELS
end

-- Has a previous level
function M.has_previous_level()
	return level > 1 
end

-- Register a checkpoints position so it can be spawned at
function M.register_checkpoint_position(checkpoint_identifier, position)
	checkpoints[checkpoint_identifier] = position
end

-- Set the current checkpoint
function M.set_checkpoint(checkpoint_identifier)
	checkpoint = checkpoint_identifier
end

function M.clear_checkpoint()
	checkpoint = 0
end 

-- Determine if a checkpoint has been reached 
function M.checkpoint_reached()
	return checkpoint > 0 and checkpoints[checkpoint]
end

-- Get the position of current checkpoint reached (if any)
function M.get_checkpoint_pos()
	if M.checkpoint_reached() then
		return checkpoints[checkpoint]
	else
		return nil
	end
end

function M.collect_banana()
	collected.bananas = collected.bananas + 1	
end

function M.get_collected_bananas()
	return collected.bananas
end

function M.collect_strawberry()
	collected.strawberries = collected.strawberries + 1	
end

function M.get_collected_strawberries()
	return collected.strawberries
end

-- Reset all collected counts (level start / transition / new game)
function M.reset_collected()
	collected.bananas = 0
	collected.strawberries = 0
end

-- Determine if a position is on screen (within a specified margin)
function M.onscreen(position, margin)
	if position.x > M.scrollpos.x - margin and
		position.x < M.scrollpos.x + margin + M.CANV_W and
		position.y > M.scrollpos.y - margin and
		position.y < M.scrollpos.y + margin + M.CANV_H then
		return true
	else
		return false
	end
end

-- Set fullscreen
function M.fullscreen(self)
	defos.toggle_fullscreen()
	defos.disable_window_resize()
	defos.disable_maximize_button()
	defos.set_cursor_visible(not defos.is_fullscreen())
end

return M
