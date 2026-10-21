// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// The vesicle's lamellae, as Backend.lamellae. The first row comes from
// add(), so the compositions follow every row the same way. remove(row)
// is ListModel's own.
ListModel {
    id: root

    // Components every leaflet's composition follows; set by MockBackend
    property var fractionsSource: null

    // One Fractions model per row and leaflet, in row order; an outer one
    // is null while the lamella is symmetric
    readonly property var innerLeafletCompositions: __inner.map(fractions => fractions.model)
    readonly property var outerLeafletCompositions: __outer.map(fractions => fractions ? fractions.model : null)

    property var __inner: []
    property var __outer: []
    property var __fractionsComponent: Qt.createComponent(Qt.resolvedUrl("Fractions.qml"))

    Component.onCompleted: add()

    // The library defaults for every lamella: the page has no scaling
    function add() {
        append({ rmin: 0.25, shellThickness: 0.0, innerLeafletDmin: 0.5, outerLeafletDmin: 0.5, symmetric: true })
    }

    // The compositions follow the rows, however they were added or removed
    onRowsInserted: (parent, first, last) => {
        const inner = __inner.slice()
        const outer = __outer.slice()
        for (let row = first; row <= last; ++row) {
            const fractions = __fractionsComponent.createObject(root)
            // Bound, not copied: MockBackend may set the source later
            fractions.source = Qt.binding(function() { return root.fractionsSource })
            inner.splice(row, 0, fractions)
            // A new lamella is symmetric
            outer.splice(row, 0, null)
        }
        __inner = inner
        __outer = outer
    }
    onRowsRemoved: (parent, first, last) => {
        const inner = __inner.slice()
        const outer = __outer.slice()
        const removed = inner.splice(first, last - first + 1).concat(outer.splice(first, last - first + 1))
        for (const fractions of removed)
            if (fractions)
                fractions.destroy()
        __inner = inner
        __outer = outer
    }

    // Splitting gives the outer leaflet its own composition, sharing
    // drops it. mock: a split one starts from the defaults; the library
    // copies the inner one
    onDataChanged: (topLeft, bottomRight, roles) => {
        const outer = __outer.slice()
        for (let row = topLeft.row; row <= bottomRight.row; ++row) {
            const symmetric = get(row).symmetric
            if (symmetric && outer[row]) {
                outer[row].destroy()
                outer[row] = null
            } else if (!symmetric && !outer[row]) {
                outer[row] = __fractionsComponent.createObject(root)
                outer[row].source = Qt.binding(function() { return root.fractionsSource })
            }
        }
        __outer = outer
    }
}
