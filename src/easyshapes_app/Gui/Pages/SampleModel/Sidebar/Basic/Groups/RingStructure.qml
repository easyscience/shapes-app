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
            text: Globals.BackendWrapper.ringStructureDmin
            onEditingFinished: Globals.BackendWrapper.ringStructureSetDmin(parseFloat(text))
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Rmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.25 }
            text: Globals.BackendWrapper.ringStructureRmin
            onEditingFinished: Globals.BackendWrapper.ringStructureSetRmin(parseFloat(text))
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Alpha")
            units: "⚬"
            validator: DoubleValidator { bottom: 0; top: 360 }
            text: Globals.BackendWrapper.ringStructureAlpha
            onEditingFinished: Globals.BackendWrapper.ringStructureSetAlpha(parseFloat(text))
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Theta")
            units: "⚬"
            validator: DoubleValidator { bottom: 0; top: 180 }
            text: Globals.BackendWrapper.ringStructureTheta
            onEditingFinished: Globals.BackendWrapper.ringStructureSetTheta(parseFloat(text))
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Fxz")
            checked: Globals.BackendWrapper.ringStructureFxz
            onToggled: Globals.BackendWrapper.ringStructureSetFxz(checked)
        }
        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Rev")
            checked: Globals.BackendWrapper.ringStructureRev
            onToggled: Globals.BackendWrapper.ringStructureSetRev(checked)
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
