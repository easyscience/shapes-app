// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Shades a bond half's square as a
// cylinder, with StructureSlab.frag's light, floor and sRGB step.

VARYING float across;
VARYING vec2 side;
VARYING vec4 bondColor;

void MAIN()
{
    // The cylinder's normal here, in view space (z toward the viewer)
    vec3 normal = vec3(side * across, sqrt(max(1.0 - across * across, 0.0)));
    // Toward the light: the screen, 15° up
    const vec3 light = vec3(0.0, 0.258819, 0.965926);
    float diffuse = max(dot(normal, light), 0.0);
    vec3 lit = bondColor.rgb * (0.15 + brightness * diffuse);
    FRAGCOLOR = vec4(pow(lit, vec3(1.0 / 2.2)), 1.0);
}
