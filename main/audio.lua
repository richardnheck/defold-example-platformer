local const = require "game.lib.const"
local data  = require "main.data"

local M = {}

-- Spatial falloff distances in world pixels, measured from the camera centre.
local SPATIAL_NEAR = 64    -- within this distance: full volume
local SPATIAL_FAR  = 420   -- beyond this distance: inaudible (sound is skipped)

-- Tracks the last play time per sound id (for debouncing).
M.gate = {}

-- Mute/Unmute all sound 
function M.mute_sound(mute)
	-- Mute/unmute by setting the gain of the master sound group (bus)
	sound.set_group_gain(const.AUDIO.GROUP_MASTER, mute and 0 or 1)
end

-- Determine whether sound is muted
function M.is_sound_muted() 
	return sound.get_group_gain(const.AUDIO.GROUP_MASTER) == 0
end
	
-- Per-id 50ms cooldown to avoid overlapping/machine-gun playback, then play.
local function play(id, props, complete_function)
	-- Seconds since this id last played (0 if never).
	local t = M.gate[id] or 0
	t = os.clock() - t

	if t > 0.05 then
		M.gate[id] = os.clock()
		sound.play(const.URLS.MAIN_SOUND..id, props, complete_function)
	end
end

-- Camera centre in world space = bottom-left scrollpos + half the visible canvas.
local function listener()
	return data.scrollpos + vmath.vector3(data.CANV_W * 0.5, data.CANV_H * 0.5, 0)
end

-- Play a sound by id, debounced so the same sound can't be spammed.
function M.sound(id, complete_function)
	play(id, {}, complete_function)
end

-- Play a sound positioned in the world: gain falls off with distance from the
-- camera centre and the sound pans left/right depending on which side it's on.
-- `pos` is the source's WORLD position (use go.get_world_position()).
function M.sound_at(id, pos, complete_function)
	local c    = listener()
	local dx   = pos.x - c.x
	local dist = vmath.length(vmath.vector3(dx, pos.y - c.y, 0))

	-- Linear gain: 1 at/inside NEAR, 0 at/beyond FAR.
	local gain
	if dist <= SPATIAL_NEAR then
		gain = 1
	elseif dist >= SPATIAL_FAR then
		return                              -- inaudible: don't spend a voice
	else
		gain = 1 - (dist - SPATIAL_NEAR) / (SPATIAL_FAR - SPATIAL_NEAR)
	end

	-- Pan by horizontal offset relative to half the canvas width, clamped to [-1, 1].
	local pan = math.max(-1, math.min(1, dx / (data.CANV_W * 0.5)))

	play(id, { gain = gain, pan = pan }, complete_function)
end

----------------------
-- Music
----------------------
-- Background music lives on the main:/sound GO, one looping component per track
-- (#music-title, #music-level1, ...). The crossfade animates each component's
-- `gain` property, but go.animate/go.set can only reach instances in the
-- caller's own collection — and gameplay scripts run in a different collection
-- from main:/sound. So we hand the work to handler.script (which shares that
-- collection); see main/handler.script. `id` is like "#music-title".

-- Crossfade to a music track. No-op (in handler) if it's already playing.
function M.music_play(id)
	msg.post(const.URLS.MAIN_HANDLER, const.MSG.MUSIC_PLAY, { id = id })
end

-- Fade out and stop the current music track, if any.
function M.music_stop()
	msg.post(const.URLS.MAIN_HANDLER, const.MSG.MUSIC_STOP)
end

return M
