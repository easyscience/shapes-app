// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick
import QtQuick3D


// Mirrors Backend.stageView: the Analysis page's structure viewer.
// Python reads the picked stage's final .gro, <model>-eq<k>.gro, into its
// own instancing; the mock shows the SDS micelle table of the
// StructureView mock, in a copy of its own, so each viewer keeps its own
// slab. The stages are the Equilibration mock's finished ones.
QtObject {
    id: root

    // A row of stages is picked
    readonly property bool hasStructure: selectedStage >= 0
    // As in the StructureView mock: off, hiding the tab resets the slab
    property bool keepLoaded: false
    // Python reads the file again with the components' bonds; the
    // mock's table is always there
    property bool showBonds: false
    readonly property bool loading: false
    readonly property string error: ''

    // The properties of Python's StructureInstancing, on Qt's, as in the
    // StructureView mock
    readonly property var instancing: FileInstancing {
        source: Qt.resolvedUrl('../../Gui/Resources/sdsmicelle_atoms.xml')
        readonly property int atomCount: instanceCount
        // Farthest atom centre from the centre, Å, from the table's script
        readonly property real radius: 25.8
        readonly property int slabCount: Math.ceil(instanceCount * slabFraction)
        readonly property int shownCount: slabCount
        readonly property int slabRows: slabCount + (root.showBonds
            ? Math.ceil(bondInstancing.instanceCount * slabFraction) : 0)
        property int slabAxis: 2
        property real slabFraction: 0.05
        readonly property var bondInstancing: FileInstancing {
            source: Qt.resolvedUrl('../../Gui/Resources/sdsmicelle_bonds.xml')
        }
    }

    // What the picker lists: 'Initial' (status ''), the equilibration's
    // copy of the model that stage 0 starts from, once it holds one; then
    // the finished stages ('done' or 'outdated'). Roles: name, status
    readonly property var stages: ListModel { id: stagesModel }
    // Row of stages shown; -1 with none
    property int selectedStage: -1

    // Mock only: the Equilibration mock, set by MockBackend
    property var equilibration: null
    onEquilibrationChanged: _rebuild()

    // The stage picked by hand, by name; '' until one is. While it is
    // missing from the list, as when it runs again, the newest shows
    property string _picked: ''
    property bool _active: false

    // A status changes in place, a stage joins as a run reaches it
    property var _sync: Connections {
        target: root.equilibration ? root.equilibration.entries : null
        function onDataChanged() { root._rebuild() }
        function onRowsInserted() { root._rebuild() }
    }

    onKeepLoadedChanged: _resetSlab()

    // Python reads only while the tab is shown; the mock's table is
    // read once
    function setActive(active) {
        _active = active
        _resetSlab()
    }

    function selectStage(index) {
        if (index < 0 || index >= stagesModel.count) return
        _picked = stagesModel.get(index).name
        selectedStage = index
    }

    function _rebuild() {
        stagesModel.clear()
        // Mock only: the Equilibration mock holds its copies once a run
        // has started, as Python's equilibration holds <model>.gro
        if (equilibration && equilibration._staged)
            stagesModel.append({ name: 'Initial', status: '' })
        const entries = equilibration ? equilibration.entries : null
        // Row 0 is the equilibration itself
        for (let i = 1; entries && i < entries.count; ++i) {
            const entry = entries.get(i)
            if (entry.status === 'done' || entry.status === 'outdated')
                stagesModel.append({ name: entry.name, status: entry.status })
        }
        let row = stagesModel.count - 1
        for (let i = 0; i < stagesModel.count; ++i)
            if (stagesModel.get(i).name === _picked)
                row = i
        selectedStage = row
    }

    function _resetSlab() {
        if (!_active && !keepLoaded)
            instancing.slabFraction = 0.05
    }
}
