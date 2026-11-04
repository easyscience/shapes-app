// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals

EaComponents.SideBarColumn {

    EaElements.GroupBox {
        title: qsTr("Equilibration setup")
        icon: "sliders-h"
        collapsed: false

        Loader { source: "Groups/EquilibrationSetup.qml" }
    }

    // Centered "Equilibrate" call-to-action below the groups. While a run
    // goes on, Cancel equilibration takes its place; its progress shows
    // in the Engine output tab.
    Item {
        width: parent.width
        height: equilibrateButton.height + EaStyle.Sizes.fontPixelSize

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

        EaElements.SideBarButton {
            anchors.centerIn: parent
            visible: Globals.BackendWrapper.equilibrationFilesLocked
            width: equilibrateButton.width
            // Off a while after the start, as Cancel assembly
            enabled: Globals.BackendWrapper.equilibrationCancelable
            text: qsTr("Cancel equilibration")
            fontIcon: "times"
            onClicked: Globals.BackendWrapper.equilibrationCancel()
        }
    }
}
