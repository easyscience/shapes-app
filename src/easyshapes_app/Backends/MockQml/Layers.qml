// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Pattern D backend (multi-row list with selection) for layers, plus a
// parallel JS array of per-layer Fractions instances. ListElement only
// accepts literal scalars, so the Fractions QtObjects can't live inside
// the ListModel rows — they're maintained in lockstep here.
QtObject {
    id: root

    // Source of components shared with every layer's Fractions instance.
    // Each layer keeps its own per-instance fracs/present state but
    // mirrors the same name list.
    property var fractionsSource: null

    // Table of layers. Roles: dmin, rmin.
    readonly property var items: ListModel {
        id: layersModel
        ListElement { dmin: 0.25; rmin: 0.5 }
    }

    // Parallel array of Fractions QtObjects, one per layer.
    // Bumping the revision token triggers rebinding for `var` consumers,
    // since rebuilding the array reference (not its contents) is what
    // QML actually signals on.
    property var fractionsInstances: []
    property int fractionsRevision: 0

    property var __fractionsComponent: null

    Component.onCompleted: {
        __fractionsComponent = Qt.createComponent(Qt.resolvedUrl("Fractions.qml"))
        if (__fractionsComponent.status !== Component.Ready) {
            console.warn("Layers: failed to load Fractions.qml:", __fractionsComponent.errorString())
            return
        }
        const arr = []
        for (let i = 0; i < layersModel.count; ++i) arr.push(__createFractions())
        fractionsInstances = arr
        fractionsRevision++
    }

    function __createFractions() {
        // Bind (don't snapshot) so per-instance Fractions follow later
        // assignments to root.fractionsSource — singleton init order is
        // not deterministic, so the source may be set after this runs.
        const f = __fractionsComponent.createObject(root)
        f.source = Qt.binding(function() { return root.fractionsSource })
        return f
    }

    function appendItem(item) {
        layersModel.append({ dmin: item.dmin, rmin: item.rmin })
        const arr = fractionsInstances.slice()
        arr.push(__createFractions())
        fractionsInstances = arr
        fractionsRevision++
    }

    function removeItem(index) {
        if (index < 0 || index >= layersModel.count) return
        layersModel.remove(index)
        const arr = fractionsInstances.slice()
        const removed = arr.splice(index, 1)[0]
        if (removed) removed.destroy()
        fractionsInstances = arr
        fractionsRevision++
    }

    function setDmin(index, value) {
        if (index < 0 || index >= layersModel.count) return
        layersModel.setProperty(index, 'dmin', value)
    }

    function setRmin(index, value) {
        if (index < 0 || index >= layersModel.count) return
        layersModel.setProperty(index, 'rmin', value)
    }

    function fractionsModelAt(index) {
        if (index < 0 || index >= fractionsInstances.length) return null
        const f = fractionsInstances[index]
        return f ? f.model : null
    }
}
