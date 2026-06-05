# Saw Trap

## Context

The platformer has `fire`, `rock-head`, and platform hazards but no path-following blade. We want a **saw** trap whose centre follows a configurable path and kills the player on contact:

- The path is defined by per-instance properties: a **start**, an **end**, and up to **three optional waypoints** (to build e.g. a square).
- If **start == end** → it loops the path **continuously** (constant speed, in node order).
- If there are **only start + end** (no waypoints) → it goes **back and forth**, with easing so it **slows at the endpoints**.
- A boolean **`show_chain`** property: when true, draw a **chain of dots** along the path using the `saw-chain` atlas animation.

It reuses the project's trap idiom: a `trap`-group KINEMATIC collision object, so the player's existing trap-death handler kills on contact (no kill code needed). Coordinate convention (confirmed): all path points are **relative offsets in pixels from the saw's placed position**.

## Key facts found (reuse these)

- **Atlas** ([platforms-and-items.atlas](../../assets/atlas/platforms-and-items.atlas)): `saw-on` (8 frames, 15fps, loop — the spinning blade), `saw-off` (unused), `saw-chain` (single 8×8 frame, `PLAYBACK_NONE`). Saw image is 38×38. **No atlas edits needed.**
- **Trap kill**: player has `co_traps_enemies` (group `player`, mask `trap`); [player.script:546-549](../../game/player/player.script#L546-L549) calls `player_die()` on `contact_point_response` where `other_group == hash("trap")`. So the saw only needs a `trap`-group collision object — **no script kill logic**. Mirror [rock_head.go](../../game/traps/rock-head/rock_head.go)'s collision object (KINEMATIC, group `trap`), but mask `player` only (the saw doesn't bounce off world).
- **Path motion**: use `go.animate(".", "position", ...)` per segment, chaining via the completion callback — same API as [falling_platform.script:37](../../game/platforms/falling-platform/falling_platform.script#L37). Loop → `EASING_LINEAR`; back-and-forth → `EASING_INOUTSINE` (eases in/out = slows at endpoints).
- **Chain dots**: factory pattern from [rotating_platform_controller.script](../../game/platforms/rotating-platform/rotating_platform_controller.script) — an embedded `factory` component + `factory.create("#factory", world_pos)`. Spawn one static `saw-chain` GO every 8px along each path segment.
- KINEMATIC objects moved by `go.animate`/`go.set_position` still report collisions (platforms + rock-head prove it).

## Files

### 1. NEW `game/traps/saw/saw.script`
Properties (all relative offsets from placement, in px):
```lua
go.property("path_start", vmath.vector3())  -- start offset (default = at placement)
go.property("path_end",   vmath.vector3())  -- end offset
go.property("waypoint1",  vmath.vector3())  -- optional; treated as unset when (0,0,0)
go.property("waypoint2",  vmath.vector3())
go.property("waypoint3",  vmath.vector3())
go.property("speed",      80)               -- px/s
go.property("show_chain", false)
```

`init(self)`:
- `anchor = go.get_position()`. Build ordered world-point list `self.pts`: `anchor + path_start`, then each waypoint with `vmath.length(wp) > 0` (in order 1→2→3), and — only if the path is **open** — `anchor + path_end`.
- **Closed (loop)** when `vmath.length(path_end - path_start) < 0.5`. Store `self.closed`.
- `go.set_position(self.pts[1])`; `self.idx = 1`; `self.dir = 1`.
- If `show_chain`, call `draw_chain(self)`.
- If `#self.pts >= 2`, start motion via `step(self)` (otherwise the saw just spins in place — safe default when nothing is configured).

`step(self)` — animate current node → next, then recurse in the completion callback:
- Next index: **closed** → `self.idx % n + 1` (wrap). **open** → `self.idx + self.dir`, flipping `self.dir` and bouncing the index back when it passes either end (handles the 2-node back-and-forth and longer open paths).
- `duration = vmath.length(to - from) / self.speed`; `easing = self.closed and go.EASING_LINEAR or go.EASING_INOUTSINE`.
- `go.animate(".", "position", go.PLAYBACK_ONCE, to, easing, duration, 0, function() self.idx = to_idx; step(self) end)`.

`draw_chain(self)` — for each segment (`n-1` segments open; `n` segments closed, last wraps `n→1`), walk from node A toward node B in `CHAIN_SPACING = 8` steps and `factory.create("#chain_factory", vmath.vector3(p.x, p.y, -0.1))` (z behind the blade). Dots are static, created once.

No `fixed_update` needed — `go.animate` drives position; `saw-on` spins via the sprite.

### 2. NEW `game/traps/saw/saw.go`
Mirror [rock_head.go](../../game/traps/rock-head/rock_head.go) structure with three components:
- `components`: id `"saw"` → `/game/traps/saw/saw.script`.
- embedded `sprite`: `default_animation: "saw-on"`, texture `/assets/atlas/platforms-and-items.atlas`.
- embedded `collisionobject`: `COLLISION_OBJECT_TYPE_KINEMATIC`, `group: "trap"`, `mask: "player"`, one `TYPE_SPHERE` shape, `data: 16.0` (radius ~16, inside the 38px blade for fair hits), centred.
- embedded `factory`: id `"chain_factory"`, `prototype: "/game/traps/saw/saw_chain.go"`.

### 3. NEW `game/traps/saw/saw_chain.go`
Visual-only dot: one embedded `sprite`, `default_animation: "saw-chain"`, texture `/assets/atlas/platforms-and-items.atlas`. No script, no collision.

### 4. EDIT `game/levels/level2.collection`
Add two root `instances` of `/game/traps/saw/saw.go` (like the existing fire/rock-head instances), each overriding the `saw` component via `component_properties` (Vector3 values as `"x, y, z"`, boolean as `PROPERTY_TYPE_BOOLEAN`):
- **`saw_back_forth`** — `path_end = "128.0, 0.0, 0.0"`, `show_chain = true`. (Open path → eased back-and-forth.)
- **`saw_loop`** — `waypoint1 = "96.0, 0.0, 0.0"`, `waypoint2 = "96.0, 96.0, 0.0"`, `waypoint3 = "0.0, 96.0, 0.0"`, `show_chain = true`. (start/end both default (0,0,0) → closed square loop.)

Positions are best-guess open spots; they will be repositioned in the editor during verification.

## Tooling
`defold-scripts-editing` for `saw.script`; `defold-proto-file-editing` for `saw.go`, `saw_chain.go`, and the `.collection` edit. No `const.lua` changes (group `"trap"` is a literal, already handled by the player).

## Verification
1. Build & launch with `defold-project-build` (Defold editor must be open).
2. In level2 confirm:
   - The back-and-forth saw glides start↔end and **visibly slows near each endpoint** (eased); the loop saw runs the square **continuously at constant speed** in node order.
   - With `show_chain = true`, a line of `saw-chain` dots is drawn along each path (behind the blade); the blade sprite spins.
   - Touching either saw reloads the level (player dies), same as fire/rock-head.
3. Reposition the demo saws and tune `speed`, the sphere radius, or `CHAIN_SPACING` if needed.
```
