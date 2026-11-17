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
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            width: EaStyle.Sizes.sideBarContentWidth * 0.2

            EaElements.Label {
                enabled: false
                text: qsTr("Fill")
            }
            EaElements.ComboBox {
                width: parent.width
                model: ["FIBO", "RINGS", "RINGS0"]
                currentIndex: model.indexOf(Globals.BackendWrapper.vesicleStructureFill)
                onActivated: (i) => Globals.BackendWrapper.vesicleStructureSetFill(model[i])
            }
        }

        // The last lamella's rmin plus its shell, worked out, not for editing
        Column {
            width: EaStyle.Sizes.sideBarContentWidth * 0.25

            EaElements.Label {
                enabled: false
                text: qsTr("Full radius, nm")
            }
            EaElements.TextField {
                readonly property var fullRadius: Globals.BackendWrapper.lamellaeFullRadius
                width: parent.width
                enabled: false
                text: typeof fullRadius === 'number' ? fullRadius.toFixed(2) : ""
                placeholderText: qsTr("unknown")
            }
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Fxz")
            checked: Globals.BackendWrapper.vesicleStructureFxz
            onToggled: Globals.BackendWrapper.vesicleStructureSetFxz(checked)
        }
        EaElements.CheckBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.15
            height: EaStyle.Sizes.fontPixelSize * 3
            text: qsTr("Rev")
            checked: Globals.BackendWrapper.vesicleStructureRev
            onToggled: Globals.BackendWrapper.vesicleStructureSetRev(checked)
        }
    }
}
