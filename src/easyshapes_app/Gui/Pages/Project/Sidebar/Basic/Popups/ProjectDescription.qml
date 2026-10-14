// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtCore

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals


// Create project: name, description and location, all optional. An empty location
// lets the library choose Projects/<name>-<uid>. The parent of the last location given
// opens the folder dialog next time; it never fills the location field.
EaElements.Dialog {
    id: dialog

    property string lastParentFolder: ''  // file URL, kept in the settings file
    readonly property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    visible: EaGlobals.Vars.showProjectDescriptionDialog
    title: qsTr('Create project')
    standardButtons: Dialog.Ok

    onAboutToShow: {
        nameField.text = ''
        descriptionField.text = ''
        locationField.text = ''
    }
    onClosed: EaGlobals.Vars.showProjectDescriptionDialog = false

    onAccepted: {
        Globals.BackendWrapper.projectCreate(nameField.text, descriptionField.text, locationField.text)
        // Reached only when create did not raise: an exception stops this handler
        if (locationField.text)
            lastParentFolder = Globals.BackendWrapper.projectPathParentUrl
    }

    Column {
        spacing: EaStyle.Sizes.fontPixelSize

        // Name
        Column {
            EaElements.Label {
                enabled: false
                text: qsTr('Name')
            }
            EaElements.TextField {
                id: nameField
                implicitWidth: dialog.inputFieldWidth
                horizontalAlignment: TextInput.AlignLeft
                // Empty, or a name safe for the default folder Projects/<name>-<uid>
                validator: RegularExpressionValidator { regularExpression: /^([a-zA-Z][a-zA-Z0-9_\-\.]{1,30})?$/ }
                placeholderText: qsTr('Optional')
                Keys.onReturnPressed: dialog.accept()
                Keys.onEnterPressed: dialog.accept()
            }
        }

        // Description
        Column {
            EaElements.Label {
                enabled: false
                text: qsTr('Description')
            }
            EaElements.TextField {
                id: descriptionField
                implicitWidth: dialog.inputFieldWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr('Optional')
                Keys.onReturnPressed: dialog.accept()
                Keys.onEnterPressed: dialog.accept()
            }
        }

        // Location
        Column {
            EaElements.Label {
                enabled: false
                text: qsTr('Location')
            }
            EaElements.TextField {
                id: locationField
                implicitWidth: dialog.inputFieldWidth
                rightPadding: chooseFolderButton.width
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr('Default location')
                Keys.onReturnPressed: dialog.accept()
                Keys.onEnterPressed: dialog.accept()

                EaElements.ToolButton {
                    id: chooseFolderButton
                    anchors.right: parent.right
                    fontIcon: 'folder-open'
                    showBackground: false
                    ToolTip.text: qsTr('Choose project folder')
                    onClicked: folderDialog.open()
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: qsTr('Choose project folder')
        currentFolder: dialog.lastParentFolder
        onAccepted: locationField.text = EaLogic.Utils.urlToLocalFile(selectedFolder)
    }

    // Same key as EasyApp's ProjectDescriptionDialog, so an earlier saved folder still works
    Settings {
        location: EaGlobals.Vars.settingsFile
        category: 'Project.Location'
        property alias projectParentDirectory: dialog.lastParentFolder
    }

}
