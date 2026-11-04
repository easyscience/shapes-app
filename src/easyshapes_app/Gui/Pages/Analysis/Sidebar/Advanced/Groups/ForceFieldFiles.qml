// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import Gui.Globals as Globals


// The equilibration force field's files. Each run copies its first .itp
// to toppar/forcefield.itp
AssetFilesGroup {
    kind: qsTr("force field")
    name: Globals.BackendWrapper.forceFieldName
    files: Globals.BackendWrapper.forceFieldFiles
    nameFilters: [qsTr("Topology files (*.itp)"), qsTr("Any (*)")]

    setName: (value) => Globals.BackendWrapper.forceFieldSetName(value)
    appendFile: (path) => Globals.BackendWrapper.forceFieldAppendFile(path)
    removeFile: (index) => Globals.BackendWrapper.forceFieldRemoveFile(index)
    editFile: (index) => Globals.BackendWrapper.forceFieldEditFile(index)
    nameTaken: () => Globals.BackendWrapper.forceFieldNameTaken()
    save: (overwrite) => Globals.BackendWrapper.forceFieldSave(overwrite)
    exportTaken: (folder) => Globals.BackendWrapper.forceFieldExportTaken(folder)
    exportTo: (folder, overwrite) => Globals.BackendWrapper.forceFieldExportTo(folder, overwrite)
}
