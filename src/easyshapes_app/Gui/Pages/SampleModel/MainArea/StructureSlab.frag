// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Shades an atom's square, cut to a
// circle, as a sphere, and a bond half's square as a cylinder:
// StructureBond.vert gives corner across the stick only. The material's
// lighting is the picker's index:
//   0 Default: one light from the screen, lifted 15°, and a 15% floor, as
//     in the Components viewer
//   1 Volumetric, 2 Vol-tint: the structure lit as one sphere. A key
//     light from the upper left, 55° to the side and 45° up from the
//     view, lights the atoms on the side of the structure that faces
//     it, seen from its centre (outward), with a glint; a backlight
//     opposite it draws a faint edge on the atoms of the far side,
//     strongest at the front of the structure and fading toward its
//     back; a 3% floor, for high contrast. Atoms between an atom and
//     the key light shade it: the scene's DirectionalLight, along the
//     key light, casts the shadows, which reach the key light and its
//     glint only. Vol-tint's key light is 4200 K warm, its backlight
//     10000 K cold
//   3 Hygge: a 2500 K light at the structure's centre, with a glint,
//     and a 4000 K ambient light. Both are brightest near the centre and
//     weaken with the distance from it, measured in structureRadius, the
//     farthest atom's. Atoms between an atom and the centre shade it
//     from the light, not the ambient: the scene's PointLight there
//     casts the shadows
//   4 Outline: flat colour in a black outline, as in an illustration
// The key light sits in view space: it stays put as the structure turns.
// The material is shaded only for the shadows: MAIN lights the atom, the
// light functions take the shadow, POST_PROCESS puts the two together.
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
    // Hygge's light, linear: 2500 K
    const vec3 warm = vec3(1.0, 0.347, 0.061);
    // Where the atom sits on the structure, seen from its centre
    vec3 dir = length(outward) > 1e-6 ? normalize(outward) : vec3(0.0, 0.0, 1.0);
    SHARED.keyLit = vec3(0.0);
    SHARED.shadow = 1.0;
    if (lighting == 1 || lighting == 2) {
        // Toward the key light: as the DirectionalLight, 55° to the side
        // and 45° up from the view
        const vec3 key = vec3(-0.57659, 0.71031, 0.40374);
        // Brightest where the surface faces halfway between the key light
        // and the viewer
        const vec3 halfway = vec3(-0.34412, 0.42393, 0.83778);
        // Vol-tint's key light, linear: 4200 K, 2.3x as strong. 1.41x
        // would make it as bright as Volumetric's white
        vec3 tint = lighting == 2 ? 2.3 * vec3(1.0, 0.649, 0.429) : vec3(1.0);
        // Vol-tint's backlight, linear: 10000 K
        vec3 backTint = lighting == 2 ? vec3(0.589, 0.702, 1.0) : vec3(1.0);
        // 1 on the side facing the key light, 0 on the far side
        float side = max(dot(dir, key), 0.0);
        // The atom's own roundness, never black
        float shape = 0.5 + 0.5 * dot(normal, key);
        float glint = pow(max(dot(normal, halfway), 0.0), 48.0);
        // Edges glow on the structure's far side only, and more toward
        // the screen: 2x at the structure's front, 1x at its centre, none
        // at its back
        float depth = max(1.0 + outward.z / structureRadius, 0.0);
        float rim = smoothstep(0.45, 0.7, dot(normal, -key)) * max(dot(dir, -key), 0.0)
                    * depth;
        SHARED.keyLit = tint * side * (colour * 1.1 * brightness * shape + vec3(0.4 * glint));
        // The edge, 0.6 strong (1.2 at the structure's front)
        SHARED.otherLit = colour * 0.03 + 0.6 * backTint * mix(colour, vec3(1.0), 0.6) * rim;
    } else if (lighting == 3) {
        // Toward the light, at the centre
        vec3 toLight = -dir;
        // Never zero: toLight's z is -1 at the least
        vec3 halfway = normalize(toLight + vec3(0.0, 0.0, 1.0001));
        // The atom's own roundness, never black
        float shape = 0.5 + 0.5 * dot(normal, toLight);
        float glint = pow(max(dot(normal, halfway), 0.0), 48.0);
        // Weaker further from the centre, as 1/d² far out, softened near
        // it: 15 at the centre, 1 at 0.31 of the radius, 0.1 at the
        // farthest atom. Above 1 red clips first: the core looks yellower
        float near = length(outward) / structureRadius;
        float falloff = 15.0 / (1.0 + 149.0 * near * near);
        SHARED.keyLit = falloff * warm * (colour * 1.1 * brightness * shape + vec3(0.4 * glint));
        // The lamp's light bounced around, colder: 4000 K, linear. No
        // shadow, weaker further out: 0.3 at the centre, 0.01 at the
        // farthest atom
        SHARED.otherLit = vec3(1.0, 0.616, 0.382) * colour * 0.3 / (1.0 + 29.0 * near * near);
    } else if (lighting == 4) {
        // The outer tenth of the radius is the outline
        SHARED.otherLit = r2 > 0.8 ? vec3(0.0) : colour * brightness;
    } else {
        // Toward the light: the screen, 15° up
        const vec3 light = vec3(0.0, 0.258819, 0.965926);
        float diffuse = max(dot(normal, light), 0.0);
        SHARED.otherLit = colour * (0.15 + brightness * diffuse);
    }
}

// Both lights always run, in no set order; the one casting no shadow
// gives 1
void DIRECTIONAL_LIGHT()
{
    SHARED.shadow *= SHADOW_CONTRIB;
}

void POINT_LIGHT()
{
    SHARED.shadow *= SHADOW_CONTRIB;
}

void POST_PROCESS()
{
    COLOR_SUM = vec4(SHARED.otherLit + SHARED.keyLit * SHARED.shadow, 1.0);
}
