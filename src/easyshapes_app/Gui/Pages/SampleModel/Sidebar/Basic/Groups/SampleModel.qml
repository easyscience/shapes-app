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
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164

    EaComponents.TableView {
        id: loadedSampleModelTableView
        clip: true
        // anchors.fill: parent

        defaultInfoText: qsTr("No models defined")
        header: EaComponents.TableViewHeader {
            EaComponents.TableViewLabel {
                id: modelNameColumnName
                width: EaStyle.Sizes.fontPixelSize * 8
                text: qsTr("Name")
                color: EaStyle.Colors.themeForegroundMinor
            }

            EaComponents.TableViewLabel {
                id: modelTypeColumnName
                width: EaStyle.Sizes.fontPixelSize * 6
                text: qsTr("Type")
                color: EaStyle.Colors.themeForegroundMinor
            }

            EaComponents.TableViewLabel {
                id: modelDescrColumnName
                width: EaStyle.Sizes.fontPixelSize * 24
                text: qsTr("Description")
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: ListModel {
            id: loadedSambleModelsModel
        }

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.TableViewDelegate {
            required property int index
            required property string name
            required property string structure_type
            required property string description

            EaComponents.TableViewTextInput {
                id: modelNameColumn
                width: EaStyle.Sizes.fontPixelSize * 12
                text: name
                onEditingFinished: name = text
                leftPadding: EaStyle.Sizes.fontPixelSize * 0.7
            }

            EaComponents.TableViewComboBox{
                id: structureTypeColumn
                width: EaStyle.Sizes.fontPixelSize * 6
                model: ["Ring", "Ball", "Vesicle", "Rod", "Bilayer", "Monolayer", "Lattice"]

                Component.onCompleted: {
                    currentIndex = model.indexOf(structure_type)
                }

                onActivated: (index) => {
                    structure_type = model[index]
                }
            }

            EaComponents.TableViewTextInput {
                id: descrColumn
                width: EaStyle.Sizes.fontPixelSize * 20
                text: description
                onEditingFinished: {
                    description = text
                    console.log("descrColumn onEditingFinished")
                }
                onAccepted: {
                    console.log("descrColumn onAccepted")
                }
            }
        }
    }

    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize


        // button 1
        EaElements.SideBarButton {
            fontIcon: 'upload'
            text: qsTr('Load an existing model')
            width: buttonWidth

            onClicked: {
                console.debug(`Clicking '${text}' button ::: ${this}`)
                Globals.References.pages.samplemodel.sidebar.basic.popups.LoadExistingModel.open()
            }

            Loader {
                source: '../Popups/LoadExistingModel.qml'
                onLoaded: {
                    item.targetModel = loadedSambleModelsModel
                    Globals.References.pages.samplemodel.sidebar.basic.popups.LoadExistingModel = item
                }
            }
        }
        // button 1


        // button 2
        EaElements.SideBarButton {
            fontIcon: 'plus-circle'
            text: qsTr('Create a new model')
            width: buttonWidth

            onClicked: {
                console.debug(`Clicking '${text}' button ::: ${this}`)
                Globals.References.pages.samplemodel.sidebar.basic.popups.CreateNewModel.open()
            }

            Loader {
                source: '../Popups/CreateNewModel.qml'
                onLoaded: {
                    item.targetModel = loadedSambleModelsModel
                    Globals.References.pages.samplemodel.sidebar.basic.popups.CreateNewModel = item
                }
            }
        }
        // button 2

        // button 3
        EaElements.SideBarButton {
            id: saveModelButton
            fontIcon: 'download'
            text: qsTr('Save the model')
            width: buttonWidth
            enabled: loadedSampleModelTableView.model ? loadedSampleModelTableView.model.count > 0 : false

            onClicked: {
                console.debug(`Clicking '${text}' button ::: ${this}`)
                Globals.References.pages.samplemodel.sidebar.basic.popups.LoadExistingModel.availableModelsModel.append(loadedSambleModelsModel.get(0))
            }
        }
        // button 3
    }

}
