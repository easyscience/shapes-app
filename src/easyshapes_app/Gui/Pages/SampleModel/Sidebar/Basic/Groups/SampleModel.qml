// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals

EaElements.GroupColumn {
    id: root
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2

    EaComponents.ListView {
        id: loadedSampleModel
        defaultInfoText: qsTr("Get started by loading or importing a model")
        multiSelection: false

        columnWidths: [
            -1,
            EaStyle.Sizes.fontPixelSize * 7,
            EaStyle.Sizes.fontPixelSize * 8
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("Name")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Type")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Shape")
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        // One row for the session's sample model; none before Continue.
        // The row edits through the wrapper's set functions until the
        // library holds several models (then a list model, ReadWrite).
        model: Globals.BackendWrapper.sampleModelShape ? 1 : 0

        delegate: EaComponents.ListViewDelegate {
            EaComponents.ListViewTextInput {
                // The library refuses a rename while an assembly writes
                // the files
                enabled: !Globals.BackendWrapper.sampleModelFilesLocked
                text: Globals.BackendWrapper.sampleModelName
                onEditingFinished: {
                    try { Globals.BackendWrapper.sampleModelSetName(text) }
                    // A refused name leaves the typed text: read the held one back
                    finally { text = Qt.binding(() => Globals.BackendWrapper.sampleModelName) }
                }
            }
            EaComponents.TableViewComboBox {
                horizontalAlignment: Text.AlignHCenter
                model: [qsTr("Discrete"), qsTr("Lattice")]
                currentIndex: Globals.BackendWrapper.sampleModelLattice ? 1 : 0
                onActivated: (i) => Globals.BackendWrapper.sampleModelSetLattice(i === 1)
            }
            EaComponents.TableViewComboBox {
                horizontalAlignment: Text.AlignHCenter
                model: Globals.BackendWrapper.sampleModelShapes
                currentIndex: model.indexOf(Globals.BackendWrapper.sampleModelShape)
                onActivated: (i) => Globals.BackendWrapper.sampleModelSetShape(model[i])
            }
        }
    }

    // Load and Import are off while a run goes on: another model would
    // replace the one the run writes for
    Item {
        width: loadImportButtons.width
        height: loadImportButtons.height

        Grid {
            id: loadImportButtons
            columns: 2
            spacing: EaStyle.Sizes.fontPixelSize
            enabled: !Globals.BackendWrapper.runLocked

            EaElements.SideBarButton {
                fontIcon: "file-import"
                text: qsTr("Load model")
                width: root.halfWidth
                onClicked: loadExistingModelLoader.item.open()
            }

            EaElements.SideBarButton {
                fontIcon: "upload"
                text: qsTr("Import model")
                width: root.halfWidth
                onClicked: importModelFolderDialog.open()
            }
        }

        // A disabled button gets no hover, so its own tooltip never
        // shows: this area over both says why they are off. No clicks
        MouseArea {
            anchors.fill: loadImportButtons
            visible: !loadImportButtons.enabled
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            EaElements.ToolTip {
                text: qsTr("Wait for the run to end, or cancel it")
                visible: parent.containsMouse && EaGlobals.Vars.showToolTips
            }
        }
    }

    Loader {
        id: loadExistingModelLoader
        source: "../Popups/LoadExistingModel.qml"
    }

    // Folder-based import: Qt's file dialogs can't accept a folder and a file at once.
    FolderDialog {
        id: importModelFolderDialog
        title: qsTr("Import a model from a directory")
        onAccepted: Globals.BackendWrapper.sampleModelImportFrom(EaLogic.Utils.urlToLocalFile(selectedFolder.toString()))
    }
}
