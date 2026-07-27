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
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2

    // The step directories only exist once equilibration has run; before that
    // the dropdown and the file list are empty.
    readonly property bool hasSteps: Globals.BackendWrapper.equilOutputsSteps
                                     ? Globals.BackendWrapper.equilOutputsSteps.count > 0
                                     : false

    // Row of the file picked in the list, -1 when nothing is selected. Drives
    // whether Export writes one file or the whole step directory.
    readonly property int selectedFileRow: stepFilesList.selectedIndexes.length > 0
                                           ? stepFilesList.selectedIndexes[0].row
                                           : -1

    // Step selector on the left, resolved directory path on the right.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Step")
            }
            EaElements.ComboBox {
                id: stepSelector
                width: root.halfWidth
                textRole: "name"
                model: Globals.BackendWrapper.equilOutputsSteps
                enabled: root.hasSteps
                displayText: currentIndex < 0 ? "" : currentText

                onActivated: (i) => Globals.BackendWrapper.equilOutputsSelect(i)

                // Mirror the dropdown index from the backend's selected step so
                // regenerating the outputs resets the label too.
                function syncIndex() {
                    currentIndex = Globals.BackendWrapper.equilOutputsSelectedIndex
                }

                Component.onCompleted: syncIndex()
                Connections {
                    target: Globals.BackendWrapper.equilOutputsSteps
                    function onCountChanged() { stepSelector.syncIndex() }
                }
                Connections {
                    target: Globals.BackendWrapper
                    function onEquilOutputsSelectedIndexChanged() { stepSelector.syncIndex() }
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Directory")
            }
            EaElements.Label {
                width: root.halfWidth
                height: EaStyle.Sizes.tableRowHeight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideLeft
                text: Globals.BackendWrapper.equilOutputsSelectedDir
            }
        }
    }

    EaComponents.ListView {
        id: stepFilesList
        defaultInfoText: qsTr("No equilibration outputs — run Equilibrate first")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 5
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
        }

        model: Globals.BackendWrapper.equilOutputsFiles

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string name
            required property string size

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {
                text: name
                elide: Text.ElideLeft
            }
            EaComponents.TableViewLabel {
                text: size
                enabled: false
            }
        }
    }

    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: root.halfWidth
            ToolTip.text: qsTr("Export the selected file to disk, or the whole step directory when no file is selected")
            enabled: Globals.BackendWrapper.equilOutputsSelectedDir !== ""
            onClicked: exportDestinationDialog.open()
        }

        EaElements.SideBarButton {
            fontIcon: "folder-open"
            text: qsTr("Open directory")
            width: root.halfWidth
            ToolTip.text: qsTr("Open the selected step directory in the system file browser")
            enabled: Globals.BackendWrapper.equilOutputsSelectedDir !== ""
            onClicked: Globals.BackendWrapper.equilOutputsOpenDir()
        }
    }

    // Destination picker for Export. What gets written is decided here rather
    // than on the button, so the selection is read when the user confirms.
    FolderDialog {
        id: exportDestinationDialog
        title: qsTr("Choose a destination directory")
        onAccepted: {
            const destination = selectedFolder.toString()
            if (root.selectedFileRow >= 0)
                Globals.BackendWrapper.equilOutputsExportFile(root.selectedFileRow, destination)
            else
                Globals.BackendWrapper.equilOutputsExportStep(destination)
        }
    }
}
