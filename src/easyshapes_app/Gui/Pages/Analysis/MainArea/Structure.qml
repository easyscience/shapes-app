// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle

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

    color: EaStyle.Colors.mainContentBackground

    StagePicker {
        id: selectorBlock

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: EaStyle.Sizes.fontPixelSize * 1.5

        visible: root.hasStages
        title: qsTr("Stage")
        model: root.stages
        currentIndex: Globals.BackendWrapper.stageViewSelectedStage
        onActivated: (index) => Globals.BackendWrapper.stageViewSelectStage(index)
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
