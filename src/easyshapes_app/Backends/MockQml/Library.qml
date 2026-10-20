// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

// Mirrors shapes.project.Library.
QtObject {

    // Library.available_projects: most recently saved first.
    readonly property var availableProjects: [
        { 'name': 'SDS-ball', 'path': '~/Projects/SDS-ball-0002', 'modified': '10 Oct 2026 16:20' },
        { 'name': 'DPPC-vesicle', 'path': '~/Projects/DPPC-vesicle-0003', 'modified': '02 Oct 2026 09:45' }
    ]

    // Library.available_examples
    readonly property var availableExamples: [
        { 'name': 'SDS-ball', 'path': '~/Examples/SDS-ball' }
    ]

    // Library.available_assets['Ion']
    readonly property var availableIons: [
        'Na<sup>+</sup>', 'Cl<sup>-</sup>', 'Br<sup>-</sup>', 'K<sup>+</sup>',
        'Ca<sup>2+</sup>', 'Mg<sup>2+</sup>', 'Zn<sup>2+</sup>'
    ]

}
