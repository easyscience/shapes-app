// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals

import "../Components" as Local

EaElements.GroupColumn {

    Row {
        property real itemWidth: EaStyle.Sizes.sideBarContentWidth * 0.27
        spacing: (EaStyle.Sizes.sideBarContentWidth - (itemWidth * 3)) / 2

        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr("Dmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.5 }
            text: Globals.BackendWrapper.rodStructure.dmin
            onEditingFinished: Globals.BackendWrapper.rodStructure.dmin = parseFloat(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr("Rmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.25 }
            text: Globals.BackendWrapper.rodStructure.rmin
            onEditingFinished: Globals.BackendWrapper.rodStructure.rmin = parseFloat(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr("Turns")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.rodStructure.turns
            onEditingFinished: Globals.BackendWrapper.rodStructure.turns = parseInt(text)
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Fxz")
            checked: Globals.BackendWrapper.rodStructure.fxz
            onToggled: Globals.BackendWrapper.rodStructure.fxz = checked
        }
        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Rev")
            checked: Globals.BackendWrapper.rodStructure.rev
            onToggled: Globals.BackendWrapper.rodStructure.rev = checked
        }
    }

    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("Rod Fractions")
        }
        Local.Fractions {}
    }
}
