// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Backend for the "SMILES generator" (Advanced sidebar). Mirrors the shapespyer
// `smiles` tool: a molecule is described by a chemical formula, a short name and
// a SMILES string (hydrogens are added automatically), and is generated into a
// 3D configuration inside a simulation box. The output is a structure file
// (.gro / .pdb) that can feed a component's files.
//
// A .sml record looks like:  C12SO4  SDS  CCCCCCCCCCCCOS(=O)(=O)[O-]
// followed by a trailing  Box  Lx Ly Lz.
QtObject {
    id: root

    // Molecule identity. `formula` is the chemical formula used as the record
    // key in a .sml file (e.g. C12SO4); `moleculeName` is the short name (SDS).
    property string moleculeName: ''
    property string formula: ''

    // The SMILES string itself.
    property string smiles: ''

    // Simulation box edge lengths in nm.
    property real boxX: 1.0
    property real boxY: 1.0
    property real boxZ: 1.0

    // Output configuration format.
    readonly property var formatOptions: ['GROMACS (.gro)', 'PDB (.pdb)']
    property string format: 'GROMACS (.gro)'

    // Component type assigned to the component created on Generate. Display
    // labels; 'Component (Other)' maps to the stored 'Other'. Defaults to the
    // generic 'Component (Other)'.
    readonly property var componentTypeOptions: ['Lipid', 'Surfactant', 'Component (Other)']
    property string componentType: 'Component (Other)'

    // Generation flags (mirror the shapespyer getMolecule arguments):
    //   cisDoubleBonds → dbcis = ['C'] (kink C=C double bonds to cis).
    //   alignZ         → align the backbone to the Z axis.
    //   flatXZ         → flatten into the XZ plane; only acts when alignZ is on.
    property bool cisDoubleBonds: false
    property bool alignZ: false
    property bool flatXZ: false

    // True once a name and a SMILES string are provided.
    property bool ready: false

    onMoleculeNameChanged: _recompute()
    onSmilesChanged: _recompute()

    function generate() {
        if (!ready) return false
        console.debug('SmilesGenerator.generate:',
                      'formula=' + formula, 'name=' + moleculeName,
                      'smiles=' + smiles,
                      'box=[' + boxX + ',' + boxY + ',' + boxZ + ']',
                      'format=' + format)
        return true
    }

    function _recompute() {
        ready = (moleculeName || '').trim() !== '' && (smiles || '').trim() !== ''
    }
}
