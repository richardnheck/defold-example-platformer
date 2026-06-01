# Defold Example Platformer

> ⚠️ **Under Construction** — this project is a work in progress and not ready for use yet.

A sample 2D platformer for [Defold](https://defold.com/) that goes beyond the basic
tutorials. It showcases a variety of platforms, traps, and basic enemies, and
demonstrates how to build a clean, maintainable player controller using the
[Stately](https://github.com/britzl/stately) finite state machine library.

The skeleton game code (menus, scene switching, HUD, level loading) is based on
[def-shell](https://github.com/benjames-171/def-shell) by Ben James. Be sure to
check out [Ben James' GitHub](https://github.com/benjames-171) — it's a wealth
of high-quality, well-documented Defold examples and templates.

## Dependencies

### [Stately](https://github.com/britzl/stately)

A small, pure-Lua finite state machine library for Defold by Björn Ritzl. It is
used here to drive the player controller, keeping per-state logic (idle, move,
jump, wall slide, etc.) cleanly separated instead of tangled in one big update
function.