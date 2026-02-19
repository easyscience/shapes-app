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

    property alias sampleModelName: sampleModelNameField.text

    title: qsTr("Create a new Sample Model")

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    standardButtons: Dialog.Ok

    Column {
        spacing: EaStyle.Sizes.fontPixelSize
        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Name")
            }

            EaElements.TextField {
                id: sampleModelNameField

                implicitWidth: inputFieldWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.]{1,30}$/ }
                placeholderText: qsTr("Enter Sample Model name here")

                Keys.onReturnPressed: dialog.accept()
                Keys.onEnterPressed: dialog.accept()
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Name3")
            }

            EaElements.Label {
                text: qsTr("Name4")
            }
        }

    }

    Component.onCompleted: {
        Globals.References.pages.samplemodel.sidebar.basic.popups.CreateNewModel = this
    }



}
