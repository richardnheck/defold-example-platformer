components {
  id: "ball1"
  component: "/game/traps/cannon/ball.script"
}
embedded_components {
  id: "ball"
  type: "sprite"
  data: "default_animation: \"cannon-ball\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: -7.0
    y: 5.0
  }
}
embedded_components {
  id: "co"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"trap\"\n"
  "mask: \"player\"\n"
  "mask: \"world\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 5.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "explosion"
  type: "sprite"
  data: "default_animation: \"cannon-ball-explosion\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/game.atlas\"\n"
  "}\n"
  ""
}
