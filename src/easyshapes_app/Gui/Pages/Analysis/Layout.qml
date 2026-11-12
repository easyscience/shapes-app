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
    id: root

    readonly property int _engineOutputTab: 0
    readonly property int _scatteringTab: 2
    // The main-area TabBar; MainContent doesn't expose it, its tabs do
    property var _tabBar: null

    Connections {
        target: Globals.BackendWrapper
        // A run started: its log shows in the Engine output tab
        function onEquilibrationFilesLockedChanged() {
            if (Globals.BackendWrapper.equilibrationFilesLocked && root._tabBar)
                root._tabBar.currentIndex = root._engineOutputTab
        }
        // A calculation started: the Scattering tab shows it
        function onScatteringFilesLockedChanged() {
            if (Globals.BackendWrapper.scatteringFilesLocked && root._tabBar)
                root._tabBar.currentIndex = root._scatteringTab
        }
    }
    // A hidden chart renders nothing: Export as PNG shows the tab first
    Connections {
        target: Globals.Vars
        function onScatteringPngRequested() {
            if (root._tabBar)
                root._tabBar.currentIndex = root._scatteringTab
        }
    }

    // Three static main-area windows: the run's log, a finished stage's
    // structure, and the SANS curves
    mainView: EaComponents.MainContent {
        tabs: [
            EaElements.TabButton {
                text: qsTr("Engine output")
                Component.onCompleted: root._tabBar = TabBar.tabBar
            },
            EaElements.TabButton { text: qsTr("Structure") },
            EaElements.TabButton { text: qsTr("Scattering") }
        ]

        items: [
            Loader { source: "MainArea/EngineOutput.qml" },
            Loader { source: "MainArea/Structure.qml" },
            Loader { source: "MainArea/Scattering.qml" }
        ]
    }

    sideBar: EaComponents.SideBar {
        tabs: [
            EaElements.TabButton { text: qsTr("Basic controls") },
            EaElements.TabButton { text: qsTr("Advanced controls") }
        ]

        items: [
            Loader { source: "Sidebar/Basic/Layout.qml" },
            Loader { source: "Sidebar/Advanced/Layout.qml" }
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
