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
        if (selectedComponent === name) return
        selectedComponent = name
        filesModel.clear()
        const list = filesByComponent[name] || []
        for (let i = 0; i < list.length; ++i) {
            filesModel.append({ path: list[i] })
        }
    }

    function appendFile(path) {
        if (selectedComponent === '') return
        filesModel.append({ path: path })
        __syncBack()
    }

    function removeFile(index) {
        if (index < 0 || index >= filesModel.count) return
        filesModel.remove(index)
        __syncBack()
    }

    // Export the whole selected component (all its files). Mock backend
    // just logs — the real backend will write to disk.
    function exportComponent() {
        if (selectedComponent === '') return
        console.debug('ComponentsFiles.exportComponent:', selectedComponent,
                      JSON.stringify(filesByComponent[selectedComponent] || []))
    }

    // Persist the current file list for the selected component. Mock just
    // mirrors filesModel back into filesByComponent — already kept in sync,
    // so this is a no-op for the mock other than the debug print.
    function save() {
        if (selectedComponent === '') return
        __syncBack()
        console.debug('ComponentsFiles.save:', selectedComponent,
                      JSON.stringify(filesByComponent[selectedComponent]))
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
