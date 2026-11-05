// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.VectorImage

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: a log, picked at the top right as the Structure tab
// picks its stage. Equilibration is the run's log, each gmx command and
// its output, as it grows; each run empties it. A finished stage shows
// its mdrun log, <model>-eq<k>.log, which stays. While a run goes on,
// the top left shows the spinning logo and the stage the run is on; a
// logo in the middle, as in the Structure tab, would cover the log.
Rectangle {
    id: root

    readonly property bool running: Globals.BackendWrapper.equilibrationFilesLocked
    readonly property string log: Globals.BackendWrapper.equilibrationLog
    readonly property var entries: Globals.BackendWrapper.equilibrationEntries
    // Equilibration is always a row: the picker shows once a stage is
    readonly property bool hasStages: entries ? entries.count > 1 : false

    // Why the picked log is empty; '' while the run's log is about to
    // grow. Equilibration is the row without a status
    readonly property string hint: {
        const picked = picker.selected
        if (root.log !== "")
            return ""
        if (!picked || !picked.status)
            return root.running ? "" : qsTr("Run Equilibrate to see the engine output")
        switch (picked.status) {
        case "running":
            return qsTr("%1 is running: pick Equilibration for its output").arg(picked.name)
        case "not run":
            return qsTr("%1 hasn't run yet").arg(picked.name)
        default:
            return qsTr("%1 holds no log").arg(picked.name)
        }
    }

    color: EaStyle.Colors.mainContentBackground

    EaElements.Label {
        anchors.centerIn: parent
        visible: root.hint !== ""
        color: EaStyle.Colors.themeForegroundMinor
        text: root.hint
    }

    // The run's progress at the left, the log picker at the right, a
    // line under both
    Column {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: EaStyle.Sizes.fontPixelSize
        visible: root.running || root.hasStages
        spacing: EaStyle.Sizes.fontPixelSize * 0.5

        Item {
            width: parent.width
            height: Math.max(progress.visible ? progress.height : 0,
                             picker.visible ? picker.height : 0)

            Row {
                id: progress
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                visible: root.running
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

            StagePicker {
                id: picker
                anchors.right: parent.right
                visible: root.hasStages
                title: qsTr("Log")
                model: root.entries
                currentIndex: Globals.BackendWrapper.equilibrationSelectedLog
                onActivated: (index) => Globals.BackendWrapper.equilibrationSelectLog(index)
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
        anchors.top: header.visible ? header.bottom : parent.top
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
