// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals

EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3
    property double quarterWidth: (EaStyle.Sizes.sideBarContentWidth - 3 * EaStyle.Sizes.fontPixelSize) / 4

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Alpha")
            units: "⚬"
            validator: DoubleValidator { bottom: 0; top: 360 }
            text: Globals.BackendWrapper.latticeStructure.alpha
            onEditingFinished: Globals.BackendWrapper.latticeStructure.alpha = parseFloat(text)
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Theta")
            units: "⚬"
            validator: DoubleValidator { bottom: 0; top: 180 }
            text: Globals.BackendWrapper.latticeStructure.theta
            onEditingFinished: Globals.BackendWrapper.latticeStructure.theta = parseFloat(text)
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Sbuff")
            units: "nm"
            validator: DoubleValidator { bottom: 0 }
            text: Globals.BackendWrapper.latticeStructure.sbuff
            onEditingFinished: Globals.BackendWrapper.latticeStructure.sbuff = parseFloat(text)
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            width: root.quarterWidth

            EaElements.Label {
                enabled: false
                text: qsTr("Type")
            }
            EaElements.ComboBox {
                width: parent.width
                model: Globals.BackendWrapper.latticeStructure.latticeTypes
                Component.onCompleted: currentIndex = model.indexOf(Globals.BackendWrapper.latticeStructure.latticeType)
                onActivated: (i) => Globals.BackendWrapper.latticeStructure.latticeType = model[i]
            }
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Nlatx")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructure.nlatx
            onEditingFinished: Globals.BackendWrapper.latticeStructure.nlatx = parseInt(text)
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Nlaty")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructure.nlaty
            onEditingFinished: Globals.BackendWrapper.latticeStructure.nlaty = parseInt(text)
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Nlatz")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructure.nlatz
            onEditingFinished: Globals.BackendWrapper.latticeStructure.nlatz = parseInt(text)
        }
    }
}
