// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

QtObject {

    // Working set of components currently loaded into the sample model.
    // ListModel (not JS array) so EaComponents.ListView's ItemSelectionModel
    // can drive Ctrl/Shift multi-selection, and so role-based delegate
    // properties (`required property string name` etc.) bind correctly.
    // Roles: name, component_type, atoms, mint, mext.
    readonly property var loaded: ListModel {
        id: loadedComponentsModel
    }

    // File paths staged while creating a new component.
    // Roles: path.
    readonly property var pendingFilePaths: ListModel {
        id: pendingFilePathsModel
    }

    function appendItem(item) {
        loadedComponentsModel.append({
            name: item.name,
            component_type: item.component_type,
            atoms: item.atoms,
            mint: item.mint,
            mext: item.mext
        })
    }

    function removeItem(index) {
        if (index < 0 || index >= loadedComponentsModel.count) return
        loadedComponentsModel.remove(index)
    }

    function clear() {
        loadedComponentsModel.clear()
    }

    function appendPendingFilePath(path) {
        pendingFilePathsModel.append({ path: path })
    }

    function removePendingFilePath(index) {
        if (index < 0 || index >= pendingFilePathsModel.count) return
        pendingFilePathsModel.remove(index)
    }

    function clearPendingFilePaths() {
        pendingFilePathsModel.clear()
    }

}
