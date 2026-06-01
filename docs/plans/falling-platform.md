# Plan — Port FallingPlatform from Godot

## Context

The Godot ninja game at `C:\Users\richa\Documents\My Games\godot-ninja-2d-platform-adventure` defines a `FallingPlatform` (see `src/objects/falling-platforms/FallingPlatform.gd` and `docs/game/objects/platforms/falling-platform.md`):

- A small platform that hangs in mid-air as a static body.
- When the player steps on it (via a thin `TriggerArea2D` strip directly above), it plays a short shake animation, waits ~0.1 s, then switches its `RigidBody2D` from `MODE_STATIC` to `MODE_RIGID` so Godot's physics drops it under gravity (`gravity_scale = 2.0`).
- Once it leaves the screen, `queue_free()` removes it. One-shot — no respawn.
- The player is not harmed; they can ride it down or jump off.

Porting this to Defold needs to satisfy two constraints unique to this project:

- **All moving platforms in this project are KINEMATIC, not DYNAMIC or STATIC.** Defold offers four collision object types: STATIC (immovable level geometry, can't change position), KINEMATIC (script-driven, no physics forces, but generates collision messages), DYNAMIC (full rigid-body simulation under forces/gravity), and TRIGGER (sensor-only, no collision response). The existing [platform.go](../../game/platforms/platform.go) and [rotating_platform.go](../../game/platforms/rotating_platform.go) are KINEMATIC for two interlocking reasons:
  1. The player at [player.go](../../game/player/player.go) is itself KINEMATIC — the player's motion is integrated by Lua in [player.script](../../game/player/player.script), not by the physics engine. KINEMATIC-vs-DYNAMIC interactions in Defold are awkward (a dynamic body would get pushed by the kinematic player rather than carrying it), so all surfaces the player stands on are kept KINEMATIC for predictable contact.
  2. The player-ride contract reads `vel` from a Lua script component (`go.get(url, "vel")` at [player.script:414](../../game/player/player.script#L414)). A DYNAMIC body's velocity lives inside the physics engine — exposing it via a Lua property would require a glue layer that just duplicates the kinematic pattern. STATIC is out for falling platforms because it cannot move at all.
  The trade-off: gravity has to be integrated by the platform script itself rather than handed to the physics engine — a few lines of vel-accumulation. Worth it to keep one consistent contract for every ride-able surface.
- **The player rides moving surfaces via a `vel` property contract** probed at [player.script:411](../../game/player/player.script#L411) and applied at [player.script:250](../../game/player/player.script#L250). The falling platform must expose `vel` like [platform.script](../../game/platforms/platform.script) does.

User-confirmed scope:
- Trigger gate: **top contact only** — gate on contact normal in `contact_point_response`, matching the Godot trigger strip that sits above the platform.
- Lifecycle: **one-shot** — `go.delete` once the platform has fallen far enough below its start position. Matches Godot's `queue_free`.
- Shake: **simple sinusoidal wobble** on the sprite's local x position — visually equivalent to Godot's 4-keyframe track without the ceremony.

## Files to create

**[game/platforms/falling_platform.go](../../game/platforms/falling_platform.go)** (new)

Mirror [platform.go](../../game/platforms/platform.go) exactly for the sprite + collision setup (same 64×32 placeholder sprite from `/game/core/game.tilesource`, same KINEMATIC collisionobject with group `"world"` / mask `"player"` and the same box shape). The only difference: script component points to `falling_platform.script`.

Self-contained — no factory, no controller. Each falling platform is an independent GO placed in the level (matches Godot's `FallingPlatform.tscn` which is a single scene placed in levels).

**[game/platforms/falling_platform.script](../../game/platforms/falling_platform.script)** (new)

Script properties:
- `vel` (vmath.vector3) — player-ride contract; read each tick by [player.script:250](../../game/player/player.script#L250).
- `shake_delay` (number, default 0.1) — seconds between trigger and fall start. Mirrors Godot's `yield(0.1)`.
- `gravity` (number, default 1500) — px/s², applied to `vel.y` each `fixed_update` once falling. Chosen so the platform falls noticeably faster than the player (player's gravity is ~900 px/s² — `GRAVITY * 60` at [player.script:9](../../game/player/player.script#L9)), echoing Godot's `gravity_scale = 2.0` "snappy drop" feel. Exposed so level designers can tune.
- `shake_amplitude` (number, default 1) — px of sprite x-wobble during shake.
- `shake_freq` (number, default 25) — Hz of wobble (sin frequency in shake state).

Internal constants (top of file, no need to expose):
- `DESPAWN_MARGIN = 32` — px beyond the viewport edge before the platform is removed. Matches half the sprite height so the platform is fully off-screen before deletion.

Despawn uses the existing [data.onscreen(pos, margin)](../../main/data.lua#L45) helper — it tests the platform's position against `data.scrollpos` (written by [camera.script:30](../../game/core/camera.script#L30)) and `data.CANV_W/CANV_H` (written by [custom.render_script:17–20](../../main/custom.render_script#L17-L20)). This is the project's existing viewport-bounds primitive — the level loader uses the same `CANV_W/CANV_H` values at [level.script:9–10](../../game/levels/level.script#L9-L10) — and is the closest analogue to Godot's `VisibilityNotifier2D.screen_exited`.

States (plain Lua-string state machine — too small to justify pulling in `stately`):
- `"idle"` — at rest. `vel = 0`. Listens for player contact.
- `"shaking"` — countdown of `shake_delay` seconds. Sprite wobbles. `vel = 0`. Ignores further player contact.
- `"falling"` — `vel.y -= gravity * dt` each frame; `go.set_position(pos + vel * dt)`. When `data.onscreen(pos, DESPAWN_MARGIN)` returns false, `go.delete`.

`init(self)`:
- `self.state = "idle"`.
- `self.timer = 0`.
- `self.vel = vmath.vector3()`.

`on_message(self, message_id, message, sender)`:
- On `hash("contact_point_response")` while `state == "idle"`:
  - Gate on the player group and on contact normal direction. From the platform's perspective when the player is standing on top, the contact normal points downward into the platform — `message.normal.y < -0.7`. (Sign mirrors the player's own floor check at [player.script:403](../../game/player/player.script#L403), which gates on `normal.y == 1` from the player's perspective; both sides see opposite-pointing normals.)
  - On match: `self.state = "shaking"`, `self.timer = 0`.

`fixed_update(self, dt)`:
- `state == "idle"`: nothing. (`vel` stays at zero, set in init.)
- `state == "shaking"`:
  - `self.timer = self.timer + dt`.
  - Wobble sprite: `go.set("#sprite", "position.x", shake_amplitude * math.sin(2 * math.pi * shake_freq * self.timer))`.
  - When `self.timer >= shake_delay`: reset sprite x to 0, `self.state = "falling"`, `self.timer = 0`.
- `state == "falling"`:
  - `self.vel.y = self.vel.y - gravity * dt` (Defold Y-up — negative vel.y is downward).
  - `local pos = go.get_position() + self.vel * dt; go.set_position(pos)`.
  - If `not data.onscreen(pos, DESPAWN_MARGIN)`: `go.delete()`.

Notes:
- The collision group `"player"` doesn't need a hash compare — by the mask configuration, only player contacts arrive on this object. But check `message.other_group == hash("player")` defensively in case future code expands the mask.
- Re-triggering is impossible by construction: the state transition out of `"idle"` happens on the first qualifying contact, and subsequent contacts hit the `state == "idle"` guard.

## File to modify

**[game/levels/level1.collection](../../game/levels/level1.collection)**

Add one `instances` block for `/game/platforms/falling_platform.go` at a free position (suggest near the existing platform cluster, e.g. `x: 200, y: 200`). Same syntax pattern as the existing platform instances (lines 2–53), with `component_properties` overriding any of `shake_delay`, `gravity`, etc. Defaults are sensible — overrides are optional. A second instance with a heavier `gravity` (e.g. 3000) is useful for play-testing the "snappy drop" feel.

## Why this design

- **Standalone GO, no factory / controller.** Godot's `FallingPlatform.tscn` is placed individually in levels. There's no "rotator" relationship to model — each falling platform owns its own state and lifecycle. Reusing the controller/child pattern from [rotating_platform_controller.script](../../game/platforms/rotating_platform_controller.script) would add ceremony without benefit.
- **Inline state machine, not `stately`.** Three states with linear transitions doesn't justify the dependency.
- **Top-only trigger via normal sign.** Matches Godot's geometric intent (the trigger strip sits above the platform). A bare "any contact" trigger would also arm the fall on side bumps and ceiling bonks, which is more permissive than the source.
- **Sprite wobble on `#sprite.position.x`, not the GO position.** Wobbling the GO would jitter the collision body and could break floor contact on the player. Sprite-local offset is purely visual.
- **Viewport-relative despawn via [data.onscreen](../../main/data.lua#L45).** Matches Godot's `VisibilityNotifier2D.screen_exited` semantics — the platform is removed once it has left the visible playfield, regardless of how far below its start position that is. Reuses the project's existing viewport primitive (camera writes `data.scrollpos`; render script writes `data.CANV_W/H`) so the rule stays consistent with the rest of the codebase. Better than a hard fall-distance constant in two ways: it adapts automatically to tall levels and to camera zoom changes, and a player riding the platform won't see it vanish under them while still on-screen.
- **Player code unchanged.** The pcall-probe at [player.script:414](../../game/player/player.script#L414) already accepts any kinematic body that exposes `vel` on a `script` component. A falling platform satisfies that contract identically to a moving platform — the player rides it down naturally once it falls.

## Verification

1. Build via the `defold-project-build` skill (Defold editor must be open on the project).
2. Walk to the test falling platform in level 1. Confirm:
   - It hangs in place statically when not touched.
   - Stepping on it from above: sprite wobbles for ~0.1 s, then the platform begins falling, accelerating downward.
   - The player rides the platform down — stays on it until they jump off or it disappears.
   - Jumping off mid-fall: the player keeps their own physics (no inheritance of platform velocity, matching the existing player-ride contract).
3. Approach the platform from the side at level — the side bump must **not** trigger the fall (validates the `normal.y` gate).
4. Jump into the platform from below — the underside bonk must **not** trigger the fall.
5. After the platform falls past the despawn threshold, confirm there are no `Could not find component 'script'` errors in the console for the now-deleted platform.
6. Re-enter the level (via menu or reload) — the platform is back at its start position (because re-instantiation happens on level load, not at runtime).

## Out of scope

- Respawn-after-N-seconds.
- A separate falling-platform sprite (placeholder reuse of `game.tilesource` is fine for now).
- Damage to the player when the platform crashes — Godot doesn't do this either.
- Sound effects (Godot version has none).
- Visual chunk/break effect on despawn.
