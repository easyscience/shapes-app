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
    id: sampleModelCreationDialog

    property var targetModel
    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    title: qsTr("Create a new Sample Model")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        targetModel.clear()
        targetModel.append(
            {
                name: sampleModelNameField.text,
                structure_type: sampleModelTypeField.currentText,
                description: sampleModelDescrField.text
            }
        )
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
                    id: sampleModelNameField
                    implicitWidth: (sampleModelCreationDialog.inputFieldWidth - nameTypeRow.spacing) / 2
                    horizontalAlignment: TextInput.AlignLeft
                    validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.]{1,30}$/ }
                    placeholderText: qsTr("(optional) Enter Sample Model name here")
                }
            }

            Column {
                EaElements.Label {
                    enabled: false
                    text: qsTr("Structure type")
                }
                EaElements.ComboBox {
                    id: sampleModelTypeField
                    implicitWidth: (sampleModelCreationDialog.inputFieldWidth - nameTypeRow.spacing) / 2
                    model: [qsTr("Ring"), qsTr("Ball"), qsTr("Vesicle"), qsTr("Rod"), qsTr("Bilayer"), qsTr("Monolayer"), qsTr("Lattice")]
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Description")
            }
            EaElements.TextField {
                id: sampleModelDescrField
                implicitWidth: sampleModelCreationDialog.inputFieldWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.]{1,30}$/ }
                placeholderText: qsTr("(optional) Enter Sample Model description here")
            }
        }
    }
}

