// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Pattern D backend (multi-row list with selection) for structure files
// shown in the Advanced sidebar of the Sample Model page.
// Roles: path, size.
//
// `size` is a fake label — the mock never touches the disk. Files the user
// adds get one from `fakeSizes`, handed out in order. The real backend stats
// the file instead.
QtObject {

    readonly property var files: ListModel {
        id: filesModel
        ListElement { path: 'structure/topology.top'; size: '118 kB' }
        ListElement { path: 'structure/coordinates.gro'; size: '2.6 MB' }
        ListElement { path: 'structure/serialized.dat'; size: '874 kB' }
    }

    readonly property var fakeSizes: ['1.2 MB', '96 kB', '3.4 MB', '512 kB', '17.8 MB']
    property int fakeSizeIndex: 0

    function appendItem(item) {
        appendPath(item.path || '')
    }

    function appendPath(path) {
        filesModel.append({ path: path, size: nextFakeSize() })
    }

    function nextFakeSize() {
        const label = fakeSizes[fakeSizeIndex % fakeSizes.length]
        fakeSizeIndex = fakeSizeIndex + 1
        return label
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

    // Mock placeholder — real backend will write the files into `destination`.
    function exportFiles(destination) {
        console.debug('StructureFiles.exportFiles: paths=' + filesModel.count,
                      '->', destination)
    }
}
