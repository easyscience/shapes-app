// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements


// Main-area window: lattice depiction — size and placement of the lattice
// units. Shown only for the Lattice type.
// DRAFT CONTAINER — rendering not implemented yet.
Rectangle {

    color: EaStyle.Colors.mainContentBackground

    Column {
        anchors.centerIn: parent
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: EaStyle.Sizes.fontPixelSize * 1.5
            color: EaStyle.Colors.themeForegroundMinor
            text: qsTr("Lattice")
        }

        EaElements.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: EaStyle.Colors.themeForegroundMinor
            text: qsTr("Placeholder — to be implemented")
        }

        EaElements.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: EaStyle.Colors.themeForegroundMinor
            text: qsTr("Will show lattice unit size and placement.")
        }
    }

}
