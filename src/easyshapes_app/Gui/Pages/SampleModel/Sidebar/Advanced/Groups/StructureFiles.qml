// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals


EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    EaComponents.ListView {
        id: structureFilesList
        defaultInfoText: qsTr("No sample model files available")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 5,
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
        }

        model: Globals.BackendWrapper.structureFilesFiles

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
            }
            EaComponents.TableViewLabel {
                text: size
                enabled: false
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this file")
                onClicked: Globals.BackendWrapper.structureFilesRemove(index)
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
            onClicked: addSampleModelFilesDialog.open()
        }

        EaElements.SideBarButton {
            fontIcon: "save"
            text: qsTr("Save to lib")
            width: root.thirdWidth
            ToolTip.text: qsTr("Save the current sample model files to the asset library")
            enabled: Globals.BackendWrapper.structureFilesFiles
                     ? Globals.BackendWrapper.structureFilesFiles.count > 0
                     : false
            onClicked: Globals.BackendWrapper.structureFilesSaveToLib()
        }

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: root.thirdWidth
            ToolTip.text: qsTr("Export the current sample model files to disk")
            enabled: Globals.BackendWrapper.structureFilesFiles
                     ? Globals.BackendWrapper.structureFilesFiles.count > 0
                     : false
            onClicked: Globals.BackendWrapper.structureFilesExport()
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
            for (let i = 0; i < selectedFiles.length; ++i) {
                Globals.BackendWrapper.structureFilesAppendPath(selectedFiles[i].toString())
            }
        }
    }
}
