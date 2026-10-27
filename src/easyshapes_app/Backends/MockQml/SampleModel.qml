// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

QtObject {

    // The Model Definition row: name, shape, and whether a lattice
    // repeats the structure. Same names as the Python part.
    property string name: ''
    readonly property var shapes: ['Ring', 'Ball', 'Vesicle', 'Rod', 'Bilayer', 'Monolayer']
    property string shape: 'Ring'
    property bool lattice: false

    // Mock only: the mock Library, set by MockBackend. A save adds to its
    // index, as a library save does
    property var library: null

    // The model's own files. Roles: path, size. A size is a fake label:
    // the mock never touches the disk
    readonly property var files: ListModel {
        id: filesModel
        ListElement { path: 'SampleModel/model.top'; size: '118 kB' }
        ListElement { path: 'SampleModel/model.gro'; size: '2.6 MB' }
    }

    // Fake sizes handed out in order to files the user adds from disk
    readonly property var fakeSizes: ['1.2 MB', '96 kB', '3.4 MB', '512 kB', '17.8 MB']
    property int fakeSizeIndex: 0

    // The mock always holds a model, so there is nothing to create
    function create() {}

    // The mock knows only names: a new model keeps the shape, and brings
    // no files
    function load(modelName) {
        console.debug('SampleModel.load:', modelName)
        name = modelName
        filesModel.clear()
    }

    function importFrom(folder) {
        console.debug('SampleModel.importFrom:', folder)
        name = folder.split(/[\\/]/).pop()
        filesModel.clear()
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
        console.debug('SampleModel.editFile:', filesModel.get(index).path)
    }

    function nameTaken() {
        return (library.availableAssets['SampleModel'] ?? []).includes(name)
    }

    function save(overwrite) {
        library.addAsset('SampleModel', name)
        console.debug('SampleModel.save:', name, 'overwrite:', overwrite)
    }

    // The mock has no file system: a folder ending in 'taken' counts as
    // taken, as in Project.locationTaken
    function exportTaken(folder) {
        return folder.endsWith('taken')
    }

    function exportTo(folder, overwrite) {
        console.debug('SampleModel.exportTo:', name, '->', folder, 'overwrite:', overwrite)
    }

}
