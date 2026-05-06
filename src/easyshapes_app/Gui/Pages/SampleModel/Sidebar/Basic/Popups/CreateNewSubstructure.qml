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
    id: substructureCreationDialog

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    title: qsTr("Create a new Substructure")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        Globals.BackendWrapper.latticeSubstructureSetLoaded({
            name: substructureNameField.text,
            structure_type: substructureTypeField.currentText,
            description: substructureDescrField.text,
            file_path: substructureFileField.text
        })
    }

    Column {
        spacing: EaStyle.Sizes.fontPixelSize

        Row {
            id: nameTypeRow
            spacing: EaStyle.Sizes.fontPixelSize

            Column {
                EaElements.Label {
                    enabled: false
                    text: qsTr("Name")
                }
                EaElements.TextField {
                    id: substructureNameField
                    implicitWidth: (substructureCreationDialog.inputFieldWidth - nameTypeRow.spacing) / 2
                    horizontalAlignment: TextInput.AlignLeft
                    validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.]{1,30}$/ }
                    placeholderText: qsTr("(optional) Enter Substructure name here")
                }
            }

            Column {
                EaElements.Label {
                    enabled: false
                    text: qsTr("Structure type")
                }
                EaElements.ComboBox {
                    id: substructureTypeField
                    implicitWidth: (substructureCreationDialog.inputFieldWidth - nameTypeRow.spacing) / 2
                    model: Globals.BackendWrapper.latticeSubstructureTypes
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Description")
            }
            EaElements.TextField {
                id: substructureDescrField
                implicitWidth: substructureCreationDialog.inputFieldWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.]{1,30}$/ }
                placeholderText: qsTr("(optional) Enter Substructure description here")
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("File")
            }

            Row {
                id: fileRow
                spacing: EaStyle.Sizes.fontPixelSize

                EaElements.TextField {
                    id: substructureFileField
                    implicitWidth: substructureCreationDialog.inputFieldWidth
                                   - browseFileButton.width
                                   - fileRow.spacing
                    horizontalAlignment: TextInput.AlignLeft
                    placeholderText: qsTr("(optional) Choose a single structure file")
                    readOnly: true
                }

                EaElements.SideBarButton {
                    id: browseFileButton
                    fontIcon: 'upload'
                    text: qsTr('Browse…')
                    width: substructureCreationDialog.inputFieldWidth * 0.2
                    onClicked: substructureFilePicker.open()
                }
            }

            FileDialog {
                id: substructureFilePicker
                fileMode: FileDialog.OpenFile
                nameFilters: ['Any (*)', 'Structure files (*.gro *.pdb *.xyz)', 'Topology files (*.itp)']
                onAccepted: substructureFileField.text = selectedFile
            }
        }
    }
}
