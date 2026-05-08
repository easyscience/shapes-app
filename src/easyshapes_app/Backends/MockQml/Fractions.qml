// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick


// Fractions backend object — instantiable, NOT a singleton.
// One instance per layer/lamella. Tracks the shared component list via
// `source` and adds per-instance `fracs` / `present` state. Sync between
// `source` and the exposed `model` is owned here so GUI consumers only
// bind `model` and read/write roles via DelegateModel.ReadWrite.
QtObject {
    id: root

    // Source list of components this fractions set tracks.
    // Typically `MockLogic.Components.loaded`. May be reassigned.
    property var source: null

    // ListModel exposed to the GUI ListView.
    // Roles: name (mirrored from source), fracs (per-instance),
    // present (per-instance).
    readonly property var model: ListModel { id: backing }

    Component.onCompleted: rebuild()
    onSourceChanged: rebuild()

    // Internal sync. Surgical inserts/removes preserve the per-instance
    // fracs/present state of unaffected rows; full rebuild only on reset
    // or source reassignment.
    property var __sync: Connections {
        target: root.source

        function onRowsInserted(parent, first, last) {
            for (let i = first; i <= last; ++i) {
                const c = root.source.get(i)
                backing.insert(i, { name: c.name, fracs: 1, present: true })
            }
        }
        function onRowsRemoved(parent, first, last) {
            for (let i = last; i >= first; --i) backing.remove(i)
        }
        function onDataChanged(topLeft, bottomRight, roles) {
            for (let i = topLeft.row; i <= bottomRight.row; ++i) {
                backing.setProperty(i, 'name', root.source.get(i).name)
            }
        }
        function onModelReset() { root.rebuild() }
    }

    function rebuild() {
        backing.clear()
        if (!source) return
        for (let i = 0; i < source.count; ++i) {
            const c = source.get(i)
            backing.append({ name: c.name, fracs: 1, present: true })
        }
    }

    function setFracs(index, value) {
        if (index < 0 || index >= backing.count) return
        backing.setProperty(index, 'fracs', value)
    }

    function setPresent(index, value) {
        if (index < 0 || index >= backing.count) return
        backing.setProperty(index, 'present', value)
    }
}
