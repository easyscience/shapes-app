// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals

EaElements.GroupColumn {

    Column {
        width: EaStyle.Sizes.sideBarContentWidth * 0.2

        EaElements.Label {
            enabled: false
            text: qsTr("Fill")
        }
        EaElements.ComboBox {
            width: parent.width
            model: ["FIBO", "RINGS", "RINGS0"]
            Component.onCompleted: currentIndex = model.indexOf(Globals.BackendWrapper.vesicleStructure.fill)
            onActivated: (i) => Globals.BackendWrapper.vesicleStructure.fill = model[i]
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Fxz")
            checked: Globals.BackendWrapper.vesicleStructure.fxz
            onToggled: Globals.BackendWrapper.vesicleStructure.fxz = checked
        }
        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Rev")
            checked: Globals.BackendWrapper.vesicleStructure.rev
            onToggled: Globals.BackendWrapper.vesicleStructure.rev = checked
        }
    }
}
