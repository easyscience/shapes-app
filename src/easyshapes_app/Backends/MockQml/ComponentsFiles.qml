// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Mirrors Backend.componentsFiles: the files of one component of the
// sample, picked from the components list. create() adds an empty
// component, named like a uid, to the list, as MockBackend wires it, and
// picks it; renaming goes through the components list.
QtObject {
    id: root

    // MockBackend adds the named component to the components list, as
    // Backend adds Python's
    signal externalComponentCreated(string name)

    // Name of the picked component; '' for none
    property string selectedComponent: ''

    // Mock only: the mock Library, set by MockBackend. A save adds to its
    // index, as a library save does
    property var library: null

    // Mock only: componentName -> [{path, size}]. A size is a fake label:
    // the mock never touches the disk
    property var filesByComponent: ({
        'DPPC': [
            { path: 'assets/components/DPPC.itp', size: '46 kB' },
            { path: 'assets/components/DPPC.gro', size: '2.4 MB' },
            { path: 'assets/components/DPPC.pdb', size: '3.1 MB' }
        ],
        'DOPC': [
            { path: 'assets/components/DOPC.itp', size: '52 kB' },
            { path: 'assets/components/DOPC.gro', size: '2.7 MB' }
        ],
        'POPC': [
            { path: 'assets/components/POPC.itp', size: '49 kB' }
        ]
    })

    // Fake sizes handed out in order to files the user adds from disk.
    readonly property var fakeSizes: ['74 kB', '1.8 MB', '320 kB', '4.2 MB', '12.5 MB']
    property int fakeSizeIndex: 0

    // The picked component's files. Roles: path, size
    readonly property var files: ListModel { id: filesModel }

    function selectComponent(name) {
        selectedComponent = name
        filesModel.clear()
        for (const file of filesByComponent[name] ?? [])
            filesModel.append(file)
    }

    // Python's library names an unnamed component by its uid; the mock
    // makes up one of the same form
    function create() {
        const name = Math.random().toString(16).slice(2, 14)
        externalComponentCreated(name)
        selectComponent(name)
    }

    // Mock only: MockBackend calls it on a rename in the components
    // list, as Python's refresh follows one
    function followRename(name, newName) {
        if (selectedComponent !== name) return
        filesByComponent = Object.assign({}, filesByComponent, { [newName]: filesByComponent[name] ?? [] })
        selectedComponent = newName
    }

    function appendFile(path) {
        filesModel.append({ path: path, size: nextFakeSize() })
        _syncBack()
    }

    function nextFakeSize() {
        const label = fakeSizes[fakeSizeIndex % fakeSizes.length]
        fakeSizeIndex = fakeSizeIndex + 1
        return label
    }

    function removeFile(index) {
        if (index < 0 || index >= filesModel.count) return
        filesModel.remove(index)
        _syncBack()
    }

    function editFile(index) {
        if (index < 0 || index >= filesModel.count) return
        console.debug('ComponentsFiles.editFile:', filesModel.get(index).path)
    }

    // A component of any type the library holds under the picked name
    function nameTaken() {
        return ['Lipid', 'Surfactant', 'Component'].some(
            type => (library.availableAssets[type] ?? []).includes(selectedComponent))
    }

    function save(overwrite) {
        library.addAsset('Component', selectedComponent)
        console.debug('ComponentsFiles.save:', selectedComponent, 'overwrite:', overwrite)
    }

    // The mock has no file system: a folder ending in 'taken' counts as
    // taken, as in Project.locationTaken
    function exportTaken(folder, row) {
        return folder.endsWith('taken')
    }

    // Row -1 exports the whole component, a row that one file
    function exportTo(folder, row, overwrite) {
        console.debug('ComponentsFiles.exportTo:', selectedComponent, 'row:', row,
                      '->', folder, 'overwrite:', overwrite)
    }

    function _syncBack() {
        const files = []
        for (let i = 0; i < filesModel.count; ++i) {
            const row = filesModel.get(i)
            files.push({ path: row.path, size: row.size })
        }
        filesByComponent = Object.assign({}, filesByComponent, { [selectedComponent]: files })
    }
}
