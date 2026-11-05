// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick


// Mirrors Backend.configuration and Backend.forceField: the files of one
// asset of the equilibration, its configuration (.mdp files) or its force
// field (.itp). Instantiable, NOT a singleton: MockBackend makes one of
// each. load() replaces the asset with the library's entry of a name.
QtObject {
    id: root

    // The asset's library type: 'AnalysisConfiguration' or 'ForceField'
    property string type: ''
    property string name: ''

    // Mock only: the mock Library, set by MockBackend. A save adds to its
    // index, as a library save does
    property var library: null

    // Mock only: the files of each library entry, set by MockBackend;
    // name -> [{path, size}]. A save adds its own. A size is a fake
    // label: the mock never touches the disk
    property var filesByName: ({})

    // The asset's files. Roles: path, size
    readonly property var files: ListModel { id: filesModel }

    // Fake sizes handed out in order to files the user adds from disk
    readonly property var fakeSizes: ['2 kB', '9 kB', '48 kB', '1.2 MB']
    property int fakeSizeIndex: 0

    Component.onCompleted: load(name)

    function load(entryName) {
        name = entryName
        filesModel.clear()
        for (const file of filesByName[entryName] ?? [])
            filesModel.append(file)
    }

    function appendFile(path) {
        filesModel.append({ path: path, size: nextFakeSize() })
    }

    function nextFakeSize() {
        const label = fakeSizes[fakeSizeIndex % fakeSizes.length]
        fakeSizeIndex = fakeSizeIndex + 1
        return label
    }

    function removeFile(index) {
        if (index < 0 || index >= filesModel.count) return
        filesModel.remove(index)
    }

    function editFile(index) {
        if (index < 0 || index >= filesModel.count) return
        console.debug(`AssetFiles.editFile (${type}):`, filesModel.get(index).path)
    }

    function nameTaken() {
        return (library.availableAssets[type] ?? []).includes(name)
    }

    // A later load of the name brings these files back
    function save(overwrite) {
        const saved = []
        for (let i = 0; i < filesModel.count; ++i)
            saved.push({ path: filesModel.get(i).path, size: filesModel.get(i).size })
        filesByName = Object.assign({}, filesByName, { [name]: saved })
        library.addAsset(type, name)
        console.debug(`AssetFiles.save (${type}):`, name, 'overwrite:', overwrite)
    }

    // The mock has no file system: a folder ending in 'taken' counts as
    // taken, as in Project.locationTaken
    function exportTaken(folder) {
        return folder.endsWith('taken')
    }

    function exportTo(folder, overwrite) {
        console.debug(`AssetFiles.exportTo (${type}):`, name, '->', folder, 'overwrite:', overwrite)
    }
}
