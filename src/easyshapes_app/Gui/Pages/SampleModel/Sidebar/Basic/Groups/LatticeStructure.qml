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
            text: Globals.BackendWrapper.latticeStructureAlpha
            onEditingFinished: Globals.BackendWrapper.latticeStructureSetAlpha(parseFloat(text))
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Theta")
            units: "⚬"
            validator: DoubleValidator { bottom: 0; top: 180 }
            text: Globals.BackendWrapper.latticeStructureTheta
            onEditingFinished: Globals.BackendWrapper.latticeStructureSetTheta(parseFloat(text))
        }
        EaElements.Parameter {
            width: root.thirdWidth
            title: qsTr("Sbuff")
            units: "nm"
            validator: DoubleValidator { bottom: 0 }
            text: Globals.BackendWrapper.latticeStructureSbuff
            onEditingFinished: Globals.BackendWrapper.latticeStructureSetSbuff(parseFloat(text))
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
                model: ["LCUB", "LBCC", "LFCC", "LHCP"]
                currentIndex: model.indexOf(Globals.BackendWrapper.latticeStructureLatticeType)
                onActivated: (i) => Globals.BackendWrapper.latticeStructureSetLatticeType(model[i])
            }
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Nlatx")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructureNlatx
            onEditingFinished: Globals.BackendWrapper.latticeStructureSetNlatx(parseInt(text))
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Nlaty")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructureNlaty
            onEditingFinished: Globals.BackendWrapper.latticeStructureSetNlaty(parseInt(text))
        }
        EaElements.Parameter {
            width: root.quarterWidth
            title: qsTr("Nlatz")
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructureNlatz
            onEditingFinished: Globals.BackendWrapper.latticeStructureSetNlatz(parseInt(text))
        }
    }
}
