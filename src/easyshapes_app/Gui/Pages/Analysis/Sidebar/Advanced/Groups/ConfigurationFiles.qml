// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import Gui.Globals as Globals


// The equilibration configuration's .mdp files. Only equil<k>.mdp runs,
// as stage k
AssetFilesGroup {
    kind: qsTr("configuration")
    name: Globals.BackendWrapper.configurationName
    files: Globals.BackendWrapper.configurationFiles
    nameFilters: [qsTr("GROMACS run parameter files (*.mdp)"), qsTr("Any (*)")]

    setName: (value) => Globals.BackendWrapper.configurationSetName(value)
    appendFile: (path) => Globals.BackendWrapper.configurationAppendFile(path)
    removeFile: (index) => Globals.BackendWrapper.configurationRemoveFile(index)
    editFile: (index) => Globals.BackendWrapper.configurationEditFile(index)
    nameTaken: () => Globals.BackendWrapper.configurationNameTaken()
    save: (overwrite) => Globals.BackendWrapper.configurationSave(overwrite)
    exportTaken: (folder) => Globals.BackendWrapper.configurationExportTaken(folder)
    exportTo: (folder, overwrite) => Globals.BackendWrapper.configurationExportTo(folder, overwrite)
}
