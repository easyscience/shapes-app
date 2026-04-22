// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Components as EaComponents

import Gui.Globals as Globals


FileDialog{
    fileMode: FileDialog.OpenFiles
    nameFilters: ['Any (*)', 'Structure files (*.gro *.pdb .*xyz)', 'Topology files (*.itp)', 'Smiles files (*.sml)']

    property var targetModel

    onAccepted: {
        for (let i = 0; i < selectedFiles.length; ++i)
            targetModel.append({ path: selectedFiles[i] })
    }

    Component.onCompleted: {
        Globals.References.pages.samplemodel.sidebar.basic.popups.openAssetFile = this
    }

}
