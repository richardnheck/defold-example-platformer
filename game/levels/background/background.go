components {
  id: "script"
  component: "/game/levels/background/background.script"
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/builtins/assets/meshes/quad.dae\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/game/levels/background/background.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/assets/images/pixel-adventure/Background/Blue.png\"\n"
  "  }\n"
  "}\n"
  ""
}
