// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.VectorImage

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals

EaComponents.SideBarColumn {

    EaElements.GroupBox {
        title: qsTr("Model Definition")
        icon: "tag"
        collapsed: false

        Loader { source: "Groups/SampleModel.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Components")
        icon: "puzzle-piece"

        Loader { source: "Groups/Components.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Ring Structure Definition")
        icon: "project-diagram"
        visible: Globals.BackendWrapper.sampleModelShape ==="Ring"

        Loader { source: "Groups/RingStructure.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Ball Structure Definition")
        icon: "project-diagram"
        visible: Globals.BackendWrapper.sampleModelShape ==="Ball"

        Loader { source: "Groups/BallStructure.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Vesicle Structure Definition")
        icon: "project-diagram"
        visible: Globals.BackendWrapper.sampleModelShape ==="Vesicle"

        Loader { source: "Groups/VesicleStructure.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Rod Structure Definition")
        icon: "project-diagram"
        visible: Globals.BackendWrapper.sampleModelShape ==="Rod"

        Loader { source: "Groups/RodStructure.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Bilayer Structure Definition")
        icon: "project-diagram"
        visible: Globals.BackendWrapper.sampleModelShape ==="Bilayer"

        Loader { source: "Groups/BilayerStructure.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Monolayer Structure Definition")
        icon: "project-diagram"
        visible: Globals.BackendWrapper.sampleModelShape ==="Monolayer"

        Loader { source: "Groups/MonolayerStructure.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Layers")
        icon: "layer-group"
        visible: Globals.BackendWrapper.sampleModelShape ==="Ball"

        Loader { source: "Groups/Layers.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Lamellae")
        icon: "layer-group"
        visible: Globals.BackendWrapper.sampleModelShape ==="Vesicle"

        Loader { source: "Groups/Lamellae.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Lattice Parameters")
        icon: "vector-square"
        visible: Globals.BackendWrapper.sampleModelLattice

        Loader { source: "Groups/LatticeStructure.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Buffer")
        icon: "flask"

        Loader { source: "Groups/Buffer.qml" }
    }

    // Centered "Assemble" call-to-action below the groups. While an
    // assembly runs, the logo, a note and Cancel take its place.
    Item {
        width: parent.width
        height: assembleButton.height + EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            id: assembleButton
            anchors.centerIn: parent
            visible: !Globals.BackendWrapper.sampleModelFilesLocked
            text: qsTr("Assemble")
            fontIcon: "cubes"
            width: EaStyle.Sizes.sideBarContentWidth
            onClicked: Globals.BackendWrapper.sampleModelAssemble()
        }

        Item {
            anchors.centerIn: parent
            width: EaStyle.Sizes.sideBarContentWidth
            height: assembleButton.height
            visible: Globals.BackendWrapper.sampleModelFilesLocked

            // Centred in the three quarters left of Cancel
            Row {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -cancelButton.width / 2
                spacing: EaStyle.Sizes.fontPixelSize * 0.5

                // The SVG spins by its own animation. A little larger
                // than the Assemble button's icon
                VectorImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width: EaStyle.Sizes.fontPixelSize * 1.5
                    height: width
                    // Drawn at its own 660 px otherwise
                    fillMode: VectorImage.PreserveAspectFit
                    source: Qt.resolvedUrl("../../../../Resources/Logos/EasyShapes.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    animations.loops: Animation.Infinite
                }

                EaElements.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Assembly in progress")
                }
            }

            EaElements.SideBarButton {
                id: cancelButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width / 4
                // Off a while after the start: shapespyer hangs when a
                // cancel meets its child process starting
                enabled: Globals.BackendWrapper.sampleModelCancelable
                text: qsTr("Cancel")
                fontIcon: "times"
                onClicked: Globals.BackendWrapper.sampleModelCancel()
            }
        }
    }
}
