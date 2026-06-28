components {
  id: "player"
  component: "/game/player/player.script"
}
components {
  id: "ground_hit"
  component: "/game/player/ground_hit.particlefx"
  position {
    y: 1.0
    z: 0.4
  }
}
components {
  id: "jump"
  component: "/game/player/jump.particlefx"
  position {
    y: 1.0
    z: 0.4
  }
}
components {
  id: "run"
  component: "/game/player/run.particlefx"
  position {
    x: -5.0
    y: 1.0
    z: 0.4
  }
}
components {
  id: "slide_right"
  component: "/game/player/slide.particlefx"
  position {
    x: 8.0
    y: 12.0
    z: 0.4
  }
}
components {
  id: "slide_left"
  component: "/game/player/slide.particlefx"
  position {
    x: -5.0
    y: 12.0
    z: 0.4
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"player-idle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlas/characters.atlas\"\n"
  "}\n"
  ""
  position {
    y: 16.0
    z: 0.5
  }
}
embedded_components {
  id: "co"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"player\"\n"
  "mask: \"world\"\n"
  "mask: \"platform\"\n"
  "mask: \"one_way_platform\"\n"
  "mask: \"item\"\n"
  "mask: \"enemy\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: 14.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "    id: \"head\"\n"
  "  }\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: 9.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 1\n"
  "    count: 1\n"
  "    id: \"body\"\n"
  "  }\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      y: 3.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 2\n"
  "    count: 3\n"
  "    id: \"feet\"\n"
  "  }\n"
  "  data: 9.0\n"
  "  data: 9.0\n"
  "  data: 5.0\n"
  "  data: 3.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "co_traps_enemies"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"player\"\n"
  "mask: \"trap\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      y: 11.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "    id: \"box\"\n"
  "  }\n"
  "  data: 4.400817\n"
  "  data: 8.5\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
