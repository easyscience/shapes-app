// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals


// The files of one asset of the equilibration, as Sample Model Files:
// its name, its files with the pencil, Add new file(s), Save to lib and
// Export. ConfigurationFiles.qml and ForceFieldFiles.qml fill in the
// asset's wrapper fields and calls. Off while a run goes on: a later
// stage reads its .mdp file only when it starts.
EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    // The asset in the dialogs' text, such as "configuration"
    property string kind: ""
    property string name: ""
    property var files: null
    // The Add dialog's filters
    property var nameFilters: []
    // The asset's wrapper calls
    property var setName: null
    property var appendFile: null
    property var removeFile: null
    property var editFile: null
    property var nameTaken: null
    property var save: null
    property var exportTaken: null
    property var exportTo: null

    enabled: !Globals.BackendWrapper.equilibrationFilesLocked

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Name")
        }
        // Save to lib under a new name keeps the library's entry as it is
        EaElements.TextField {
            id: nameField
            width: EaStyle.Sizes.sideBarContentWidth
            horizontalAlignment: TextInput.AlignLeft
            text: root.name
            onEditingFinished: {
                try { root.setName(text) }
                // A refused name leaves the typed text: read the held one back
                finally { text = Qt.binding(() => root.name) }
            }
        }
    }

    EaComponents.ListView {
        defaultInfoText: qsTr("No files in this %1").arg(root.kind)
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.tableRowHeight,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("File")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Size")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: root.files

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string path
            required property string size

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {
                text: path
                elide: Text.ElideLeft
                ToolTip.text: path
            }
            EaComponents.TableViewLabel {
                text: size
                enabled: false
            }
            EaComponents.TableViewButton {
                fontIcon: "edit"
                ToolTip.text: qsTr("Edit this file")
                onClicked: root.editFile(index)
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this file")
                onClicked: root.removeFile(index)
            }
        }
    }

    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Add new file(s)")
            width: root.thirdWidth
            ToolTip.text: qsTr("Pick one or more files from disk and add them to this %1").arg(root.kind)
            onClicked: addFilesDialog.open()
        }

        EaElements.SideBarButton {
            fontIcon: "save"
            text: qsTr("Save to lib")
            width: root.thirdWidth
            ToolTip.text: qsTr("Save this %1 to the asset library").arg(root.kind)
            // A name the library holds asks first
            onClicked: {
                if (root.nameTaken())
                    saveOverwriteDialog.open()
                else
                    root.save(false)
            }
        }

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: root.thirdWidth
            ToolTip.text: qsTr("Export this %1 to a folder").arg(root.kind)
            onClicked: exportDestinationDialog.open()
        }
    }

    FileDialog {
        id: addFilesDialog
        fileMode: FileDialog.OpenFiles
        nameFilters: root.nameFilters
        onAccepted: {
            for (let i = 0; i < selectedFiles.length; ++i)
                root.appendFile(EaLogic.Utils.urlToLocalFile(selectedFiles[i].toString()))
        }
    }

    // A folder that is not empty asks first
    FolderDialog {
        id: exportDestinationDialog
        title: qsTr("Choose a destination directory")
        onAccepted: {
            const folder = EaLogic.Utils.urlToLocalFile(selectedFolder.toString())
            if (root.exportTaken(folder)) {
                exportOverwriteDialog.folder = folder
                exportOverwriteDialog.open()
            } else {
                root.exportTo(folder, false)
            }
        }
    }

    // Asks before replacing the library's entry of this asset's name
    EaElements.Dialog {
        id: saveOverwriteDialog
        title: qsTr("Replace library asset")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: root.save(true)
        onRejected: console.debug(`Save of ${root.name} cancelled: the name is taken`)

        // In a Column: a bare item under a titled dialog loops its
        // implicitWidth
        Column {
            EaElements.Label {
                text: qsTr("The library already holds a %1 named %2. Replace it?")
                      .arg(root.kind).arg(root.name)
            }
        }
    }

    // Asks before an export replaces files; the folder dialog sets folder
    EaElements.Dialog {
        id: exportOverwriteDialog
        property string folder: ""
        title: qsTr("Replace exported files")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: root.exportTo(folder, true)
        onRejected: console.debug(`Export to ${folder} cancelled: the folder is taken`)

        Column {
            EaElements.Label {
                text: qsTr("%1 is not empty. Export there anyway? Files of an earlier export of this %2 are replaced.")
                      .arg(exportOverwriteDialog.folder).arg(root.kind)
            }
        }
    }
}
