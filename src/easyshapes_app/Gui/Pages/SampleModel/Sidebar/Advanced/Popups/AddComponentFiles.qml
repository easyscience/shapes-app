// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Dialogs

import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals


FileDialog {
    fileMode: FileDialog.OpenFiles
    nameFilters: [
        "Any (*)",
        "Structure files (*.gro *.pdb *.xyz)",
        "Topology files (*.itp)",
        "Smiles files (*.sml)"
    ]

    onAccepted: {
        for (let i = 0; i < selectedFiles.length; ++i) {
            Globals.BackendWrapper.componentsFilesAppend(EaLogic.Utils.urlToLocalFile(selectedFiles[i].toString()))
        }
    }
}
