// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


QtObject {

    // Loaded ions — at most 2 rows. ListModel so the chip Repeater rebinds
    // on append/remove without manual reassignment. Roles: name.
    readonly property var loaded: ListModel {
        id: loadedIonsModel
    }

    readonly property var available: ListModel {
        ListElement { name: 'NA+' }
        ListElement { name: 'CL-' }
        ListElement { name: 'K+' }
        ListElement { name: 'CA2+' }
        ListElement { name: 'MG2+' }
        ListElement { name: 'ZN2+' }
    }

    // Hard cap at the backend layer. The button row also disables itself,
    // but mocks must not be the only place enforcing the rule.
    readonly property int maxIons: 2

    function appendItem(item) {
        if (loadedIonsModel.count >= maxIons) return
        loadedIonsModel.append({ name: item.name })
    }

    function removeItem(index) {
        if (index < 0 || index >= loadedIonsModel.count) return
        loadedIonsModel.remove(index)
    }

    function clear() {
        loadedIonsModel.clear()
    }

    function saveToCatalog() {
        for (let i = 0; i < loadedIonsModel.count; ++i) {
            const row = loadedIonsModel.get(i)
            if (!row.name) continue
            available.append({ name: row.name })
        }
    }

    function removeFromCatalog(index) {
        if (index < 0 || index >= available.count) return
        available.remove(index)
    }
}
