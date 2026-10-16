// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtCore

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals


FolderDialog {

    id: openProjectDialog

    title: qsTr('Open project folder')

    // selectedFolder is a url object; urlToLocalFile needs a string
    onAccepted: Globals.BackendWrapper.projectLoad(EaLogic.Utils.urlToLocalFile(selectedFolder.toString()))

    // Starts in the Create dialog's stored folder. It is read at each open,
    // because Create may have changed it since the app started.
    function openInLastParentFolder() {
        currentFolder = projectLocation.value('projectParentDirectory', '')
        open()
    }

    Settings {
        id: projectLocation
        location: EaGlobals.Vars.settingsFile
        category: 'Project.Location'
    }

    Component.onCompleted: {
        Globals.References.pages.project.sidebar.basic.popups.openProject = openProjectDialog
    }

}
