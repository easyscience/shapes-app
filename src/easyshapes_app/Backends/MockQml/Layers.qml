// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// The ball's layers, as Backend.layers. The first row comes from add(),
// so the compositions follow every row the same way. remove(row) is
// ListModel's own.
ListModel {
    id: root

    // Components every row's composition follows; set by MockBackend
    property var fractionsSource: null

    // One Fractions model per row, in row order
    readonly property var compositions: __fractions.map(fractions => fractions.model)

    property var __fractions: []
    property var __fractionsComponent: Qt.createComponent(Qt.resolvedUrl("Fractions.qml"))

    Component.onCompleted: add()

    // The library defaults for every layer: the page has no scaling
    function add() {
        append({ dmin: 0.5, rmin: 0.25 })
    }

    // The compositions follow the rows, however they were added or removed
    onRowsInserted: (parent, first, last) => {
        const list = __fractions.slice()
        for (let row = first; row <= last; ++row) {
            const fractions = __fractionsComponent.createObject(root)
            // Bound, not copied: MockBackend may set the source later
            fractions.source = Qt.binding(function() { return root.fractionsSource })
            list.splice(row, 0, fractions)
        }
        __fractions = list
    }
    onRowsRemoved: (parent, first, last) => {
        const list = __fractions.slice()
        for (const fractions of list.splice(first, last - first + 1))
            fractions.destroy()
        __fractions = list
    }
}
