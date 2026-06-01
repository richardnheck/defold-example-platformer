# Port Godot ninja player → Defold

## Context

Goal: replace stubbed [game/player/player.script](game/player/player.script) with FSM matching Godot ninja player at `C:\Users\richa\Documents\My Games\godot-ninja-2d-platform-adventure`. Source spec: that repo's `docs\game\player\player.md` + state files in `src/characters/player/state_machine/`. Mechanics + core anims only. Out of scope this pass: celebrate, talk, die states; SFX; visual effect spawns. Camera/loader/level wiring already in place — port plugs into existing `pos`/`point`/`contact_point_response`/`new_level` message contract.

## 1. Assets — copy individual frame PNGs

Source dir: `<godot>/src/characters/player/sprites/`.
Copy these files into `assets/png/player/`:

- `player-idle1.png` .. `player-idle4.png`
- `player-run5.png` .. `player-run10.png`
- `player-jump11.png`
- `player-jump12.png`
- `player-slide52.png`, `player-slide53.png`

New [main/player.atlas](main/player.atlas) — one animation group per state, images added in order:

- `idle` fps=8 loop → idle1..4
- `run` fps=15 loop → run5..10
- `jump_up` fps=1 → jump11
- `jump_down` fps=1 → jump12
- `slide` fps=5 loop → slide52, slide53

## 2. game.project — fixed timestep + stately dep

Append/edit:
```
[display]
update_frequency = 60

[physics]
use_fixed_timestep = 1

[project]
dependencies = <existing defos URL>, https://github.com/britzl/stately/archive/master.zip
```
Player physics uses `fixed_update(self, dt)` so Godot per-frame constants stay numerically identical.

After editing, run `defold-project-setup` to fetch stately into `.deps/`.

## 3. [game/player/player.go](game/player/player.go) — edits

- Swap sprite component `tile_set` from `/game/core/game.tilesource` → `/main/player.atlas`, `default_animation` → `"idle"`.
- Keep kinematic collisionobject (group `player`, mask `world`) but enlarge: AABB box ~16×28 (or two shapes: feet circle + body box). Decision: replace sphere with `TYPE_BOX` 14w × 28h centred at (0, -2).
- No factory components added (effects skipped per scope).

## 4. [game/player/player.script](game/player/player.script) — full rewrite using stately

`local stately = require("stately.stately")` (verify module path after dependency fetch). Event-driven, replace-only — perfect fit for the chosen FSM semantics.

Properties on `self`:

```
self.vel              -- vmath.vector3
self.dir              -- -1 / 0 / 1 (input, horizontal)
self.facing           -- -1 / 1
self.on_floor         -- bool (from collision)
self.next_to_left     -- bool (raycast)
self.next_to_right    -- bool (raycast)
self.action_held      -- bool (jump key currently down)
self.jump_buffer      -- timer, decrements; doubles as "press happened recently" edge signal
self.jump_cut_applied     -- bool, one-shot short-hop latch reset on each jump/air_jump/wall_jump enter; set true the moment we halve vel.y on release
self.air_jumped       -- bool, single double-jump per airtime
self.fsm              -- stately instance
self.states           -- table holding state refs: states.idle, states.move, ...
self.correction       -- vmath.vector3 (collision resolution accumulator)
```

### Constants (per-frame, Godot values)

```
SPEED          = 125
GRAVITY        = 15
GRAVITY_WALL   = 3
JUMP           = 340
AIR_JUMP       = 280
WALL_JUMP_Y    = 295
WALL_JUMP_X    = 155
FALL_MAX       = 600    -- terminal velocity guard
VAR_JUMP_MULT  = 0.5
JUMP_BUFFER    = 0.2
RAY_LEN        = 10     -- half-width + small margin
```

### States and stately wiring

In `init`:

```lua
self.fsm = stately.create()
local s = {}
s.idle      = self.fsm.state()
s.move      = self.fsm.state()
s.jump      = self.fsm.state()   -- covers ground jump AND ledge fall (no impulse)
s.air_jump  = self.fsm.state()
s.wall_slide = self.fsm.state()  -- internal flag self.clinging toggles cling vs slide gravity
s.wall_jump = self.fsm.state()
self.states = s
```

(Die/celebrate/talk deferred.)

### Event vocabulary

Events are plain strings (or `hash()`). Defined as locals at top of script:

- `EV_MOVE_START` — dir went 0 → non-zero
- `EV_MOVE_STOP` — dir went non-zero → 0
- `EV_JUMP` — buffered jump fires while on_floor
- `EV_FALL` — left ground without explicit jump (used in idle/move → jump fall variant)
- `EV_AIR_JUMP` — jump_buffer > 0 mid-air (fresh press survived ground-jump check), air_jumped == false
- `EV_TOUCH_WALL` — !on_floor, next_to_wall on side matching dir, action_held
- `EV_LEAVE_WALL` — wall gone or stopped pressing into wall (with action_held context)
- `EV_WALL_JUMP` — in wall_slide, action_held + dir pressing AWAY from wall
- `EV_LAND_IDLE` — became on_floor, dir == 0
- `EV_LAND_MOVE` — became on_floor, dir ~= 0

### Transition table

```lua
local function t(from, to, ev) self.fsm.transition(from, to, ev) end

t(s.idle,       s.move,       EV_MOVE_START)
t(s.idle,       s.jump,       EV_JUMP)
t(s.idle,       s.jump,       EV_FALL)

t(s.move,       s.idle,       EV_MOVE_STOP)
t(s.move,       s.jump,       EV_JUMP)
t(s.move,       s.jump,       EV_FALL)

t(s.jump,       s.air_jump,   EV_AIR_JUMP)
t(s.jump,       s.wall_slide, EV_TOUCH_WALL)
t(s.jump,       s.idle,       EV_LAND_IDLE)
t(s.jump,       s.move,       EV_LAND_MOVE)

t(s.air_jump,   s.wall_slide, EV_TOUCH_WALL)
t(s.air_jump,   s.idle,       EV_LAND_IDLE)
t(s.air_jump,   s.move,       EV_LAND_MOVE)

t(s.wall_slide, s.wall_jump,  EV_WALL_JUMP)
t(s.wall_slide, s.jump,       EV_LEAVE_WALL)   -- becomes a falling jump (no impulse)
t(s.wall_slide, s.idle,       EV_LAND_IDLE)
t(s.wall_slide, s.move,       EV_LAND_MOVE)

t(s.wall_jump,  s.wall_slide, EV_TOUCH_WALL)
t(s.wall_jump,  s.idle,       EV_LAND_IDLE)
t(s.wall_jump,  s.move,       EV_LAND_MOVE)

self.fsm.start(s.idle)
```

### Callbacks

`on_enter` for each state plays its animation and sets entry-side flags (impulse, jump_cut_applied reset, etc). `on_update` applies per-frame physics for that state. Stately's callbacks don't pass `self` — capture it in the closure inside `init`.

### Per-state callbacks

Side notes: `apply_gravity(g)` = `self.vel.y = self.vel.y + g`. `var_cut()` = if `!self.action_held and self.vel.y < 0 and !self.jump_cut_applied` then `self.vel.y = self.vel.y * VAR_JUMP_MULT; self.jump_cut_applied = true`. `self.wall_side` = `-1` if `next_to_left`, `+1` if `next_to_right`, `0` otherwise (recomputed each frame before update).

**idle**
- `on_enter`: `sprite.play_flipbook("#sprite", hash("idle"))`, `vel.x = 0`, `jump_cut_applied = false`, `air_jumped = false`.
- `on_update`: `apply_gravity(GRAVITY)`. (Transition firing happens in `fixed_update` orchestration — see below.)

**move**
- `on_enter`: play `run`.
- `on_update`: `vel.x = dir * SPEED`; `facing = dir`; `apply_gravity(GRAVITY)`.

**jump** (covers fresh jump AND ledge fall)
- `on_enter`: if `self.jump_with_impulse` (entry flag set just before firing `EV_JUMP`) then `vel.y = -JUMP`; else leave vel.y unchanged (fall path via `EV_FALL`). `jump_cut_applied = false`. Play `jump_up` if `vel.y < 0`, else `jump_down`.
- `on_update`: `apply_gravity(GRAVITY)`; `vel.x = dir * SPEED`; `var_cut()`; anim swap to `jump_down` when `vel.y > 30`.

**air_jump**
- `on_enter`: `vel.y = -AIR_JUMP`; `air_jumped = true`; `jump_cut_applied = false`; play `jump_up`.
- `on_update`: same as `jump.on_update`.

**wall_slide**
- `on_enter`: `vel.x = 0`; `vel.y = 0`; `facing = wall_side` (face into wall); `jump_cut_applied = false`; play `slide`.
- `on_update`: if `action_held` then `vel.y = 0` (cling). Else if `dir == wall_side` (releasing jump but still pressing INTO wall) then `apply_gravity(GRAVITY_WALL)`. Else `apply_gravity(GRAVITY)` (transitional frame before `EV_LEAVE_WALL` fires).

**wall_jump**
- `on_enter`: `vel.y = -WALL_JUMP_Y`; `vel.x = -wall_side * WALL_JUMP_X`; `facing = -wall_side`; `air_jumped = true` (no air-jump permitted from wall_jump — must touch a wall and wall_jump again to gain another aerial boost); `jump_cut_applied = false`; play `jump_up`.
- `on_update`: same as `jump.on_update`.

### Event-firing orchestration (in `fixed_update`)

Stately is event-driven: events must be fired explicitly. The order each frame:

```
-- (1) Sample raycasts + collision flags already populated
-- (2) Compute wall_side from next_to_left/right
-- (3) on_floor already set by contact_point_response handler
-- (4) Decrement jump_buffer

local cur = self.fsm.current_state()

-- Buffered jump consumption
if self.jump_buffer > 0 and (cur == s.idle or cur == s.move) and self.on_floor then
    self.jump_with_impulse = true
    self.jump_buffer = 0
    self.fsm.handle_event(EV_JUMP)
    cur = self.fsm.current_state()
end

-- Mid-air double-jump press (jump_buffer survived the ground-jump check, so it's a fresh mid-air press).
-- Only valid from `jump` — wall_jump locks the air jump out.
if self.jump_buffer > 0 and not self.air_jumped and cur == s.jump then
    self.jump_buffer = 0
    self.fsm.handle_event(EV_AIR_JUMP)
    cur = self.fsm.current_state()
end

-- Walked off ledge
if (cur == s.idle or cur == s.move) and not self.on_floor then
    self.jump_with_impulse = false
    self.fsm.handle_event(EV_FALL)
    cur = self.fsm.current_state()
end

-- Touched wall mid-air
if (cur == s.jump or cur == s.air_jump or cur == s.wall_jump)
   and not self.on_floor and self.action_held
   and ((self.next_to_left and self.dir < 0) or (self.next_to_right and self.dir > 0)) then
    self.fsm.handle_event(EV_TOUCH_WALL)
    cur = self.fsm.current_state()
end

-- Wall jump trigger
if cur == s.wall_slide and self.action_held
   and self.dir == -self.wall_side and self.wall_side ~= 0 then
    self.fsm.handle_event(EV_WALL_JUMP)
    cur = self.fsm.current_state()
end

-- Leave wall (wall gone or both jump released AND no into-wall input)
if cur == s.wall_slide then
    local still_clinging =
        (self.wall_side ~= 0)
        and (self.action_held or self.dir == self.wall_side)
    if not still_clinging then
        self.fsm.handle_event(EV_LEAVE_WALL)
        cur = self.fsm.current_state()
    end
end

-- Landed
if self.on_floor and (cur == s.jump or cur == s.air_jump or cur == s.wall_jump or cur == s.wall_slide) then
    if self.dir ~= 0 then
        self.fsm.handle_event(EV_LAND_MOVE)
    else
        self.fsm.handle_event(EV_LAND_IDLE)
    end
    cur = self.fsm.current_state()
end

-- Move start/stop (grounded only)
if cur == s.idle and self.dir ~= 0 and self.on_floor then
    self.fsm.handle_event(EV_MOVE_START)
elseif cur == s.move and self.dir == 0 and self.on_floor then
    self.fsm.handle_event(EV_MOVE_STOP)
end

-- (5) Advance current state per-frame physics
self.fsm.update(dt)

-- (6) Clamp vel.y, apply position, sprite flip, point to camera, clear edges
```

### Lifecycle wiring

- `init`: create stately instance + states + transitions per section above, register `on_enter`/`on_update` for each state, call `self.fsm.start(s.idle)`; acquire input focus; init flags (`vel`, `dir`, `facing=1`, `air_jumped=false`, `jump_cut_applied=false`, etc.).
- `on_message`:
  - `"pos"` → `go.set_position(message.pos)`, `vel = 0`, re-`start(s.idle)` the fsm.
  - `"contact_point_response"` → accumulate correction like current script (lines 88–107), set `on_floor = true` when normal.y > 0.7, side-wall flags when |normal.x| > 0.7. Keep tile-pickup logic (lines 47–53) as-is.
  - other existing messages (`show_menu`, `new_level`, etc.) preserved as-is.
- `on_input`:
  - `left`/`right` pressed/released → update `self.dir` (-1, 0, 1 based on which side held).
  - `action` pressed → `self.jump_buffer = JUMP_BUFFER`; `self.action_held = true`. (`jump_buffer > 0` serves as the "just pressed" signal — consumed by whichever event fires.)
  - `action` released → `self.action_held = false`.
  - `exit`, `debug` → preserved.
- `fixed_update(self, dt)`:
  1. Wall raycasts: `physics.raycast(pos, pos + vector3(±RAY_LEN, y_off, 0), {hash("world")})` at y-offsets {-6, +6} per side. Set `next_to_left` / `next_to_right`. Compute `wall_side`.
  2. Decrement `jump_buffer`.
  3. Run **event-firing orchestration** block above — fires events; stately calls relevant `on_enter` callbacks synchronously.
  4. `self.fsm.update(dt)` — runs current state's `on_update`.
  5. Clamp `self.vel.y = math.min(self.vel.y, FALL_MAX)`.
  6. Apply collision correction accumulated from `contact_point_response` last frame, then `go.set_position(go.get_position() + self.vel + self.correction)`. Reset `correction = vmath.vector3()`.
  7. `sprite.set_hflip("#sprite", self.facing < 0)`.
  8. `msg.post("view#script", "point", {pos = go.get_position()})`.
  9. Reset `on_floor` / `next_to_left` / `next_to_right` (re-set next frame by raycast + contact response).

## 5. Collision detection

Three distinct concerns, handled separately:

### 5.1 Collision resolution (push body out of overlap)

Kinematic bodies in Defold don't auto-resolve. Each frame the physics engine posts one `contact_point_response` message per intersection it detects, carrying `normal`, `distance` (penetration depth), and `applied_normal_impulse`. The current player.script already does the standard pattern (lines 88–107):

```lua
local proj = vmath.dot(self.correction, message.normal)
local comp = (message.distance - proj) * message.normal
self.correction = self.correction + comp
go.set_position(go.get_position() + comp)
```

`self.correction` tracks how much we've already pushed out this frame so multiple contacts (e.g. corner of two tiles) don't double-push in the same direction. Keep this verbatim — it's the resolution step, independent of state-machine logic.

### 5.2 Floor detection (`on_floor`)

Drive from the same `contact_point_response` messages. If the contact normal points roughly upward, we're standing on it:

```lua
if message.normal.y > 0.7 then
    self.on_floor = true
end
```

Reset `self.on_floor = false` at the end of each `fixed_update` so it must be re-established by a fresh contact next frame. Contacts fire reliably while gravity holds the player against the floor, so this stays `true` continuously while grounded. The 0.7 threshold accepts mild slopes (≈45°).

### 5.3 Wall detection (`next_to_left`, `next_to_right`)

Contacts get unreliable here: in `wall_slide` we set `vel.x = 0` for cling, so the player isn't actively pushing into the wall — Defold's collision correction has already pushed us out and we may not generate a contact every frame. Solution: poll geometry directly with `physics.raycast` each frame:

```lua
local pos = go.get_position()
local hit_l_top    = physics.raycast(pos + vmath.vector3(0,  6, 0), pos + vmath.vector3(-RAY_LEN,  6, 0), {hash("world")})
local hit_l_bottom = physics.raycast(pos + vmath.vector3(0, -6, 0), pos + vmath.vector3(-RAY_LEN, -6, 0), {hash("world")})
local hit_r_top    = physics.raycast(pos + vmath.vector3(0,  6, 0), pos + vmath.vector3( RAY_LEN,  6, 0), {hash("world")})
local hit_r_bottom = physics.raycast(pos + vmath.vector3(0, -6, 0), pos + vmath.vector3( RAY_LEN, -6, 0), {hash("world")})
self.next_to_left  = hit_l_top ~= nil or hit_l_bottom ~= nil
self.next_to_right = hit_r_top ~= nil or hit_r_bottom ~= nil
```

Two rays per side at small y offsets so a wall covering only head or feet still registers — a single ray could miss at the edge of a tile. `RAY_LEN` = (collision-shape half-width) + 1–2 px margin (e.g. `9` with a 14-wide box).

### 5.4 Frame order

```
contact_point_response messages arrive (between updates)
    → apply correction, set on_floor on upward normals
fixed_update fires:
    1. raycast for next_to_left / next_to_right
    2. orchestration fires events (uses on_floor + next_to_* + input)
    3. fsm.update(dt) runs state on_update (gravity, vel.x)
    4. apply vel → go.set_position
    5. reset on_floor = false, next_to_* = false, correction = vmath.vector3()
```

### 5.5 Known sharp edges

Defold kinematic collision has known issues: corner snags, tunneling at high velocity, slope handling. Ship this scheme, see what feels off, fix incrementally — possible follow-ups include separate feet-circle + body-box shapes, a velocity cap to prevent tunneling, or a one-way platform group.

## 6. What stays unchanged

- [game/core/camera.script](game/core/camera.script) — already smooth-follows on `point`.
- [game/core/loader.script](game/core/loader.script) — `new_level` / `reload_level` wiring.
- [game/levels/level.script](game/levels/level.script) — already posts `pos` to `common/player` from spawn tile.
- [main/game.input_binding](main/game.input_binding) — `left`/`right`/`action` already mapped.
- Tile-pickup behaviour (beep + set_tile) preserved.

## 7. Critical files

- [game/player/player.script](game/player/player.script) — full rewrite (stately FSM).
- [game/player/player.go](game/player/player.go) — sprite tile_set + animation + collision shape change.
- [main/player.atlas](main/player.atlas) — new.
- `assets/png/player/` — new dir, 14 frame PNGs copied from Godot project.
- [game.project](game.project) — fixed timestep settings + stately dependency URL.

## 8. Verification

1. `defold-project-build` — build & launch.
2. Spawn on level 1 → idle animation plays.
3. Left/right → run anim + facing flip, walks at expected speed.
4. Jump (action) → arc rises ~JUMP/GRAVITY frames, peak height feels identical to Godot. Variable height: tap → low hop; hold → full jump.
5. After a ground jump, one mid-air press triggers the double jump (air_jump state). Further mid-air presses do nothing until the player lands and `air_jumped` resets.
6. Hold INTO wall + jump held while airborne → cling (no descent). Release jump while still holding into wall → slow slide at GRAVITY_WALL. Releasing direction or wall absence drops to fall.
7. From cling, press direction AWAY (jump still held) → wall_jump diagonal launch. Air jump is NOT available from wall_jump.
8. Chain wall jumps between two close walls — only re-touching a wall (entering wall_slide again) enables another wall_jump; no aerial double jump in between.
9. Jump buffer: press action ~0.15s before landing → jumps on touch.
10. Tile pickup still emits beep and clears tile.
11. Camera tracks smoothly; `point` messages keep flowing.
12. Level complete tile still routes via existing `new_level` path (no celebrate anim this pass).
13. Side-by-side feel check vs Godot build (numerical constants are identical, so should match).
