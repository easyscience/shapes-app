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

    EaComponents.ListView {
        id: loadedComponents

        defaultInfoText: qsTr("Load or create components")

        multiSelection: true

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 6,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
                horizontalAlignment: Text.AlignHCenter
            }
            EaComponents.TableViewLabel {
                text: qsTr("Name")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Type")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Atoms")
                color: EaStyle.Colors.themeForegroundMinor
                horizontalAlignment: Text.AlignHCenter
            }
            EaComponents.TableViewLabel {
                text: qsTr("Mint")
                color: EaStyle.Colors.themeForegroundMinor
                horizontalAlignment: Text.AlignHCenter
            }
            EaComponents.TableViewLabel {
                text: qsTr("Mext")
                color: EaStyle.Colors.themeForegroundMinor
                horizontalAlignment: Text.AlignHCenter
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: ListModel {
            id: loadedComponentsModel
        }

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string name
            required property string component_type
            required property int mint
            required property int mext
            required property int atoms

            EaComponents.TableViewLabel {
                text: index + 1
                horizontalAlignment: Text.AlignHCenter
                enabled: false
            }

            EaComponents.ListViewTextInput {
                id: modelNameColumn
                text: name
                onEditingFinished: name = text
            }

            EaComponents.TableViewLabel {
                text: component_type
                enabled: false
            }

            EaComponents.ListViewTextInput {
                text: atoms
                horizontalAlignment: Text.AlignHCenter
                onEditingFinished: atoms = parseInt(text)
                validator: IntValidator { bottom: 0 }
            }

            EaComponents.ListViewTextInput {
                text: mint
                horizontalAlignment: Text.AlignHCenter
                onEditingFinished: mint = parseInt(text)
                validator: IntValidator { bottom: 0 }
            }

            EaComponents.ListViewTextInput {
                text: mext
                horizontalAlignment: Text.AlignHCenter
                onEditingFinished: mext = parseInt(text)
                validator: IntValidator { bottom: 0 }
            }

            EaComponents.TableViewButton {
                id: deleteRowColumn
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this component")
                onClicked: loadedComponentsModel.remove(index)
            }
        }
    }

    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: 'upload'
            text: qsTr('Load component(s)')
            width: buttonWidth
            onClicked: loadExistingComponentLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: 'plus-circle'
            text: qsTr('Create component')
            width: buttonWidth
            onClicked: createNewComponentLoader.item.open()
        }

        EaElements.SideBarButton {
            id: saveModelButton
            fontIcon: 'download'
            text: qsTr('Save component(s)')
            width: buttonWidth
            enabled: loadedComponents.model ? loadedComponents.model.count > 0 : false
            onClicked: {
                const indexes = loadedComponents.selectedIndexes
                for (let i = 0; i < indexes.length; ++i)
                    loadExistingComponentLoader.item.availableComponentsModel.append(
                        loadedComponentsModel.get(indexes[i].row)
                    )
            }
        }
    }

    Loader {
        id: loadExistingComponentLoader
        source: '../Popups/LoadExistingComponent.qml'
        onLoaded: item.targetModel = loadedComponentsModel
    }

    Loader {
        id: createNewComponentLoader
        source: '../Popups/CreateNewComponent.qml'
        onLoaded: item.targetModel = loadedComponentsModel
    }

}
