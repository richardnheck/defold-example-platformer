# Plan — Port RotatingPlatform from Godot

## Context

The Godot ninja game at `C:\Users\richa\Documents\My Games\godot-ninja-2d-platform-adventure` defines a `RotatingPlatform` Node2D (see `src/objects/rotating-platform/RotatingPlatform.gd`) with two modes:

- **SPIN**: continuous rotation around a pivot at a configured angular speed.
- **SWING**: back-and-forth arc with eased motion.

A rotator owns `chains` platform bodies equally spaced around the pivot at a fixed radius; each child platform stays visually horizontal as it orbits. The Godot docs explicitly note the player does **not** inherit orbital motion — the player rides via collision only and slides off if the platform moves fast.

Porting this to Defold needs a parent "rotator" GO that drives N spawned child platform GOs each tick. Defold's per-GO transform makes "stay horizontal" automatic: spawned platforms have their own world rotation (0) independent of the rotator, so no explicit counter-rotation step is needed. Each child platform exposes the same `vel` property the existing [game/player/player.script](../../game/player/player.script) ride contract already consumes (lines 250–251, 411–415), so no player-side changes are required.

User-confirmed scope:
- MVP — SPIN and SWING modes; configurable `chains`, `radius`, speeds, swing amplitude.
- Sinusoidal-angle swing easing (mirrors existing `sin_motion` in [platform.script](../../game/platforms/platform.script); exact analytic derivative for `vel`).
- No orbital inheritance for the player.
- Skip Godot's `swing_time_offset`, ClockSwitch `receiving_channel`, length-chain visibility cosmetic, and editor preview drawing.
- Keep "platforms stay horizontal" — naturally satisfied by the Defold per-GO transform.

## Files to create

**[game/platforms/rotating_platform.script](../../game/platforms/rotating_platform.script)** (new)
Minimal script — one line: `go.property("vel", vmath.vector3())`. Position and velocity are set externally by the rotator each tick. No `init`/`fixed_update` needed. The `vel` property is what the player's pcall-probe in [player.script](../../game/player/player.script#L411) latches onto, so ride works automatically.

**[game/platforms/rotating_platform.go](../../game/platforms/rotating_platform.go)** (new)
Mirror [platform.go](../../game/platforms/platform.go):
- Sprite from `/game/core/game.tilesource` (same 64×32 placeholder visual).
- Kinematic collisionobject `co` with group `"world"`, mask `"player"`, same box shape.
- Script component `script` referencing `rotating_platform.script`.

**[game/platforms/rotating_platform_controller.script](../../game/platforms/rotating_platform_controller.script)** (new)

Properties:
- `swing_mode` (bool, default false) — false: SPIN, true: SWING.
- `start_direction` (number, deg, default 0) — initial pivot angle. 0 = +X (right).
- `spin_speed` (number, deg/s, default 90) — SPIN only.
- `swing_degrees` (number, deg, default 90) — SWING amplitude either side of `start_direction`.
- `swing_speed` (number, deg/s peak, default 90) — SWING only. Peak occurs at the centre of the arc.
- `radius` (number, px, default 48) — orbit radius from pivot to platform centre.
- `chains` (number int, default 1) — platforms equally spaced around the pivot.

`init(self)`:
- Cache `self.pivot = go.get_position()` and `self.time = 0`.
- For each `c` in `1..chains`: `factory.create("#platform_factory", self.pivot)`, store `{ id, url = msg.url(nil, id, "script"), angle_offset_rad = (c-1) * 2π / chains }`.
- Precompute `self.omega_swing = swing_speed / swing_degrees` (in 1/s) when in swing mode and `swing_degrees ~= 0`, so peak angular speed equals `swing_speed`.

`fixed_update(self, dt)`:
- Advance `self.time += dt`.
- Compute current `angle_rad` and `angular_vel_rad_per_sec`:
  - SPIN: `angle_rad = (start_direction + spin_speed * time) * π/180`; `angular_vel = spin_speed * π/180`.
  - SWING: `phase = omega_swing * time`; `angle_rad = (start_direction + swing_degrees * sin(phase)) * π/180`; `angular_vel = swing_degrees * omega_swing * cos(phase) * π/180`.
- For each platform `p`: `θ = angle_rad + p.angle_offset_rad`; `pos = pivot + radius * (cos θ, sin θ, 0)`; `vel = radius * angular_vel * (-sin θ, cos θ, 0)` (tangent, derivative of the radial unit vector). Apply with `go.set_position(pos, p.id)` and `go.set(p.url, "vel", vel)`.

Note on sign convention: Defold is Y-up with math-standard positive-CCW; Godot was Y-down with positive-CW. To match Godot's visual sense, flip the sign of `spin_speed` / `swing_speed` per-instance — documented in a script-header comment, no code work needed.

**[game/platforms/rotating_platform_controller.go](../../game/platforms/rotating_platform_controller.go)** (new)
- `factory` component id `platform_factory` referencing `rotating_platform.go`.
- Script component id `script` referencing `rotating_platform_controller.script`.
- No sprite/collision on the rotator itself — it's an invisible controller.

## File to modify

**[game/levels/level1.collection](../../game/levels/level1.collection)**
Add one test instance — an `instances` block for `/game/platforms/rotating_platform_controller.go` at a free position, with `component_properties` overrides for `chains` (e.g. 3), `radius` (e.g. 64), `spin_speed`, and one second instance with `swing_mode: true` and `swing_degrees: 60` to exercise both modes. Same syntax pattern as the existing platform overrides for `vertical` / `distance` / `period` / `linear`.

## Why this design

- **Separate `rotating_platform.go` from existing `platform.go`**: keeps each platform type focused (`platform.go` is self-driven, `rotating_platform.go` is externally driven). Trying to fold both into one script means a flag that disables internal motion, which muddles the `vel` contract.
- **Factory-spawned children, not static collection layout**: matches Godot's programmatic `_add_platform`, lets `chains` vary per instance, and keeps level files clean — one rotator instance produces N platforms.
- **Pivot at the rotator's authored position**: matches Godot (RotatingPlatform is a Node2D positioned at the pivot; platforms are positioned by the parent Pivot rotation).
- **Player code unchanged**: the pcall-probe at [player.script:411](../../game/player/player.script#L411) already accepts any kinematic body that exposes `vel` on a `script` component. Spawned `rotating_platform` instances meet that contract by construction.

## Verification

1. Build via the `defold-project-build` skill (Defold editor must be open on the project).
2. Walk to the test SPIN rotator in level 1. Confirm:
   - Platforms orbit the pivot at the configured radius.
   - Platforms remain visually horizontal as they orbit.
   - Standing on a slow spinner: player rides translationally — drifts in the direction of the platform's tangential motion at that instant and slides off when the platform direction reverses (matches Godot).
   - No FSM flicker into `jump` — the `floor_buffer` from the alignment fix already covers this.
3. Walk to the test SWING rotator. Confirm:
   - Arc back-and-forth with eased motion at the endpoints (matches Godot's feel).
   - Player rides smoothly through the slow portion of the swing.
4. Open level1.collection in the editor, change `chains` from 1 → 3 → 4, rebuild, and confirm chains spawn equally spaced.
5. Verify no `Could not find component 'script'` errors in the console (`/console` endpoint).

## Out of scope

- `swing_time_offset` (Godot's delayed-start parameter).
- `receiving_channel` / ClockSwitch toggling.
- The "chain ladder" cosmetic (Godot draws N platforms in a chain but only renders the outermost — purely visual, no gameplay impact).
- Editor-preview drawing of orbit guides.
- Player orbital-motion inheritance / rotation lock.
- Re-skinning the platform sprite (placeholder reuse of `game.tilesource` is fine for now).
