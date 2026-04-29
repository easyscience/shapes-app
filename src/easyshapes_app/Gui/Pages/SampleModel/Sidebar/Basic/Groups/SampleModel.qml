// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
//import QtQuick.Dialogs

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Elements as EaElements
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Logic as EaLogic

import Gui.Globals as Globals

EaElements.GroupColumn {
    id: root
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164
    property string currentStructureType: ""

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

        model: ListModel {
            id: loadedSambleModelsModel
            onCountChanged: root.currentStructureType = count > 0 ? get(0).structure_type : ""
        }

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string name
            required property string structure_type
            required property string description

            EaComponents.ListViewTextInput {
                text: name
                onEditingFinished: name = text
            }
            EaComponents.TableViewComboBox{
                model: [qsTr("Ring"), qsTr("Ball"), qsTr("Vesicle"), qsTr("Rod"), qsTr("Bilayer"), qsTr("Monolayer"), qsTr("Lattice")]
                Component.onCompleted: {
                    currentIndex = model.indexOf(structure_type)
                }
                onActivated: (index) => {
                    structure_type = model[index]
                    root.currentStructureType = model[index]
                }
            }
            EaComponents.ListViewTextInput {
                text: description
                onEditingFinished: description = text
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
            enabled: loadedSampleModel.model && loadedSampleModel.model.count > 0 && loadedSambleModelsModel.get(0).name !== ""
            onClicked: loadExistingModelLoader.item.availableModelsModel.append(loadedSambleModelsModel.get(0))
        }
    }

    Loader {
        id: loadExistingModelLoader
        source: '../Popups/LoadExistingModel.qml'
        onLoaded: item.targetModel = loadedSambleModelsModel
    }

    Loader {
        id: createNewModelLoader
        source: '../Popups/CreateNewModel.qml'
        onLoaded: item.targetModel = loadedSambleModelsModel
    }

}
