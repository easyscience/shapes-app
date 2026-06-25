// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Pattern D backend (multi-row list with selection) for structure files
// shown in the Advanced sidebar of the Sample Model page.
// Roles: path.
QtObject {

    readonly property var files: ListModel {
        id: filesModel
        ListElement { path: 'structure/topology.top' }
        ListElement { path: 'structure/coordinates.gro' }
        ListElement { path: 'structure/serialized.dat' }
    }

    function appendItem(item) {
        filesModel.append({ path: item.path || '' })
    }

    function appendPath(path) {
        filesModel.append({ path: path })
    }

    function removeItem(index) {
        if (index < 0 || index >= filesModel.count) return
        filesModel.remove(index)
    }

    function clear() {
        filesModel.clear()
    }

    // Mock placeholder — real backend will persist to the asset library.
    function saveToLib() {
        console.debug('StructureFiles.saveToLib: paths=' + filesModel.count)
    }

    // Mock placeholder — real backend will write the files to disk.
    function exportFiles() {
        console.debug('StructureFiles.exportFiles: paths=' + filesModel.count)
    }
}
