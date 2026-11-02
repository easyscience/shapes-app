// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle

import Gui.Globals as Globals


// Main-area window: per-component atomistic depiction. Shows the selected
// component on its own in the Qt Quick 3D molecular viewer (parsed atoms drawn
// as CPK spheres). `componentIndex` / `componentName` are set by the page
// Loader. The mock returns one shared template molecule.
//
// mint/mext are atom indices; the viewer draws an orientation arrow
// atom[mint] -> atom[mext] over the molecule.
Rectangle {
    id: root

    // Row in Globals.BackendWrapper.componentsLoaded this window depicts.
    property int componentIndex: -1
    property string componentName: ""
    // Atom indices defining the orientation vector drawn over the molecule
    // (arrow atom[mint] -> atom[mext]); -1 means "no vector".
    property int componentMint: -1
    property int componentMext: -1
    // Goes up when the row changes (its files, Mint, Mext): the atoms
    // and bonds are read again
    property int revision: 0

    color: EaStyle.Colors.mainContentBackground

    BaseMol3dQuick {
        anchors.fill: parent
        atoms: {
            // Read for the dependency only
            root.revision
            return root.componentIndex >= 0
                   ? Globals.BackendWrapper.componentStructureAtoms(root.componentIndex)
                   : []
        }
        // From the topology file: none without one
        bonds: {
            root.revision
            return root.componentIndex >= 0
                   ? Globals.BackendWrapper.componentStructureBonds(root.componentIndex)
                   : []
        }
        vectorStart: root.componentMint
        vectorEnd: root.componentMext
    }

}
