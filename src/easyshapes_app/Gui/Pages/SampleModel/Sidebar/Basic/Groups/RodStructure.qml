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
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Dmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.5 }
            text: Globals.BackendWrapper.rodStructureDmin
            onEditingFinished: Globals.BackendWrapper.rodStructureSetDmin(parseFloat(text))
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Rmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.25 }
            text: Globals.BackendWrapper.rodStructureRmin
            onEditingFinished: Globals.BackendWrapper.rodStructureSetRmin(parseFloat(text))
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Turns")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.rodStructureTurns
            onEditingFinished: Globals.BackendWrapper.rodStructureSetTurns(parseInt(text))
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Fxz")
            checked: Globals.BackendWrapper.rodStructureFxz
            onToggled: Globals.BackendWrapper.rodStructureSetFxz(checked)
        }
        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Rev")
            checked: Globals.BackendWrapper.rodStructureRev
            onToggled: Globals.BackendWrapper.rodStructureSetRev(checked)
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
