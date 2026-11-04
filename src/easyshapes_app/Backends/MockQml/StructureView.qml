// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick
import QtQuick3D


// Mirrors Backend.structureView. Python reads the sample model's .gro
// into its own instancing, which sends the GPU only the slab's atoms;
// the mock shows a small SDS micelle from a FileInstancing table in
// Gui/Resources, always there, and leaves hiding the atoms outside the
// slab to the tab's shader. Its bonds, a second table there, were
// guessed by distance, as the mock Components guesses them; the tab
// hides them while Show bonds is off.
QtObject {
    id: root

    readonly property bool hasStructure: true
    // Off: hiding the tab resets the slab; Python also drops the atoms,
    // the mock's table stays
    property bool keepLoaded: false
    // Python reads the file again with the components' bonds; the
    // mock's table is always there
    property bool showBonds: false
    readonly property bool loading: false
    readonly property string error: ''

    // The properties of Python's StructureInstancing, on Qt's
    readonly property var instancing: FileInstancing {
        source: Qt.resolvedUrl('../../Gui/Resources/sdsmicelle_atoms.xml')
        readonly property int atomCount: instanceCount
        // Farthest atom centre from the centre, Å, from the table's script
        readonly property real radius: 25.8
        // Python counts the slab's atoms; the mock takes the slab's share
        // of them all, rounded up
        readonly property int slabCount: Math.ceil(instanceCount * slabFraction)
        readonly property int shownCount: slabCount
        // Python counts the slab's rows: its atoms and, with bonds, their
        // halves; the mock takes the slab's share of the bond table too
        readonly property int slabRows: slabCount + (root.showBonds
            ? Math.ceil(bondInstancing.instanceCount * slabFraction) : 0)
        property int slabAxis: 2
        property real slabFraction: 0.05
        // Two rows a bond, in Python's layout: the position is the
        // half's start, customData the way to the middle and the radius
        readonly property var bondInstancing: FileInstancing {
            source: Qt.resolvedUrl('../../Gui/Resources/sdsmicelle_bonds.xml')
        }
        // The residue names of the file shown, each drawn while ticked;
        // the mock only lists them
        readonly property var residues: Residues {}
    }

    property bool _active: false

    onKeepLoadedChanged: _resetSlab()

    // Python reads only while the tab is shown; the mock's table is
    // read once
    function setActive(active) {
        _active = active
        _resetSlab()
    }

    function _resetSlab() {
        if (!_active && !keepLoaded)
            instancing.slabFraction = 0.05
    }
}
