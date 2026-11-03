// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Stretches a bond half's square from its
// start (the instance position, its atom's centre) to the bond's middle
// (the instance data's xyz further on), turned to face the camera around
// its axis, 2 x radius (the data's w) wide. Atoms are flat discs at their
// centres: the stick is pushed 0.5 Å back, so a disc covers it near its
// atom and it shows between atoms. As StructureSlab.vert, it moves VERTEX,
// for the shadow map, and a half outside the slab shrinks to nothing;
// Python sends only the slab's. StructureSlab.frag shades it as a
// cylinder: corner runs across the stick only, and lights it as its atom:
// outward is the atom's place from the structure's centre.

VARYING vec2 corner;
VARYING vec4 atomColor;
VARYING vec3 outward;

void MAIN()
{
    atomColor = INSTANCE_COLOR;
    vec3 start = INSTANCE_MODEL_MATRIX[3].xyz;
    outward = mat3(VIEW_MATRIX) * start;
    // The camera's right, up and back, in world space
    vec3 right = vec3(VIEW_MATRIX[0][0], VIEW_MATRIX[1][0], VIEW_MATRIX[2][0]);
    vec3 up = vec3(VIEW_MATRIX[0][1], VIEW_MATRIX[1][1], VIEW_MATRIX[2][1]);
    vec3 back = vec3(VIEW_MATRIX[0][2], VIEW_MATRIX[1][2], VIEW_MATRIX[2][2]);
    NORMAL = back;
    vec3 along = INSTANCE_DATA.xyz;
    // Across the stick on screen; one seen end-on has no way across
    vec2 d = vec2(dot(along, right), dot(along, up));
    vec2 side = length(d) > 1e-6 ? normalize(vec2(-d.y, d.x)) : vec2(1.0, 0.0);
    corner = side * VERTEX.x;
    vec3 offset = along * (VERTEX.y * 0.5 + 0.5)
                  + (right * side.x + up * side.y) * VERTEX.x * INSTANCE_DATA.w
                  - back * 0.5;
    if (abs(dot(start, slabAxis)) > slabHalf)
        offset = vec3(0.0);
    // In the instance's space, which its scale (the bond radius) scales
    VERTEX = offset / length(INSTANCE_MODEL_MATRIX[0].xyz);
}
