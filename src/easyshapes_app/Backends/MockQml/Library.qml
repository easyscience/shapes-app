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

    // Library.available_assets: names by type. A save in the Library
    // assets editor adds to it (addAsset)
    property var availableAssets: ({
        'Lipid': ['DPPC', 'DOPC', 'POPC', 'Cholesterol'],
        'Surfactant': ['SDS', 'CTAB', 'Triton-X100'],
        'Component': ['D2O-buffer'],
        'Ion': [
            'Na<sup>+</sup>', 'Cl<sup>-</sup>', 'Br<sup>-</sup>', 'K<sup>+</sup>',
            'Ca<sup>2+</sup>', 'Mg<sup>2+</sup>', 'Zn<sup>2+</sup>'
        ],
        'Solvent': ['TIP3', 'Ethanol'],
        'Salt': ['NaCl', 'KCl', 'Tris', 'HEPES', 'MgCl₂', 'CaCl₂', 'Phosphate', 'EDTA']
    })

    // Library.available_assets['Ion']
    readonly property var availableIons: availableAssets['Ion'] ?? []

    // Library.available_assets['Solvent']
    readonly property var availableSolvents: availableAssets['Solvent'] ?? []

    // Library.available_assets['Salt']
    readonly property var availableSalts: availableAssets['Salt'] ?? []

    // Mock only: what a save writes to the library index
    function addAsset(type, name) {
        const names = availableAssets[type] ?? []
        if (!names.includes(name))
            availableAssets = Object.assign({}, availableAssets, { [type]: names.concat([name]) })
    }

}
