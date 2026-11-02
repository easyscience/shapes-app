// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Structure viewer (Structure.qml). Turns an atom's square to face the
// camera, sized by the atom's radius (the instance scale) times the
// material's radiusScale, below 1 while bonds show. An atom outside
// the slab goes behind the far plane and is never drawn; slabAxis and
// slabHalf are the material's properties. Python sends only the slab's
// atoms already; this cut hides the mock's.

VARYING vec2 corner;
VARYING vec4 atomColor;

void MAIN()
{
    atomColor = INSTANCE_COLOR;
    corner = VERTEX.xy;
    vec3 centre = INSTANCE_MODEL_MATRIX[3].xyz;
    if (abs(dot(centre, slabAxis)) > slabHalf) {
        POSITION = vec4(0.0, 0.0, 2.0, 1.0);
    } else {
        float radius = length(INSTANCE_MODEL_MATRIX[0].xyz) * radiusScale;
        vec4 eye = VIEW_MATRIX * vec4(centre, 1.0);
        eye.xy += VERTEX.xy * radius;
        POSITION = PROJECTION_MATRIX * eye;
    }
}
