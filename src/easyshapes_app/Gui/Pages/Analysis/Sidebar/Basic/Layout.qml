// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals

EaComponents.SideBarColumn {

    EaElements.GroupBox {
        title: qsTr("Equilibration")
        icon: "sliders-h"
        collapsed: false

        Column {
            spacing: EaStyle.Sizes.fontPixelSize

            Loader { source: "Groups/EquilibrationSetup.qml" }

            // "Equilibrate" under the setup. While a run goes on, Cancel
            // equilibration takes its place; its progress shows in the
            // Engine output tab. Outside the setup's column, which is off
            // during a run, so Cancel stays on
            Item {
                width: EaStyle.Sizes.sideBarContentWidth
                height: equilibrateButton.height

                EaElements.SideBarButton {
                    id: equilibrateButton
                    anchors.centerIn: parent
                    visible: !Globals.BackendWrapper.equilibrationFilesLocked
                    text: qsTr("Equilibrate")
                    fontIcon: "magic"
                    width: EaStyle.Sizes.sideBarContentWidth / 2
                    // The run starts from the model's files, which an assembly
                    // writes; and it needs GROMACS
                    enabled: Globals.BackendWrapper.sampleModelShape !== ""
                             && !Globals.BackendWrapper.sampleModelFilesLocked
                             && Globals.BackendWrapper.configGmxProblem === ""
                    onClicked: Globals.BackendWrapper.equilibrationRun()
                }

                // A disabled button gets no hover, so its own tooltip never
                // shows: this area over it says why it is off. No clicks
                MouseArea {
                    anchors.fill: equilibrateButton
                    visible: equilibrateButton.visible && !equilibrateButton.enabled
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton

                    EaElements.ToolTip {
                        text: Globals.BackendWrapper.configGmxProblem
                              ? qsTr("GROMACS can't run: %1").arg(Globals.BackendWrapper.configGmxProblem)
                              : ""
                        visible: parent.containsMouse && EaGlobals.Vars.showToolTips && text !== ""
                    }
                }

                EaElements.SideBarButton {
                    anchors.centerIn: parent
                    visible: Globals.BackendWrapper.equilibrationFilesLocked
                    width: equilibrateButton.width
                    text: qsTr("Cancel equilibration")
                    fontIcon: "times"
                    onClicked: Globals.BackendWrapper.equilibrationCancel()
                }
            }
        }
    }

    // Built as Equilibration: the setup, then its button outside the
    // setup's column. Closed at first: only the first group opens
    EaElements.GroupBox {
        title: qsTr("Scattering")
        icon: "chart-line"

        Column {
            spacing: EaStyle.Sizes.fontPixelSize

            Loader {
                id: scatteringSetup
                source: "Groups/ScatteringSetup.qml"
            }

            // "Calculate" under the setup. While a calculation runs,
            // Cancel calculation takes its place; the Scattering tab
            // shows the run
            Item {
                width: EaStyle.Sizes.sideBarContentWidth
                height: calculateButton.height

                EaElements.SideBarButton {
                    id: calculateButton
                    anchors.centerIn: parent
                    visible: !Globals.BackendWrapper.scatteringFilesLocked
                    text: qsTr("Calculate")
                    fontIcon: "play-circle"
                    width: EaStyle.Sizes.sideBarContentWidth / 2
                    // An assembly rewrites the model's .gro, which Initial
                    // reads
                    enabled: Globals.BackendWrapper.scatteringSelectedStructure >= 0
                             && (scatteringSetup.item?.fieldsValid ?? false)
                             && !Globals.BackendWrapper.sampleModelFilesLocked
                    onClicked: Globals.BackendWrapper.scatteringCalculate()
                }

                // A disabled button gets no hover, so its own tooltip never
                // shows: this area over it says why it is off. No clicks
                MouseArea {
                    anchors.fill: calculateButton
                    visible: calculateButton.visible && !calculateButton.enabled
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton

                    EaElements.ToolTip {
                        text: Globals.BackendWrapper.sampleModelFilesLocked
                              ? qsTr("Wait for the assembly to end")
                              : Globals.BackendWrapper.scatteringSelectedStructure < 0
                                ? qsTr("Assemble the sample model first")
                                : qsTr("Fix the red fields")
                        visible: parent.containsMouse && EaGlobals.Vars.showToolTips
                    }
                }

                EaElements.SideBarButton {
                    anchors.centerIn: parent
                    visible: Globals.BackendWrapper.scatteringFilesLocked
                    width: calculateButton.width
                    text: qsTr("Cancel calculation")
                    fontIcon: "times"
                    onClicked: Globals.BackendWrapper.scatteringCancel()
                }
            }
        }
    }
}
