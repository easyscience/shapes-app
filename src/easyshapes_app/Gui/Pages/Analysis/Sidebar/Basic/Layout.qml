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

        Loader { source: "Groups/AnalysisConfig.qml" }
    }

    // Centered "Equilibrate" call-to-action below the groups.
    Item {
        width: parent.width
        height: equilibrateButton.height + EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            id: equilibrateButton
            anchors.centerIn: parent
            text: qsTr("Equilibrate")
            fontIcon: "magic"
            width: EaStyle.Sizes.sideBarContentWidth
            enabled: Globals.BackendWrapper.analysisConfigFiles
                     ? Globals.BackendWrapper.analysisConfigFiles.count > 0
                     : false
            onClicked: {
                console.debug("Equilibrate clicked")
                Globals.BackendWrapper.activeBackend.analysis.equilibrate()
            }
        }
    }
}
