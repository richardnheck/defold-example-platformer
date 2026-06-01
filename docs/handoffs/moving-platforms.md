# Handoff — Moving platforms

## Status

Platform GO at [game/platforms/platform.go](../../game/platforms/platform.go) + [platform.script](../../game/platforms/platform.script). Properties `vertical` (bool), `distance` (px, total travel ±half), `period` (s, one full cycle). Visual is a 64×32 sprite stretched from the existing `game.tilesource` (placeholder — collision box ended up auto-resized to ~32×16 px by the editor; swap art when ready).

Player rides via [player.script:248-258](../../game/player/player.script#L248) (the platform-ride block in `update()`), with floor-coyote buffer (`FLOOR_BUFFER_FRAMES = 3`) and `platform_id` / `platform_last_pos` tracking from `contact_point_response.other_id` / `other_position`.

**Working:**
- Vertical-down platforms no longer flick the FSM into `jump` state — `floor_buffer` bridges the 1–3 frame contact gaps.
- Horizontal platforms carry the player exactly (no slide). Fix was moving the platform-ride delta from `fixed_update` to `update`: per Defold's lifecycle (with fixed timestep on), `fixed_update → physics → update → late_update`, so reading `go.get_position(platform_id)` from `update` always returns the platform's end-of-frame position. `message.other_position` seeds `platform_last_pos` on attach to avoid first-frame slip.
- Detachment on jump / air-jump / wall-jump clears `platform_id`; auto-detach when `floor_buffer` drains to zero.

## Open issue — vertical-platform vertical alignment is wrong by ~one frame of platform motion

**Symptom:**
- Platform descending → player floats slightly **above** the platform's visual top.
- Platform ascending → player clips slightly **into** the platform.

Constant offset, roughly equal to one frame of platform motion (~5 px at fast settings; ~1 px at defaults).

**Cause:** the platform-ride delta is applied in `update()`, which runs *after* the physics step. Order each frame is:

1. `fixed_update`: player applies gravity (`vel.y += 15` → `pos.y -= 0.25` at 60 Hz); platform applies its sin offset.
2. Physics step:
   - If platform moved up faster than the player dropped: penetration → contact response pushes player up by the penetration depth, sets `vel.y = 0`, sets `on_floor` / `floor_buffer`.
   - If platform moved down faster than the player dropped: gap → no contact, `vel.y` accumulates.
3. `update`: platform-ride delta `(cur - last)` is applied on top of whatever the physics step did.

For UP: contact already pushed the player to platform-top, and then `update` adds the platform's per-frame delta a second time, so the player ends up ~one-frame-of-motion above. For DOWN: no contact correction this frame, and `update` only applies the platform's delta — but the player also already moved down by gravity in step 1, so the player ends up ~one-frame-of-motion further down than the platform's new top.

The horizontal case escapes this because the contact normal is `(0,1)`: contact correction only affects Y, so the horizontal `update` delta is the *only* horizontal motion source. There's nothing to double-count.

**Suggested next step:** move the platform-ride delta out of `update` and apply it inside `fixed_update`, *before* the player's gravity / FSM update and *before* the physics step. Then the physics step sees the player already translated by the platform's motion and only resolves the actual residual penetration (the gravity drop), giving correct alignment.

The catch: when the platform-ride runs at the top of `fixed_update`, `go.get_position(platform_id)` reads whatever the platform's `fixed_update` has done *this tick*. Script-call order within `fixed_update` is not deterministic across collections, so the delta could be from the current tick (good) or from the previous tick (1-frame visual lag — same magnitude as today's bug, but only on velocity changes, not constantly). Two ways to remove that uncertainty:

1. **Sample the platform's *intended* position, not its current position.** Have the platform expose its motion as a script property (e.g. `vel` recomputed each tick = `half * omega * cos(time * omega) * axis`) via `go.property`; the player does `go.get(platform_url, "vel") * dt` for the delta. No dependence on script order. Cleanest fix.
2. **Force the platform to update before the player.** Put the platform-ride in player `update()` *and* the platform's motion in player `update()` too, with the player's main physics moved fully out of `fixed_update` and into `update`. Bigger refactor and ties player physics to render rate.

Option 1 is the recommended path. It also makes the platform's "current velocity" available for things like inheriting platform momentum when the player jumps off — a feature that's currently missing (jumps clear `platform_id` and the player loses any sideways carry).

## Useful pointers

- **Platform-ride logic:** [player.script update()](../../game/player/player.script#L243).
- **Floor-coyote / `is_grounded` helper:** [player.script reset_player_state + is_grounded](../../game/player/player.script#L216).
- **Platform-id capture from contact:** [player.script handle_obstacle_contact](../../game/player/player.script#L351), seeded with `message.other_position`.
- **Defold lifecycle reference (fixed-timestep order):** <https://defold.com/manuals/application-lifecycle/> — key fact: `fixed_update → update → late_update` within a frame.
- The collision box on [platform.go](../../game/platforms/platform.go) was auto-edited to ~32×16 half-extents (smaller than the 64×32 sprite). If you change the sprite art, also resize the box back to 32×16 half-extents (so a 64×32 visual gets a 64×32 collision).

## Out of scope (for now)

- Platform-momentum carry on jump-off (mentioned above as a useful side effect of Option 1).
- Multiple-platform handover (stepping from one platform onto another with overlapping floor contacts).
- Per-platform speed/easing customisation beyond `period` (e.g. linear ping-pong instead of sinusoidal).
