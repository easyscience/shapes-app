// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals

EaElements.GroupColumn {

    // 1st row
    EaElements.GroupRow {
        spacing: EaStyle.Sizes.fontPixelSize

        // button
        EaElements.SideBarButton {
            id: generateDataButton

            fontIcon: 'plus-circle'
            text: qsTr('Generate new data')

            onClicked: {
                console.debug(`Clicking '${text}' button ::: ${this}`)
                Globals.BackendWrapper.activeBackend.analysis.generateData()
            }
        }
        // button

        // text input
        EaElements.ParamTextField {
            height: generateDataButton.height

            inputMethodHints: Qt.ImhDigitsOnly

            value: Globals.BackendWrapper.activeBackend.analysis.dataSize
            units: 'points'

            onTextChanged: {
                Globals.BackendWrapper.activeBackend.analysis.dataSize = text
            }
        }
        // text input
    }
    // 1st row
}
