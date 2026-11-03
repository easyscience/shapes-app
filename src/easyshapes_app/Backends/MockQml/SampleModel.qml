// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

QtObject {
    id: root

    // The Model Definition row: name, shape, and whether a lattice
    // repeats the structure. Same names as the Python part.
    property string name: ''
    readonly property var shapes: ['Ring', 'Ball', 'Vesicle', 'Rod', 'Bilayer', 'Monolayer']
    property string shape: 'Ring'
    property bool lattice: false

    // An assembly runs: the mock's ends by itself after 10 s. Cancel may
    // stop it 3 s after the start, as in Python
    readonly property bool filesLocked: _run.running
    readonly property bool cancelable: filesLocked && !_delay.running

    // Mock only: the mock Library, set by MockBackend. A save adds to its
    // index, as a library save does
    property var library: null
    // Mock only: the mock components and error, set by MockBackend.
    // Assemble fails into the error dialog without components, as a
    // check before the start does in Python
    property var components: null
    property var error: null

    // A replacement of the model, waiting for the run to stop
    property var _pending: null

    property Timer _run: Timer {
        interval: 10000
        onTriggered: root._end()
    }
    property Timer _delay: Timer {
        interval: 3000
        onTriggered: if (root._pending) root.cancel()
    }

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

    function assemble() {
        if (components.loaded.count === 0) {
            error.message = `ValueError: ${shape} has no components`
            return
        }
        _run.start()
        _delay.start()
    }

    function cancel() {
        _run.stop()
        _end()
    }

    // Calls then once no assembly runs: at once, or after cancelling the
    // running one as soon as Cancel may
    function afterAssembly(then) {
        if (!filesLocked) {
            then()
            return
        }
        _pending = then
        if (cancelable) cancel()
    }

    function _end() {
        _delay.stop()
        const then = _pending
        _pending = null
        if (then) then()
    }

    // The mock knows only names: a new model keeps the shape, and brings
    // no files
    function load(modelName) {
        afterAssembly(() => {
            console.debug('SampleModel.load:', modelName)
            root.name = modelName
            filesModel.clear()
        })
    }

    function importFrom(folder) {
        afterAssembly(() => {
            console.debug('SampleModel.importFrom:', folder)
            root.name = folder.split(/[\\/]/).pop()
            filesModel.clear()
        })
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
