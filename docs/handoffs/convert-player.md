# Handoff — Convert Godot ninja player to Defold

Source plan: [docs/plans/convert-player.md](../plans/convert-player.md). Godot reference: `C:\Users\richa\Documents\My Games\godot-ninja-2d-platform-adventure` (see its `docs\game\player\player.md`).

## Status

FSM, jump, double-jump, wall slide, wall jump, var-jump cut, jump buffer, coyote time all working. One outstanding bug — see below.

## What landed since the first pass

- **Wall grab guard** ([player.script:283](../../game/player/player.script#L283)): airborne + `!on_floor` + `jump_held` + `vel.y > 0` (descending) + `(next_to_left or next_to_right)`. Drops the original dir-into-wall requirement and adds the descending check, so grab only fires at the apex regardless of horizontal input.
- **Landing guard** ([player.script:332](../../game/player/player.script#L332)): added `vel.y >= 0`. Prevented immediate `jump → move` re-entry on the same frame as `EV_JUMP` (when `on_floor` was still true from the prior physics step's contact).
- **Coyote time** (`COYOTE_TIME = 0.1`): on `EV_FALL` the coyote window opens and `air_jumped` is pre-locked. A jump press inside the window applies the ground-jump impulse and unlocks `air_jumped`; outside it, no jump fires until landing.
- **Cleanup**: input binding `"action"` renamed to `"jump"` for the player's jump key (menus still use `"action"` for confirm/dismiss); inline `hash()` calls extracted to `ACTION_*` / `MSG_*` constants; `--- State: NAME` headers in `setup_fsm`; doc comments on every `self.*` field in `reset_player_state`; idle/move treats "dir pressed into a blocked wall" as effective `dir = 0` on the ground.

## Open issue — `on_floor` is set incorrectly when against a wall

**Symptom:** Player jumps against a wall, releases jump in flight, keeps holding direction toward the wall. Player ends up suspended high against the wall, FSM in `move` state, run animation looping while horizontally blocked. Visually looks like a wall grab even though `jump_held` is false and the FSM is not in `wall_slide`.

**What the FSM debug log shows:** `on_floor=true` while the player is clearly in mid-air against the wall. With `on_floor` stuck true, `EV_FALL` never fires from `idle`/`move`, so the FSM stays in `move`. The player can't be airborne in `move` by design — they get there because a wall contact is being mis-classified as a floor contact.

**Likely cause:** the contact-buffering code I added in [`collision()` and the top of `fixed_update()`](../../game/player/player.script#L213) — contacts are queued in `on_message` and resolved together at the top of `fixed_update` so I can spot corner artifacts (a wall-tile corner that resolves vertically alongside the real horizontal wall contact). The corner-artifact suppression for *positional correction* works, but the `on_floor` flag is still being set when a corner contact has `normal.y > 0.7`. So a wall corner with a slight upward bias gets read as a floor.

**This is a departure from Defold conventions.** The official platformer tutorial handles all collision resolution inside `on_message` directly, with no buffering and no work in `update`/`fixed_update`. Re-reading those references is the right next step before patching further:

- Defold platformer tutorial: <https://defold.com/tutorials/platformer/>
- `britzl/platypus` (a maintained Defold platformer library by a Defold maintainer): <https://github.com/britzl/platypus>

**Suggested next step:** Revert the buffering. Move all contact handling back into `collision()` (called per `contact_point_response` message), following the platypus pattern for floor-vs-wall classification (e.g. use the dominant axis of the contact normal AND require the contact's *vertical* overlap to be the dominant one before setting `on_floor`, not just `normal.y > 0.7`). Keep the corner-artifact insight — what changes is *where* the classification happens, not whether it happens.

## Useful pointers

- **Stately API** is at [.deps/stately/stately.lua](../../.deps/stately/stately.lua), ~165 LOC. `current_state()` returns a hash; compare with `s.idle.id`, not `s.idle`.
- **Build via editor HTTP**: `POST http://127.0.0.1:$(Get-Content .internal/editor.port)/command/build`. After editing `game.project` dependencies, hit `/command/fetch-libraries` first.
- **Read runtime console**: `GET .../console` returns `{lines, regions}`; filter `lines` with `Where-Object { $_ -match "dbg" }`.
- **FSM state-change debug print** is currently in [player.script:173](../../game/player/player.script#L173) — leave it in place while diagnosing the `on_floor` issue.
- **Old player code preserved** in [game/player/player_copy.script](../../game/player/player_copy.script) and `.go` if you need to diff against the pre-port behaviour.

## Still out of scope

`die` / `celebrate` / `talk` states; SFX; visual effect spawns; level-complete celebration anim before `new_level`.
