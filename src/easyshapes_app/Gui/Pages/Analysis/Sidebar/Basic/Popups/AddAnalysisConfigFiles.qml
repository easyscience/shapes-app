// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Dialogs

import Gui.Globals as Globals


FileDialog {
    fileMode: FileDialog.OpenFiles
    nameFilters: [
        "GROMACS run parameter files (*.mdp)",
        "Any (*)"
    ]

    onAccepted: {
        for (let i = 0; i < selectedFiles.length; ++i) {
            Globals.BackendWrapper.analysisConfigAppendPath(selectedFiles[i].toString())
        }
    }
}
