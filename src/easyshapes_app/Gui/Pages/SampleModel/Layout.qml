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

    // Main-area tabs, fed to the TabBar and the SwipeView through two
    // Repeaters on one model, so tabs and views stay index-aligned. The
    // Lattice tab is appended and removed in place, while the model is a
    // lattice: the other tabs stay built, and the tab in front stays,
    // unless it is the Lattice tab being removed.
    ListModel {
        id: mainAreaModel
        ListElement { label: QT_TR_NOOP("Shape"); file: "MainArea/Shape.qml" }
        ListElement { label: QT_TR_NOOP("Components"); file: "MainArea/Components.qml" }
        ListElement { label: QT_TR_NOOP("Structure"); file: "MainArea/Structure.qml" }
    }
    readonly property int _structureTab: 2
    readonly property int _latticeTab: 3
    // The main-area TabBar; MainContent doesn't expose it, its tabs do
    property var _tabBar: null

    function _syncLatticeTab() {
        const shown = mainAreaModel.count > _latticeTab
        if (Globals.BackendWrapper.sampleModelLattice && !shown) {
            mainAreaModel.append({ label: QT_TR_NOOP("Lattice"), file: "MainArea/Lattice.qml" })
        } else if (!Globals.BackendWrapper.sampleModelLattice && shown) {
            // Leaving the Lattice tab itself: back to the first tab
            if (_tabBar && _tabBar.currentIndex === _latticeTab)
                _tabBar.currentIndex = 0
            mainAreaModel.remove(_latticeTab)
        }
    }

    Connections {
        target: Globals.BackendWrapper
        function onSampleModelLatticeChanged() { root._syncLatticeTab() }
        // An assembly started: its progress shows in the Structure tab
        function onSampleModelFilesLockedChanged() {
            if (Globals.BackendWrapper.sampleModelFilesLocked && root._tabBar)
                root._tabBar.currentIndex = root._structureTab
        }
    }

    mainView: EaComponents.MainContent {
        tabs: [
            Repeater {
                model: mainAreaModel
                EaElements.TabButton {
                    text: qsTr(model.label)
                    Component.onCompleted: root._tabBar = TabBar.tabBar
                }
            }
        ]

        items: [
            Repeater {
                model: mainAreaModel
                Loader {
                    source: model.file
                }
            }
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
            Globals.References.applicationWindow.appBarCentralTabs.analysisButton.enabled = true
            Globals.References.applicationWindow.appBarCentralTabs.analysisButton.toggle()
        }
    }

    Component.onCompleted: {
        _syncLatticeTab()
        console.debug(`Sample model page loaded ::: ${this}`)
    }
    Component.onDestruction: console.debug(`sample model page destroyed ::: ${this}`)

}
