// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Helpers

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: the sample model's assembled structure, atom by atom,
// cut to a slab across an axis.
//
// The atoms come as an instance table (structureViewInstancing): Python
// reads the model's .gro while this tab is in front and sends the GPU only
// the slab's atoms; the mock gives a small SDS micelle. Every atom is one
// square (2 triangles) that the shaders (StructureSlab.vert/.frag) turn to
// the camera, cut to a circle and shade as a sphere lit from the screen.
// With Show bonds, a second table (bondInstancing) gives each bond as two
// halves, squares that StructureBond.vert/.frag stretch to sticks. The
// background, the slab, the bonds and whether the atoms stay loaded are
// set in Advanced controls, Structure viewer.
Rectangle {
    id: root

    readonly property var instancing: Globals.BackendWrapper.structureViewInstancing
    // Strength of the shader's light (1 = full colour where it faces it)
    property real brightness: 1.0

    color: EaStyle.Colors.mainContentBackground

    // In front: the current item of every SwipeView it sits in (the
    // main-area tabs, the app's pages), which keep all their pages built
    // and visible
    readonly property bool _shown: {
        for (let item = parent; item; item = item.parent)
            if (item.SwipeView.view && !item.SwipeView.isCurrentItem)
                return false
        return true
    }
    on_ShownChanged: Globals.BackendWrapper.structureViewSetActive(_shown)
    Component.onCompleted: Globals.BackendWrapper.structureViewSetActive(_shown)
    Component.onDestruction: Globals.BackendWrapper.structureViewSetActive(false)

    // The background picker's choices: the theme's, black, white, 50% grey
    readonly property var _backgrounds: [root.color, "#000000", "#ffffff", "#808080"]
    readonly property var _axes: [Qt.vector3d(1, 0, 0), Qt.vector3d(0, 1, 0), Qt.vector3d(0, 0, 1)]
    // Room for the farthest atom, Å
    readonly property real _radius: Math.max(instancing.radius, 1)
    // The wheel's zoom on top of the fit
    property real _zoom: 1
    // Sticks drawn: bonds in the slab, Show bonds ticked. Unticked, they
    // hide at once, before Python reads the file again without bonds;
    // the mock's table is always there
    readonly property bool _sticks: instancing.shownCount > 0
                                    && instancing.slabRows > instancing.slabCount
                                    && Globals.Vars.structureShowBonds

    View3D {
        id: view
        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            clearColor: root._backgrounds[Globals.Vars.structureBackground]
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        // Camera orbits this node, at the structure's centre. No scene
        // light: the shader lights the atoms itself.
        Node {
            id: originNode
            PerspectiveCamera {
                id: camera
                // Fits the farthest atom in the 60° view, with room to spare
                z: root._radius * 3.5 * root._zoom
                clipNear: 1
                clipFar: root._radius * 20
            }
        }

        // One square per atom or bond half, -1..1; the vertex shaders
        // turn it to the camera and size it
        ProceduralMesh {
            id: square
            positions: [Qt.vector3d(-1, -1, 0), Qt.vector3d(1, -1, 0),
                        Qt.vector3d(1, 1, 0), Qt.vector3d(-1, 1, 0)]
            indexes: [0, 1, 2, 0, 2, 3]
        }

        // Always visible, its table empty without atoms: hidden until the
        // first atoms came, Qt drew the frame that showed it before their
        // table was up, and the atoms only appeared on the next frame
        Model {
            geometry: square
            instancing: root.instancing
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                cullMode: Material.NoCulling
                vertexShader: "StructureSlab.vert"
                fragmentShader: "StructureSlab.frag"
                // Uniforms of the shaders
                property vector3d slabAxis: root._axes[root.instancing.slabAxis]
                property real slabHalf: root._radius * root.instancing.slabFraction
                property real brightness: root.brightness
                // Ball and stick while sticks are drawn: atoms at 0.25 x
                // the van der Waals radius, not 0.4, or they would cover
                // the sticks
                property real radiusScale: root._sticks ? 0.625 : 1.0
            }
        }

        Model {
            visible: root._sticks
            geometry: square
            instancing: root.instancing.bondInstancing
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Unshaded
                cullMode: Material.NoCulling
                vertexShader: "StructureBond.vert"
                fragmentShader: "StructureBond.frag"
                // Uniforms of the shaders
                property vector3d slabAxis: root._axes[root.instancing.slabAxis]
                property real slabHalf: root._radius * root.instancing.slabFraction
                property real brightness: root.brightness
            }
        }
    }

    // Left-drag turns, right-drag pans, the wheel zooms, as in the
    // Components viewer.
    TrackballControl {
        anchors.fill: view
        origin: originNode
        camera: camera
        onZoomed: (factor) => root._zoom *= factor
    }

    // While an assembly runs, the placeholder covers the structure it
    // replaces. A cover, not a hidden view: a Model shown in the frame
    // its table comes up in is drawn a frame late
    Rectangle {
        anchors.fill: view
        visible: Globals.BackendWrapper.sampleModelFilesLocked
        color: view.environment.clearColor
    }

    // What the view can't show, in its middle, and which way to move
    // the slider when the slab is the reason
    EaElements.Label {
        anchors.centerIn: view
        width: Math.min(implicitWidth, view.width - 2 * EaStyle.Sizes.fontPixelSize)
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: Globals.BackendWrapper.structureViewError
               && !Globals.BackendWrapper.sampleModelFilesLocked
               ? EaStyle.Colors.red : EaStyle.Colors.themeForegroundMinor
        // The structure is read again when the assembly ends
        text: Globals.BackendWrapper.sampleModelFilesLocked
              ? qsTr("Assembling…")
              : !Globals.BackendWrapper.structureViewHasStructure
              ? qsTr("Assemble the model to see its structure")
              : Globals.BackendWrapper.structureViewLoading
                ? qsTr("Loading…")
                : Globals.BackendWrapper.structureViewError
                  ? Globals.BackendWrapper.structureViewError
                  : root.instancing.atomCount === 0
                    ? ""
                    : root.instancing.slabCount === 0
                      ? qsTr("No atoms in the slab: raise Slab thickness in Advanced controls")
                      : ""
        visible: text !== ""
    }

    EaElements.Label {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: EaStyle.Sizes.fontPixelSize
        visible: root.instancing.atomCount > 0 && !Globals.BackendWrapper.sampleModelFilesLocked
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("%1 of %2 atoms are shown")
              .arg(root.instancing.shownCount.toLocaleString(Qt.locale(), 'f', 0))
              .arg(root.instancing.atomCount.toLocaleString(Qt.locale(), 'f', 0))
    }
}
