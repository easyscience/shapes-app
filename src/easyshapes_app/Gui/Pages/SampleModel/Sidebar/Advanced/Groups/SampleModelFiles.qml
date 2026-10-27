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


EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    // No shape before Continue: Python holds no sample model yet
    readonly property bool hasModel: Globals.BackendWrapper.sampleModelShape !== ""

    EaComponents.ListView {
        id: sampleModelFilesList
        defaultInfoText: qsTr("No sample model files available")
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

        model: Globals.BackendWrapper.sampleModelFiles

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
                onClicked: Globals.BackendWrapper.sampleModelEditFile(index)
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this file")
                onClicked: Globals.BackendWrapper.sampleModelRemoveFile(index)
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
            ToolTip.text: qsTr("Pick one or more files from disk and add them to the sample model")
            enabled: root.hasModel
            onClicked: addSampleModelFilesDialog.open()
        }

        EaElements.SideBarButton {
            fontIcon: "save"
            text: qsTr("Save to lib")
            width: root.thirdWidth
            ToolTip.text: qsTr("Save this sample model, with its components and buffer, to the asset library")
            enabled: root.hasModel
            // A name the library holds asks first
            onClicked: {
                if (Globals.BackendWrapper.sampleModelNameTaken())
                    saveOverwriteDialog.open()
                else
                    Globals.BackendWrapper.sampleModelSave(false)
            }
        }

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: root.thirdWidth
            ToolTip.text: qsTr("Export this sample model, with its components and buffer, to a folder")
            enabled: root.hasModel
            onClicked: exportDestinationDialog.open()
        }
    }

    // A folder that is not empty asks first
    FolderDialog {
        id: exportDestinationDialog
        title: qsTr("Choose a destination directory")
        onAccepted: {
            const folder = EaLogic.Utils.urlToLocalFile(selectedFolder.toString())
            if (Globals.BackendWrapper.sampleModelExportTaken(folder)) {
                exportOverwriteDialog.folder = folder
                exportOverwriteDialog.open()
            } else {
                Globals.BackendWrapper.sampleModelExportTo(folder, false)
            }
        }
    }

    FileDialog {
        id: addSampleModelFilesDialog
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            "Any (*)",
            "Structure files (*.gro *.pdb *.xyz)",
            "Topology files (*.itp *.top)",
            "Data files (*.dat)"
        ]
        onAccepted: {
            for (let i = 0; i < selectedFiles.length; ++i)
                Globals.BackendWrapper.sampleModelAppendFile(EaLogic.Utils.urlToLocalFile(selectedFiles[i].toString()))
        }
    }

    // Asks before replacing the library's entry of this model's name
    EaElements.Dialog {
        id: saveOverwriteDialog
        title: qsTr("Replace library asset")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Globals.BackendWrapper.sampleModelSave(true)
        onRejected: console.debug(`Save of ${Globals.BackendWrapper.sampleModelName} cancelled: the name is taken`)

        // In a Column: a bare item under a titled dialog loops its
        // implicitWidth
        Column {
            EaElements.Label {
                text: qsTr("The library already holds a sample model named %1. Replace it?")
                      .arg(Globals.BackendWrapper.sampleModelName)
            }
        }
    }

    // Asks before an export replaces files; the folder dialog sets folder
    EaElements.Dialog {
        id: exportOverwriteDialog
        property string folder: ""
        title: qsTr("Replace exported files")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Globals.BackendWrapper.sampleModelExportTo(folder, true)
        onRejected: console.debug(`Export to ${folder} cancelled: the folder is taken`)

        Column {
            EaElements.Label {
                text: qsTr("%1 is not empty. Export there anyway? Files of an earlier export of this sample model are replaced.")
                      .arg(exportOverwriteDialog.folder)
            }
        }
    }
}
