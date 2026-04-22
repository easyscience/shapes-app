// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Elements as EaElements

import Gui.Globals as Globals


EaElements.Dialog{
    id: componentCreationDialog

    property var targetModel

    title: qsTr("Create a new Component")

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        console.log("Ok Clicked")

        targetModel.append({
            name: componentNameField.text,
            component_type: sampleModelTypeField.currentText,
            atoms: 42,
            mint: 0,
            mext: 0
        })
    }
    onRejected: console.log("Cancel Clicked")
    onOpened: console.log("Opened CreateNewComponent Clicked")

    Component.onCompleted: {
        Globals.References.pages.samplemodel.sidebar.basic.popups.CreateNewComponent = this
    }

    Column {

        spacing: EaStyle.Sizes.fontPixelSize

        Row {
            spacing: EaStyle.Sizes.fontPixelSize

            property int halfFieldWidth: (componentCreationDialog.inputFieldWidth - spacing) / 2

            Column {
                EaElements.Label {
                    enabled: false
                    text: qsTr("Name")
                }

                EaElements.TextField {
                    id: componentNameField

                    implicitWidth: parent.parent.halfFieldWidth
                    horizontalAlignment: TextInput.AlignLeft
                    validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.]{1,30}$/ }
                    placeholderText: qsTr("(optional) Enter Component name here")
                }
            }

            Column {
                EaElements.Label {
                    enabled: false
                    text: qsTr("Component type")
                }

                EaElements.ComboBox {
                    id: sampleModelTypeField
                    implicitWidth: parent.parent.halfFieldWidth
                    model: ["Other", "Lipid", "Surfactant"]
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("SMILES string")
            }

            EaElements.TextField {
                implicitWidth: componentCreationDialog.inputFieldWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("(optional) Define component using SMILES")
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Paths")
            }

            EaComponents.ListView {
                id: filePaths
                defaultInfoText: qsTr("No files added")
                enabled: true
                maxRowCountShow: 2
                width: componentCreationDialog.inputFieldWidth

                columnWidths: [
                    -1,
                    EaStyle.Sizes.tableRowHeight
                ]

                scrollBarInteractive: false

                model: ListModel {
                    id: selectedFilePathsModel
                }

                delegate: EaComponents.ListViewDelegate {
                    required property int index
                    required property url path

                    EaComponents.TableViewLabel {
                        id: pathColumn
                        text: path
                        elide: Text.ElideLeft
                        horizontalAlignment: Text.Alignleft

                        leftPadding: EaStyle.Sizes.fontPixelSize * 0.5
                    }

                    EaComponents.TableViewButton {
                        id: deleteRowColumn
                        fontIcon: "minus-circle"
                        ToolTip.text: qsTr("Remove this file")
                        onClicked: selectedFilePathsModel.remove(index)
                    }
                }
            }
        }
        Column {
            EaElements.SideBarButton {
                fontIcon: 'upload'
                text: qsTr('Add files')
                width: componentCreationDialog.width * 0.3164

                onClicked: {
                    console.debug(`Clicking '${text}' button ::: ${this}`)
                    Globals.References.pages.samplemodel.sidebar.basic.popups.openAssetFile.open()
                }

                Loader {
                    source: '../Popups/OpenAssetFile.qml'
                    onLoaded: {
                        item.targetModel = selectedFilePathsModel
                    }
                }
            }
        }
    }
}

