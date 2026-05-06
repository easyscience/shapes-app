// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


EaElements.Dialog{
    id: componentCreationDialog

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    title: qsTr("Create a new Component")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        Globals.BackendWrapper.componentsAppend({
            name: componentNameField.text,
            component_type: sampleModelTypeField.currentText,
            atoms: 42,
            mint: 0,
            mext: 0
        })
    }

    Column {
        spacing: EaStyle.Sizes.fontPixelSize

        Row {
            property int halfFieldWidth: (componentCreationDialog.inputFieldWidth - spacing) / 2
            spacing: EaStyle.Sizes.fontPixelSize

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
                    model: [qsTr("Other"), qsTr("Lipid"), qsTr("Surfactant")]
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
                scrollBarInteractive: false

                columnWidths: [
                    -1,
                    EaStyle.Sizes.tableRowHeight
                ]

                model: Globals.BackendWrapper.componentsPendingFilePaths

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
                        onClicked: Globals.BackendWrapper.componentsRemovePendingFilePath(index)
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
                }
            }
        }
    }
}

