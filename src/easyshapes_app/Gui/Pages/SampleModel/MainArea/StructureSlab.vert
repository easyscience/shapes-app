// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Turns an atom's square to face the
// camera, sized by the atom's radius (the instance scale) times the
// material's radiusScale, below 1 while bonds show. It moves VERTEX, not
// POSITION: Qt then places the square in every pass, the shadow map's
// too. An atom outside the slab shrinks to nothing and is never drawn;
// slabAxis and slabHalf are the material's properties. Python sends only
// the slab's atoms already; this cut hides the mock's. outward is the
// atom's place from the structure's centre (the world's origin), in view
// space, for the Volumetric and Hygge lights.

VARYING vec2 corner;
VARYING vec4 atomColor;
VARYING vec3 outward;

void MAIN()
{
    atomColor = INSTANCE_COLOR;
    corner = VERTEX.xy;
    vec3 centre = INSTANCE_MODEL_MATRIX[3].xyz;
    outward = mat3(VIEW_MATRIX) * centre;
    // The camera's right, up and back, in world space
    vec3 right = vec3(VIEW_MATRIX[0][0], VIEW_MATRIX[1][0], VIEW_MATRIX[2][0]);
    vec3 up = vec3(VIEW_MATRIX[0][1], VIEW_MATRIX[1][1], VIEW_MATRIX[2][1]);
    NORMAL = vec3(VIEW_MATRIX[0][2], VIEW_MATRIX[1][2], VIEW_MATRIX[2][2]);
    float size = abs(dot(centre, slabAxis)) > slabHalf ? 0.0 : radiusScale;
    // In the instance's space, which the atom's radius scales
    VERTEX = size * (right * corner.x + up * corner.y);
}
