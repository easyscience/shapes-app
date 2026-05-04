// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals

EaElements.GroupColumn {
    id: root
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164

    Component.onCompleted: Globals.References.pages.samplemodel.sidebar.basic.groups.sampleModel = root

    EaComponents.ListView {
        id: loadedSampleModel
        defaultInfoText: qsTr("Get started by loading or creating a model")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 12,
            EaStyle.Sizes.fontPixelSize * 6,
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
                text: qsTr("Description")
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: Globals.BackendWrapper.sampleModelLoaded

        delegate: EaComponents.ListViewDelegate {
            required property var modelData
            required property int index

            EaComponents.ListViewTextInput {
                text: modelData ? modelData.name : ''
                onEditingFinished: Globals.BackendWrapper.sampleModelUpdateField('name', text)
            }
            EaComponents.TableViewComboBox {
                model: Globals.BackendWrapper.sampleModelStructureTypes
                Component.onCompleted: {
                    currentIndex = model.indexOf(modelData.structure_type)
                }
                onActivated: (i) => {
                    Globals.BackendWrapper.sampleModelUpdateField('structure_type', model[i])
                }
            }
            EaComponents.ListViewTextInput {
                text: modelData ? modelData.description : ''
                onEditingFinished: Globals.BackendWrapper.sampleModelUpdateField('description', text)
            }
        }
    }

    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "upload"
            text: qsTr("Load model")
            width: buttonWidth
            onClicked: loadExistingModelLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Create model")
            width: buttonWidth
            onClicked: createNewModelLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: "download"
            text: qsTr("Save model")
            width: buttonWidth
            enabled: Globals.BackendWrapper.sampleModelLoaded.length > 0
                  && Globals.BackendWrapper.sampleModelLoaded[0].name !== ""
            onClicked: Globals.BackendWrapper.sampleModelSaveToCatalog()
        }
    }

    Loader {
        id: loadExistingModelLoader
        source: '../Popups/LoadExistingModel.qml'
    }

    Loader {
        id: createNewModelLoader
        source: '../Popups/CreateNewModel.qml'
    }

}
