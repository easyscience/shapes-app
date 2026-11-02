// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Cuts an atom's square to a circle and
// shades it as a sphere: one light from the screen, lifted 15°, and a 15%
// floor, as in the Components viewer; brightness is the material's
// property. Qt hands the table's colours over linear, and leaves an
// unshaded material's output as written: it is turned back to sRGB here,
// as Qt does for the viewer's materials. Where two atoms overlap, they meet
// in a straight cut, not a curve: there is no per-pixel depth.

VARYING vec2 corner;
VARYING vec4 atomColor;

void MAIN()
{
    float r2 = dot(corner, corner);
    if (r2 > 1.0)
        discard;
    // The sphere's normal here, in view space (z toward the viewer)
    vec3 normal = vec3(corner, sqrt(1.0 - r2));
    // Toward the light: the screen, 15° up
    const vec3 light = vec3(0.0, 0.258819, 0.965926);
    float diffuse = max(dot(normal, light), 0.0);
    vec3 lit = atomColor.rgb * (0.15 + brightness * diffuse);
    FRAGCOLOR = vec4(pow(lit, vec3(1.0 / 2.2)), 1.0);
}
