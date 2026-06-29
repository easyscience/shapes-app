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


EaComponents.ContentPage {

    // Two static main-area windows. Both are always shown; their content stays
    // empty until equilibration is finished (gated on the backend's
    // `analysis.equilibrated` flag, set by the sidebar's Equilibrate button).
    mainView: EaComponents.MainContent {
        tabs: [
            EaElements.TabButton { text: qsTr("Engine output") },
            EaElements.TabButton { text: qsTr("Scattering") }
        ]

        items: [
            Loader { source: "MainArea/EngineOutput.qml" },
            Loader { source: "MainArea/Scattering.qml" }
        ]
    }

    sideBar: EaComponents.SideBar {
        tabs: [
            EaElements.TabButton { text: qsTr("Basic controls") }
        ]

        items: [
            Loader { source: "Sidebar/Basic/Layout.qml" }
        ]

        continueButton.text: qsTr("Continue")

        continueButton.onClicked: {            
            console.debug(`Clicking '${continueButton.text}' button ::: ${this}`)
            Globals.References.applicationWindow.appBarCentralTabs.summaryButton.enabled = true
            Globals.References.applicationWindow.appBarCentralTabs.summaryButton.toggle()
        }
    }

    Component.onCompleted: console.debug(`Analysis page loaded ::: ${this}`)
    Component.onDestruction: console.debug(`Analysis page destroyed ::: ${this}`)

}
