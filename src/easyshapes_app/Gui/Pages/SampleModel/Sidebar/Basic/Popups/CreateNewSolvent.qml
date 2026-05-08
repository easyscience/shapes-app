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


EaElements.Dialog {
    id: solventCreationDialog

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    title: qsTr("Import a new Solvent")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        Globals.BackendWrapper.solventSetLoaded({
            name: solventNameField.text,
            solvent_type: solventTypeField.currentText,
            description: solventDescrField.text,
            file_path: solventFileField.text
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
                    id: solventNameField
                    implicitWidth: (solventCreationDialog.inputFieldWidth - nameTypeRow.spacing) / 2
                    horizontalAlignment: TextInput.AlignLeft
                    validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.\/]{1,30}$/ }
                    placeholderText: qsTr("(optional) Enter Solvent name here")
                }
            }

            Column {
                EaElements.Label {
                    enabled: false
                    text: qsTr("Solvent type")
                }
                EaElements.ComboBox {
                    id: solventTypeField
                    implicitWidth: (solventCreationDialog.inputFieldWidth - nameTypeRow.spacing) / 2
                    model: Globals.BackendWrapper.solventTypes
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Description")
            }
            EaElements.TextField {
                id: solventDescrField
                implicitWidth: solventCreationDialog.inputFieldWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("(optional) Enter Solvent description here")
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
                    id: solventFileField
                    implicitWidth: solventCreationDialog.inputFieldWidth
                                   - browseFileButton.width
                                   - fileRow.spacing
                    horizontalAlignment: TextInput.AlignLeft
                    placeholderText: qsTr("(optional) Choose a single solvent file")
                    readOnly: true
                }

                EaElements.SideBarButton {
                    id: browseFileButton
                    fontIcon: 'upload'
                    text: qsTr('Browse…')
                    width: solventCreationDialog.inputFieldWidth * 0.2
                    onClicked: solventFilePicker.open()
                }
            }

            FileDialog {
                id: solventFilePicker
                fileMode: FileDialog.OpenFile
                nameFilters: ['Any (*)', 'Structure files (*.gro *.pdb *.xyz)', 'Topology files (*.itp)']
                onAccepted: solventFileField.text = selectedFile
            }
        }
    }
}
