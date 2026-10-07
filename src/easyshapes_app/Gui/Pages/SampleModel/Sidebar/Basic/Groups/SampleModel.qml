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

    EaComponents.ListView {
        id: loadedSampleModel
        defaultInfoText: qsTr("Get started by loading or importing a model")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 10,
            EaStyle.Sizes.fontPixelSize * 6,
            EaStyle.Sizes.fontPixelSize * 7,
            -1
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
            EaComponents.TableViewLabel {
                text: qsTr("Description")
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: Globals.BackendWrapper.sampleModelLoaded

        delegate: EaComponents.ListViewDelegate {
            required property var modelData
            required property int index

            EaComponents.ListViewTextInput {
                text: modelData ? modelData.name : ""
                onEditingFinished: Globals.BackendWrapper.sampleModelUpdateField("name", text)
            }
            EaComponents.TableViewComboBox {
                horizontalAlignment: Text.AlignHCenter
                model: Globals.BackendWrapper.sampleModelTypes
                Component.onCompleted: currentIndex = model.indexOf(modelData.type)
                onActivated: (i) => Globals.BackendWrapper.sampleModelUpdateField("type", model[i])
            }
            EaComponents.TableViewComboBox {
                horizontalAlignment: Text.AlignHCenter
                model: Globals.BackendWrapper.sampleModelStructureTypes
                Component.onCompleted: currentIndex = model.indexOf(modelData.structure_type)
                onActivated: (i) => Globals.BackendWrapper.sampleModelUpdateField("structure_type", model[i])
            }
            EaComponents.ListViewTextInput {
                text: modelData ? modelData.description : ""
                onEditingFinished: Globals.BackendWrapper.sampleModelUpdateField("description", text)
            }
        }
    }

    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

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

    Loader {
        id: loadExistingModelLoader
        source: "../Popups/LoadExistingModel.qml"
    }

    // Folder-based import: Qt's file dialogs can't accept a folder and a file at once.
    FolderDialog {
        id: importModelFolderDialog
        title: qsTr("Import a model from a directory")
        onAccepted: console.debug(`Import model from folder '${selectedFolder}'`)
    }
}
