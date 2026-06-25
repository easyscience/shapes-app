// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Pattern D backend (multi-row list with selection) for the per-component
// file list shown in the Advanced sidebar of the Sample Model page.
//
// The full state is a map of {componentName -> [paths]}. The UI only ever
// sees one component's file list at a time, so we keep that as a single
// ListModel (`files`) and repopulate it whenever the user picks a different
// component through `selectComponent(name)`. Storing the active list as a
// ListModel (rather than a JS array) keeps role-based delegate properties
// and ItemSelectionModel-driven selection working — see QML_MOCKUP_BACKEND
// Pattern D for the rationale.
QtObject {
    id: root

    // Name of the component whose files are currently being shown.
    // Empty string means no selection — `files` is then empty.
    property string selectedComponent: ''

    // Editable name shown in the name field. Tracks `selectedComponent` when a
    // component is picked from the dropdown, is emptied by `createNew()`, and is
    // the name the file list is persisted under by `save()`.
    property string editName: ''

    // Internal map: componentName -> JS array of file paths. Mutations go
    // through __syncBack() so the map stays consistent with the ListModel.
    property var filesByComponent: ({
        'DPPC': [
            'assets/components/DPPC.itp',
            'assets/components/DPPC.gro',
            'assets/components/DPPC.pdb'
        ],
        'DOPC': [
            'assets/components/DOPC.itp',
            'assets/components/DOPC.gro'
        ],
        'POPC': [
            'assets/components/POPC.itp'
        ]
    })

    // Active file list for `selectedComponent`. Roles: path.
    readonly property var files: ListModel {
        id: filesModel
    }

    function selectComponent(name) {
        selectedComponent = name
        editName = name
        filesModel.clear()
        const list = filesByComponent[name] || []
        for (let i = 0; i < list.length; ++i) {
            filesModel.append({ path: list[i] })
        }
    }

    // Start a fresh, unsaved component: clear the dropdown selection, the name
    // field and the staged file list.
    function createNew() {
        selectedComponent = ''
        editName = ''
        filesModel.clear()
    }

    function appendFile(path) {
        filesModel.append({ path: path })
        if (selectedComponent !== '') __syncBack()
    }

    function removeFile(index) {
        if (index < 0 || index >= filesModel.count) return
        filesModel.remove(index)
        if (selectedComponent !== '') __syncBack()
    }

    // Mock placeholder — real backend will open the file in an editor.
    function editFile(index) {
        if (index < 0 || index >= filesModel.count) return
        console.debug('ComponentsFiles.editFile:', filesModel.get(index).path)
    }

    // Export the whole selected component (all its files). Mock backend
    // just logs — the real backend will write to disk.
    function exportComponent() {
        if (selectedComponent === '') return
        console.debug('ComponentsFiles.exportComponent:', selectedComponent,
                      JSON.stringify(filesByComponent[selectedComponent] || []))
    }

    // Persist the current file list to the asset library under `editName`.
    // For a freshly created component (`selectedComponent === ''`) this stores
    // the staged files under the new name and adopts it as the selection.
    // Renaming an existing component leaves the old map entry untouched (mock
    // only). Returns the saved name so the caller can mirror it into the
    // basic-tab components list.
    function save() {
        const name = (editName || '').trim()
        if (name === '') return ''
        const arr = []
        for (let i = 0; i < filesModel.count; ++i) {
            arr.push(filesModel.get(i).path)
        }
        const copy = Object.assign({}, filesByComponent)
        copy[name] = arr
        filesByComponent = copy
        selectedComponent = name
        editName = name
        console.debug('ComponentsFiles.save:', name, JSON.stringify(arr))
        return name
    }

    function __syncBack() {
        if (selectedComponent === '') return
        const arr = []
        for (let i = 0; i < filesModel.count; ++i) {
            arr.push(filesModel.get(i).path)
        }
        // Reassign the map so the `filesByComponent` property emits its
        // Changed signal — keeps any future bindings on the map honest.
        const copy = Object.assign({}, filesByComponent)
        copy[selectedComponent] = arr
        filesByComponent = copy
    }
}
