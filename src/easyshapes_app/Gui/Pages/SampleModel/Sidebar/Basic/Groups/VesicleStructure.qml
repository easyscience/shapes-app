// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


EaElements.GroupColumn {

    Row {
        property real itemWidth: EaStyle.Sizes.sideBarContentWidth * 0.2
        spacing: EaStyle.Sizes.fontPixelSize * 2

        Column {
            width: parent.itemWidth

            EaElements.Label {
                enabled: false
                text: qsTr('Fill')
            }
            EaElements.ComboBox {
                width: parent.width
                model: ['FIBO', 'RINGS', 'RINGS0']
                Component.onCompleted: {
                    currentIndex = model.indexOf(Globals.BackendWrapper.ballStructure.fill)
                }
                onActivated: (i) => {
                    Globals.BackendWrapper.ballStructure.fill = model[i]
                }
            }
        }
        EaElements.CheckBox {
            height: EaStyle.Sizes.fontPixelSize * 5
            text: qsTr('Fxz')
            checked: Globals.BackendWrapper.ballStructure.fxz
            onToggled: Globals.BackendWrapper.ballStructure.fxz = checked
        }
        EaElements.CheckBox {
            height: EaStyle.Sizes.fontPixelSize * 5
            text: qsTr('Rev')
            checked: Globals.BackendWrapper.ballStructure.rev
            onToggled: Globals.BackendWrapper.ballStructure.rev = checked
        }
    }
}
