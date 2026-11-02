// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Stretches a bond half's square from its
// start (the instance position, its atom's centre) to the bond's middle
// (the instance data's xyz further on), turned to face the camera around
// its axis, 2 x radius (the data's w) wide. Atoms are flat discs at their
// centres: the stick is pushed 0.5 Å back, so a disc covers it near its
// atom and it shows between atoms. A half outside the slab is never drawn,
// as in StructureSlab.vert; Python sends only the slab's.

VARYING float across;
VARYING vec2 side;
VARYING vec4 bondColor;

void MAIN()
{
    bondColor = INSTANCE_COLOR;
    across = VERTEX.x;
    vec3 start = INSTANCE_MODEL_MATRIX[3].xyz;
    if (abs(dot(start, slabAxis)) > slabHalf) {
        side = vec2(1.0, 0.0);
        POSITION = vec4(0.0, 0.0, 2.0, 1.0);
    } else {
        vec4 a = VIEW_MATRIX * vec4(start, 1.0);
        vec4 b = VIEW_MATRIX * vec4(start + INSTANCE_DATA.xyz, 1.0);
        // Across the stick on screen; one seen end-on has no way across
        vec2 d = b.xy - a.xy;
        side = length(d) > 1e-6 ? normalize(vec2(-d.y, d.x)) : vec2(1.0, 0.0);
        vec4 eye = mix(a, b, VERTEX.y * 0.5 + 0.5);
        eye.xy += side * VERTEX.x * INSTANCE_DATA.w;
        eye.z -= 0.5;
        POSITION = PROJECTION_MATRIX * eye;
    }
}
