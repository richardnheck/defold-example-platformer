components {
  id: "spike-ball"
  component: "/game/traps/spiked-ball/spiked-ball.script"
  properties {
    id: "mode"
    value: "2.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "chain"
  type: "sprite"
  data: "default_animation: \"chain-64\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "offset: 0.54\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/platforms-and-items.atlas\"\n"
  "}\n"
  ""
  position {
    y: -28.0
    z: -0.5
  }
}
embedded_components {
  id: "ball"
  type: "sprite"
  data: "default_animation: \"spiked-ball\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/platforms-and-items.atlas\"\n"
  "}\n"
  ""
  position {
    y: -62.0
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"trap\"\n"
  "mask: \"player\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      x: 1.0\n"
  "      y: -62.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "    id: \"circle\"\n"
  "  }\n"
  "  data: 9.0\n"
  "}\n"
  ""
}
