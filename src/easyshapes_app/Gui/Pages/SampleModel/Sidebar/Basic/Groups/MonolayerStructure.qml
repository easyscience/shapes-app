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
            title: qsTr("Zsep")
            units: "nm"
            validator: DoubleValidator { bottom: 0 }
            text: Globals.BackendWrapper.monolayerStructure.zsep
            onEditingFinished: Globals.BackendWrapper.monolayerStructure.zsep = parseFloat(text)
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Nside")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.monolayerStructure.nside
            onEditingFinished: Globals.BackendWrapper.monolayerStructure.nside = parseInt(text)
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Dmin")
            units: "nm"
            validator: DoubleValidator { bottom: 0.5 }
            text: Globals.BackendWrapper.monolayerStructure.dmin
            onEditingFinished: Globals.BackendWrapper.monolayerStructure.dmin = parseFloat(text)
        }
    }

    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("Monolayer Fractions")
        }
        Local.Fractions {}
    }
}
