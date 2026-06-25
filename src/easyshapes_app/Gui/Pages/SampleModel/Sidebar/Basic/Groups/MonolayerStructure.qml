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
            title: qsTr("Zsep")
            units: "nm"
            validator: DoubleValidator { bottom: 0 }
            text: Globals.BackendWrapper.monolayerStructure.zsep
            onEditingFinished: Globals.BackendWrapper.monolayerStructure.zsep = parseFloat(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr("Nside")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.monolayerStructure.nside
            onEditingFinished: Globals.BackendWrapper.monolayerStructure.nside = parseInt(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
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
