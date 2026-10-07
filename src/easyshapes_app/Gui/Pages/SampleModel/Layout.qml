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

    // Dynamic main-area tabs. The window set is built from backend state and fed
    // to the TabBar/SwipeView through Repeaters, so the conditional window (Lattice)
    // is genuinely INSERTED and REMOVED rather than hidden in place —
    // no reserved empty slot/gap. The two Repeaters share `mainAreaModel`, so the
    // tabs and views stay index-aligned. Rebuilds when the structure type or the
    // model type changes.
    //
    // LIMITATION: EaComponents.MainContent doesn't expose its TabBar.currentIndex,
    // so when a conditional window is inserted/removed the selected index can shift.
    // Preserving the selection across edits needs a key-aware container —
    // see the proposed framework component (a model-driven MainContent exposing
    // `currentKey`). The `key` field below is carried for that future container.
    readonly property var mainAreaModel: {
        let list = []
        list.push({ key: "shape", label: qsTr("Shape"), source: "MainArea/Shape.qml" })
        list.push({ key: "components", label: qsTr("Components"), source: "MainArea/Components.qml" })
        if (Globals.BackendWrapper.sampleModelCurrentType === "Lattice")
            list.push({ key: "lattice", label: qsTr("Lattice"), source: "MainArea/Lattice.qml" })
        return list
    }

    mainView: EaComponents.MainContent {
        tabs: [
            Repeater {
                model: root.mainAreaModel
                EaElements.TabButton {
                    text: root.mainAreaModel[index].label
                }
            }
        ]

        items: [
            Repeater {
                model: root.mainAreaModel
                Loader {
                    source: root.mainAreaModel[index].source
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

    Component.onCompleted: console.debug(`Sample model page loaded ::: ${this}`)
    Component.onDestruction: console.debug(`sample model page destroyed ::: ${this}`)

}
