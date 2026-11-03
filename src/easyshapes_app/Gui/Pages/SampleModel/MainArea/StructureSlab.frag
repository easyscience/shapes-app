// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Shades an atom's square, cut to a
// circle, as a sphere, and a bond half's square as a cylinder:
// StructureBond.vert gives corner across the stick only. The material's
// lighting is the picker's index:
//   0 Default: one light from the screen, lifted 15°, and a 15% floor, as
//     in the Components viewer
//   1 Artistic-free, 2 Artistic-fixed: the structure lit as one sphere.
//     A key light (keyLight, in view space) lights the atoms on the side
//     of the structure that faces it, seen from its centre (outward),
//     with a glint; a backlight opposite it draws a thin bright edge on
//     the atoms of the far side; a 3% floor, for high contrast. Atoms
//     between an atom and the key light shade it: the scene's
//     DirectionalLight, along the key light, casts the shadows, which
//     reach the key light and its glint only. Free, the lights turn with
//     the structure; fixed, they stay put as it turns
//   3 Outline: flat colour in a black outline, as in an illustration
// The material is shaded only for the shadows: MAIN lights the atom, the
// light function takes the shadow, POST_PROCESS puts the two together.
// brightness is the material's property. Qt hands the table's colours
// over linear, and tonemaps a shaded material's output to sRGB. Where two
// atoms overlap, they meet in a straight cut, not a curve: there is no
// per-pixel depth.

VARYING vec2 corner;
VARYING vec4 atomColor;
VARYING vec3 outward;

SHARED_VARS {
    // The key light's share of the colour, which the shadow dims
    vec3 keyLit;
    // The rest
    vec3 otherLit;
    // 1 in full light
    float shadow;
};

void MAIN()
{
    float r2 = dot(corner, corner);
    if (r2 > 1.0)
        discard;
    // The surface's normal here, in view space (z toward the viewer)
    vec3 normal = vec3(corner, sqrt(1.0 - r2));
    vec3 colour = atomColor.rgb;
    SHARED.keyLit = vec3(0.0);
    SHARED.shadow = 1.0;
    if (lighting == 1 || lighting == 2) {
        // Where the atom sits on the structure, seen from its centre
        vec3 dir = length(outward) > 1e-6 ? normalize(outward) : vec3(0.0, 0.0, 1.0);
        // 1 on the side facing the key light, 0 on the far side
        float side = max(dot(dir, keyLight), 0.0);
        // The atom's own roundness, never black
        float shape = 0.5 + 0.5 * dot(normal, keyLight);
        // Brightest where the surface faces halfway between the key light
        // and the viewer
        vec3 halfway = normalize(keyLight + vec3(0.0, 0.0, 1.0));
        float glint = pow(max(dot(normal, halfway), 0.0), 48.0);
        // Edges glow on the structure's far side only
        float rim = smoothstep(0.45, 0.7, dot(normal, -keyLight))
                    * max(dot(dir, -keyLight), 0.0);
        SHARED.keyLit = side * (colour * 1.1 * brightness * shape + vec3(0.4 * glint));
        SHARED.otherLit = colour * 0.03 + mix(colour, vec3(1.0), 0.6) * rim;
    } else if (lighting == 3) {
        // The outer tenth of the radius is the outline
        SHARED.otherLit = r2 > 0.8 ? vec3(0.0) : colour * brightness;
    } else {
        // Toward the light: the screen, 15° up
        const vec3 light = vec3(0.0, 0.258819, 0.965926);
        float diffuse = max(dot(normal, light), 0.0);
        SHARED.otherLit = colour * (0.15 + brightness * diffuse);
    }
}

void DIRECTIONAL_LIGHT()
{
    SHARED.shadow = SHADOW_CONTRIB;
}

void POST_PROCESS()
{
    COLOR_SUM = vec4(SHARED.otherLit + SHARED.keyLit * SHARED.shadow, 1.0);
}
