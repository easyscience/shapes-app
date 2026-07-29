// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: Components. A dropdown selects which loaded component to
// depict (mirroring the component selector in the Advanced tab's Components Files
// group), and the selected component is shown below in a ComponentView. Keeping
// the per-component choice in a ComboBox keeps the page's outer tabs simple.
// DRAFT CONTAINER — per-component rendering not implemented yet.
Rectangle {
    id: root

    readonly property var components: Globals.BackendWrapper.componentsLoaded

    color: EaStyle.Colors.mainContentBackground

    // Empty state — no components loaded yet.
    EaElements.Label {
        anchors.centerIn: parent
        visible: root.components.count === 0
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("No components yet — load or create one in the sidebar.")
    }

    // Component selector. Mirrors Advanced › Components Files: dropdown over the
    // loaded components by name. The current index is the selection driving the
    // ComponentView below.
    Column {
        id: selectorBlock

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: EaStyle.Sizes.fontPixelSize * 1.5

        visible: root.components.count > 0

        EaElements.Label {
            enabled: false
            text: qsTr("Component")
        }

        EaElements.ComboBox {
            id: componentSelector
            width: EaStyle.Sizes.fontPixelSize * 20
            textRole: "name"
            model: root.components

            // Keep the selection valid as components are added/removed.
            Connections {
                target: root.components
                function onCountChanged() {
                    if (root.components.count === 0)
                        componentSelector.currentIndex = -1
                    else if (componentSelector.currentIndex < 0)
                        componentSelector.currentIndex = 0
                    else if (componentSelector.currentIndex >= root.components.count)
                        componentSelector.currentIndex = root.components.count - 1
                }
            }
        }
    }

    // The selected component's depiction.
    ComponentView {
        anchors.top: selectorBlock.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: EaStyle.Sizes.fontPixelSize

        visible: root.components.count > 0

        readonly property bool hasSelection: componentSelector.currentIndex >= 0
                                             && componentSelector.currentIndex < root.components.count
        readonly property var selectedRow: hasSelection
                                            ? root.components.get(componentSelector.currentIndex)
                                            : null

        componentIndex: componentSelector.currentIndex
        componentName: hasSelection ? selectedRow.name : ""
        // mint/mext are atom indices; the viewer draws an arrow atom[mint] -> atom[mext].
        componentMint: hasSelection ? selectedRow.mint : -1
        componentMext: hasSelection ? selectedRow.mext : -1
    }

}
