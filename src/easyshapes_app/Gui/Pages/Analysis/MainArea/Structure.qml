// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals

import "../../SampleModel/MainArea" as SampleModelArea


// Main-area window: the initial structure, the equilibration's copy of
// the model, or a finished stage's, its final <model>-eq<k>.gro, through
// the Sample model page's structure view. Picked as the Components viewer
// picks its component: a dropdown at the top right, the view below. Until
// one is picked, the newest shows.
Rectangle {
    id: root

    readonly property var stages: Globals.BackendWrapper.stageViewStages
    readonly property bool hasStages: stages ? stages.count > 0 : false

    // Rows of stages change their status in place, which a read of one
    // row doesn't follow: each change counts here
    property int _revision: 0
    Connections {
        target: root.stages
        function onDataChanged() { root._revision++ }
        function onRowsInserted() { root._revision++ }
        function onRowsRemoved() { root._revision++ }
        function onModelReset() { root._revision++ }
    }
    readonly property var selected: {
        root._revision
        const index = Globals.BackendWrapper.stageViewSelectedStage
        return root.stages && index >= 0 && index < root.stages.count ? root.stages.get(index) : null
    }

    // A row's name, with its status in the minor colour, as in
    // Equilibration Files; Initial has none
    function label(name, status) {
        return status ? `${name}&nbsp;&nbsp;<font color='$TEXT_COLOR'>${status}</font>` : name
    }

    color: EaStyle.Colors.mainContentBackground

    // Stage selector, as the Components viewer's component selector
    Column {
        id: selectorBlock

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: EaStyle.Sizes.fontPixelSize * 1.5

        visible: root.hasStages

        EaElements.Label {
            enabled: false
            text: qsTr("Stage")
        }

        EaElements.ComboBox {
            id: picker
            width: EaStyle.Sizes.fontPixelSize * 14
            model: root.stages
            currentIndex: Globals.BackendWrapper.stageViewSelectedStage
            displayText: root.selected ? root.label(root.selected.name, root.selected.status) : ""
            onActivated: (index) => Globals.BackendWrapper.stageViewSelectStage(index)

            // As EaElements.ComboBox's own, with the status after the
            // name: its textRole takes one role only
            delegate: EaElements.MenuItem {
                required property int index
                required property string name
                required property string status

                width: parent !== null ? parent.width : 0
                height: EaStyle.Sizes.comboBoxHeight
                font.family: picker.font.family
                textFormat: Text.RichText
                text: root.label(name, status).split('$TEXT_COLOR').join(EaStyle.Colors.themeForegroundMinor)
                highlighted: picker.highlightedIndex === index
                hoverEnabled: picker.hoverEnabled
            }
        }
    }

    // The picked stage's structure; no run covers it, as a stage's
    // final .gro is written once
    SampleModelArea.Structure {
        anchors.top: root.hasStages ? selectorBlock.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: root.hasStages ? EaStyle.Sizes.fontPixelSize : 0

        instancing: Globals.BackendWrapper.stageViewInstancing
        hasStructure: Globals.BackendWrapper.stageViewHasStructure
        loading: Globals.BackendWrapper.stageViewLoading
        error: Globals.BackendWrapper.stageViewError
        setActive: (active) => Globals.BackendWrapper.stageViewSetActive(active)
        busy: false
        emptyText: qsTr("Run Equilibrate to see a stage's structure")
    }
}
