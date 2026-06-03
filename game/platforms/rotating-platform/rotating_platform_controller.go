components {
  id: "script"
  component: "/game/platforms/rotating-platform/rotating_platform_controller.script"
}
embedded_components {
  id: "marker"
  type: "sprite"
  data: "default_animation: \"player\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 24.0\n"
  "  y: 24.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/game/core/game.tilesource\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "platform_factory"
  type: "factory"
  data: "prototype: \"/game/platforms/rotating-platform/rotating_platform.go\"\n"
  ""
}
