// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.VectorImage

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: the equilibration's log, each gmx command and its
// output, as it grows. While a run goes on, a strip above it shows the
// spinning logo and the stage the run is on; a logo in the middle, as in
// the Structure tab, would cover the log. The log stays after the run.
Rectangle {
    id: root

    readonly property bool running: Globals.BackendWrapper.equilibrationFilesLocked
    readonly property string log: Globals.BackendWrapper.equilibrationLog

    color: EaStyle.Colors.mainContentBackground

    // Before any run: no log, just a hint
    EaElements.Label {
        anchors.centerIn: parent
        visible: root.log === "" && !root.running
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("Run Equilibrate to see the engine output")
    }

    Column {
        id: strip
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: EaStyle.Sizes.fontPixelSize
        visible: root.running
        spacing: EaStyle.Sizes.fontPixelSize * 0.5

        Row {
            spacing: EaStyle.Sizes.fontPixelSize

            // The SVG spins by its own animation, as in the Structure tab
            VectorImage {
                anchors.verticalCenter: parent.verticalCenter
                width: EaStyle.Sizes.fontPixelSize * 2.5
                height: width
                // Drawn at its own 660 px otherwise
                fillMode: VectorImage.PreserveAspectFit
                source: Qt.resolvedUrl("../../../Resources/Logos/EasyShapes.svg")
                preferredRendererType: VectorImage.CurveRenderer
                animations.loops: Animation.Infinite
            }

            EaElements.Label {
                anchors.verticalCenter: parent.verticalCenter
                color: EaStyle.Colors.themeForegroundMinor
                text: qsTr("Running eq%1 of eq%2–eq%3")
                      .arg(Globals.BackendWrapper.equilibrationStage)
                      .arg(Globals.BackendWrapper.equilibrationFirstStage)
                      .arg(Globals.BackendWrapper.equilibrationLastStage)
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: EaStyle.Colors.appBorder
        }
    }

    // A Flickable, not a ScrollView, so its scroll bars are EasyApp's, as
    // in EaComponents.ListView; a ScrollView's own had a black background
    Flickable {
        anchors.top: root.running ? strip.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: EaStyle.Sizes.fontPixelSize
        visible: root.log !== ""
        clip: true

        TextArea.flickable: EaElements.TextArea {
            readOnly: true
            wrapMode: TextEdit.NoWrap
            font.family: EaStyle.Fonts.monoFontFamily
            text: root.log
            // The newest lines stay in view as the log grows
            onTextChanged: cursorPosition = length
        }

        // Always shown while there is something to scroll: thin, wider
        // under the mouse
        ScrollBar.vertical: EaElements.ScrollBar {
            policy: size < 1.0 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
        }
        ScrollBar.horizontal: EaElements.ScrollBar {
            policy: size < 1.0 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
        }
    }
}
