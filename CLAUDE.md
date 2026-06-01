# defold-platformer-experimentation

A Defold platformer game. Bootstrap is [main/main.collection](main/main.collection) using [main/custom.render](main/custom.render). Single external dep: [defos](https://github.com/subsoap/defos).

## Goal

Port the player from the Godot 3 game at `C:\Users\richa\Documents\My Games\godot-ninja-2d-platform-adventure` into this Defold project. Source of truth for player behaviour is that repo's `docs\game\player\player.md` — a `KinematicBody2D` ninja with a stack-based FSM (idle/move/jump/air_jump/wall_slide/wall_jump/die/celebrate/talk), coyote time + jump buffer, wall raycasts, variable jump height, and spawned effects/SFX. Re-implement the same mechanics using Defold idioms (collection + .go + .script, physics, `msg.post`, hash-based states) under [game/player/](game/player/), driven from [game/core/game.collection](game/core/game.collection).

## Layout

- [main/](main/) — bootstrap. [handler.script](main/handler.script) owns two collectionproxies (`menu`, `game`) and swaps them via `show_game` / `show_menu` messages. Also holds [main.atlas](main/main.atlas), [game.input_binding](main/game.input_binding), shared [data.lua](main/data.lua) / [ui.lua](main/ui.lua).
- [menu/](menu/) — main menu, controls, credits GUIs loaded via proxy.
- [game/](game/) — gameplay, loaded via proxy.
  - [core/](game/core/) — [game.collection](game/core/game.collection) (root), [camera.script](game/core/camera.script), [loader.script](game/core/loader.script), shared `common.collection`, tilesource.
  - [levels/](game/levels/) — [level.script](game/levels/level.script) + per-level `.collection` / `.tilemap`.
  - [player/](game/player/) — [player.go](game/player/player.go) + [player.script](game/player/player.script).
  - [gui/](game/gui/) — in-game HUD, pause, gameover, complete, shutter overlays.
- [assets/](assets/) — `font/`, `ogg/`, `png/`.

## Build and Run Game

Use the `defold-project-build` skill. Requires the Defold editor to be running with this project open.

## Conventions

- Graphics: nearest-neighbour filtering (pixel art).
- `shared_state = 1` — Lua state shared across scripts; required by [data.lua](main/data.lua) / [ui.lua](main/ui.lua).
- Scene switching always goes through `handler.script`; don't load proxies directly from gameplay code.
