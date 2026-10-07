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
    id: root
    property double quarterWidth: (EaStyle.Sizes.sideBarContentWidth - 3 * EaStyle.Sizes.fontPixelSize) / 4

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Dmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.5 }
            text: Globals.BackendWrapper.ringStructure.dmin
            onEditingFinished: Globals.BackendWrapper.ringStructure.dmin = parseFloat(text)
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Rmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.25 }
            text: Globals.BackendWrapper.ringStructure.rmin
            onEditingFinished: Globals.BackendWrapper.ringStructure.rmin = parseFloat(text)
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Alpha")
            units: "⚬"
            validator: DoubleValidator { bottom: 0; top: 360 }
            text: Globals.BackendWrapper.ringStructure.alpha
            onEditingFinished: Globals.BackendWrapper.ringStructure.alpha = parseFloat(text)
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Theta")
            units: "⚬"
            validator: DoubleValidator { bottom: 0; top: 180 }
            text: Globals.BackendWrapper.ringStructure.theta
            onEditingFinished: Globals.BackendWrapper.ringStructure.theta = parseFloat(text)
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Fxz")
            checked: Globals.BackendWrapper.ringStructure.fxz
            onToggled: Globals.BackendWrapper.ringStructure.fxz = checked
        }
        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Rev")
            checked: Globals.BackendWrapper.ringStructure.rev
            onToggled: Globals.BackendWrapper.ringStructure.rev = checked
        }
    }

    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("Ring Fractions")
        }
        Local.Fractions {}
    }
}
