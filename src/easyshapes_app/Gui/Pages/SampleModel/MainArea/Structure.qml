// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick.VectorImage

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
// the camera, cut to a circle and shade as a sphere. With Show bonds, a
// second table (bondInstancing) gives each bond as two halves, squares
// that StructureBond.vert stretches to sticks and StructureSlab.frag
// shades as cylinders. The background, the slab, the lighting, the bonds
// and whether the atoms stay loaded are set in Advanced controls,
// Structure viewer.
Rectangle {
    id: root

    readonly property var instancing: Globals.BackendWrapper.structureViewInstancing
    // Strength of the shader's light (1 = full colour where it faces it)
    property real brightness: 1.0
    // Artistic-free keeps the lights on the structure: it turns them
    // against the camera, which the trackball turns by turning originNode.
    // The other modes keep them on the camera
    readonly property quaternion _lightTurn: Globals.Vars.structureLighting === 1
                                             ? originNode.rotation.inverted()
                                             : Qt.quaternion(1, 0, 0, 0)
    // The key light, in view space: from the upper left, 45° in front as
    // the view starts
    readonly property vector3d _keyLight: _lightTurn.times(Qt.vector3d(-0.57735, 0.57735, 0.57735))

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
    // Qt draws a new table a frame late, and draws no further frame when
    // nothing else moves: the atoms stayed away until a drag. So the two
    // frames after a new table change _frame, a uniform no shader reads,
    // and each change asks Qt for one more frame
    property int _frame: 0
    property int _framesLeft: 0

    Connections {
        target: root.instancing
        // The mock's table never changes
        ignoreUnknownSignals: true
        function onSlabChanged() { root._framesLeft = 2 }
    }

    Connections {
        target: root.Window.window
        enabled: root._framesLeft > 0
        function onFrameSwapped() {
            root._framesLeft--
            root._frame++
        }
    }

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

        // Camera orbits this node, at the structure's centre. The shader
        // lights the atoms itself; the scene's one light only casts the
        // Artistic modes' shadows.
        Node {
            id: originNode
            PerspectiveCamera {
                id: camera
                // Fits the farthest atom in the 60° view, with room to spare
                z: root._radius * 3.5 * root._zoom
                clipNear: 1
                clipFar: root._radius * 20

                // Along the shader's key light (_keyLight), turned as it
                Node {
                    rotation: root._lightTurn
                    // From the upper left, 45° in front. Lengths in Å
                    DirectionalLight {
                        eulerRotation: Qt.vector3d(-35.26, -45, 0)
                        castsShadow: Globals.Vars.structureLighting === 1
                                     || Globals.Vars.structureLighting === 2
                        shadowMapQuality: Light.ShadowMapQualityVeryHigh
                        softShadowQuality: Light.PCF8
                        pcfFactor: 0.5
                        // An atom's radius: an atom doesn't shade itself
                        shadowBias: 1.0
                        // Past the far side of the structure
                        shadowMapFar: camera.z + root._radius * 2
                    }
                }
            }
        }

        // One square per atom or bond half, -1..1; the vertex shaders
        // turn it to the camera and size it. Normals, which a shaded
        // material reads; the shaders turn them to the camera
        ProceduralMesh {
            id: square
            positions: [Qt.vector3d(-1, -1, 0), Qt.vector3d(1, -1, 0),
                        Qt.vector3d(1, 1, 0), Qt.vector3d(-1, 1, 0)]
            normals: [Qt.vector3d(0, 0, 1), Qt.vector3d(0, 0, 1),
                      Qt.vector3d(0, 0, 1), Qt.vector3d(0, 0, 1)]
            indexes: [0, 1, 2, 0, 2, 3]
        }

        // Always visible, its table empty without atoms: hidden until the
        // first atoms came, Qt drew the frame that showed it before their
        // table was up, and the atoms only appeared on the next frame
        Model {
            geometry: square
            instancing: root.instancing
            materials: CustomMaterial {
                // Shaded for the shadows only
                shadingMode: CustomMaterial.Shaded
                cullMode: Material.NoCulling
                vertexShader: "StructureSlab.vert"
                fragmentShader: "StructureSlab.frag"
                // Uniforms of the shaders
                property vector3d slabAxis: root._axes[root.instancing.slabAxis]
                property real slabHalf: root._radius * root.instancing.slabFraction
                property real brightness: root.brightness
                property int lighting: Globals.Vars.structureLighting
                property vector3d keyLight: root._keyLight
                // Ball and stick while sticks are drawn: atoms at 0.25 x
                // the van der Waals radius, not 0.4, or they would cover
                // the sticks
                property real radiusScale: root._sticks ? 0.625 : 1.0
                property int frame: root._frame
            }
        }

        Model {
            visible: root._sticks
            geometry: square
            instancing: root.instancing.bondInstancing
            materials: CustomMaterial {
                shadingMode: CustomMaterial.Shaded
                cullMode: Material.NoCulling
                vertexShader: "StructureBond.vert"
                // The atoms' light, on a cylinder
                fragmentShader: "StructureSlab.frag"
                // Uniforms of the shaders
                property vector3d slabAxis: root._axes[root.instancing.slabAxis]
                property real slabHalf: root._radius * root.instancing.slabFraction
                property real brightness: root.brightness
                property int lighting: Globals.Vars.structureLighting
                property vector3d keyLight: root._keyLight
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

    // While an assembly runs, a cover hides the structure it replaces.
    // A cover, not a hidden view: a Model shown in the frame its table
    // comes up in is drawn a frame late
    Rectangle {
        anchors.fill: view
        visible: Globals.BackendWrapper.sampleModelFilesLocked
        color: view.environment.clearColor
    }

    // While an assembly runs or the file is read: the spinning logo,
    // and which of the two under it
    Column {
        anchors.centerIn: view
        visible: Globals.BackendWrapper.sampleModelFilesLocked
                 || Globals.BackendWrapper.structureViewLoading
        spacing: EaStyle.Sizes.fontPixelSize

        // The SVG spins by its own animation. As large as the Home
        // page's logo
        VectorImage {
            anchors.horizontalCenter: parent.horizontalCenter
            width: EaStyle.Sizes.fontPixelSize * 5
            height: width
            // Drawn at its own 660 px otherwise
            fillMode: VectorImage.PreserveAspectFit
            source: Qt.resolvedUrl("../../../Resources/Logos/EasyShapes.svg")
            preferredRendererType: VectorImage.CurveRenderer
            animations.loops: Animation.Infinite
        }

        EaElements.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: EaStyle.Colors.themeForegroundMinor
            // The structure is read again when the assembly ends
            text: Globals.BackendWrapper.sampleModelFilesLocked
                  ? qsTr("Assembling…") : qsTr("Loading…")
        }
    }

    // What the view can't show, in its middle, and which way to move
    // the slider when the slab is the reason
    EaElements.Label {
        anchors.centerIn: view
        width: Math.min(implicitWidth, view.width - 2 * EaStyle.Sizes.fontPixelSize)
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: Globals.BackendWrapper.structureViewError
               ? EaStyle.Colors.red : EaStyle.Colors.themeForegroundMinor
        // None while the logo shows
        text: Globals.BackendWrapper.sampleModelFilesLocked
              || Globals.BackendWrapper.structureViewLoading
              ? ""
              : !Globals.BackendWrapper.structureViewHasStructure
                ? qsTr("Assemble the model to see its structure")
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
