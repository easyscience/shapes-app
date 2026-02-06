// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Elements as EaElements
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Logic as EaLogic

import Gui.Globals as Globals

EaElements.GroupColumn {

    EaElements.ComboBox {
         model: ["EaElements.ComboBox 1", "EaElements.ComboBox 2", "EaElements.ComboBox 3"]
    }

    Column {
        EaElements.RadioButton {
            checked: true
            text: qsTr("EaElements.RadioButton 1")
        }
        EaElements.RadioButton {
            text: qsTr("EaElements.RadioButton 2")
        }
    }

    Column {
        spacing: 10
        EaElements.CheckBox {
            checked: true
            text: qsTr("EaElements.CheckBox 1")
        }
        EaElements.CheckBox {
            text: qsTr("EaElements.CheckBox 2")
        }
    }

}
