// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// Delegates reach this file's ids (root, sketch, camera, view) directly
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick3D

import EasyApplication.Gui.Style as EaStyle


// 3D molecular structure viewer (engine: native Qt Quick 3D, no WebEngine/JS).
//
// App-local for now (kept in shapes-app rather than promoted to EasyApp until
// the design settles). Data-driven: the caller supplies a parsed atom list in
// `atoms` — [{element, x, y, z}] in Ångström, ideally centred on the origin.
// Each atom is drawn as a CPK-coloured sphere sized by its van der Waals radius.
// An optional orientation arrow runs from atom[vectorStart] to atom[vectorEnd].
// Tap an atom to label it (index + element); tap empty space to clear.
// Left-drag to orbit, right-drag to pan, wheel to zoom.
//
// Bonds come from the caller in `bonds` (the component's topology file),
// drawn as thin sticks, each half in its atom's colour; none are guessed
// here.
Rectangle {
    id: root

    // Parsed atoms: [{element: "C", x, y, z}] in Å, centred near the origin.
    property var atoms: []
    // Bonds: [[i, j], ...] 0-based atom indices; pairs past the atoms are
    // skipped.
    property var bonds: []
    property real bondRadius: sketch.bondRadius
    // Sphere radius = atomScale * vdW-radius(element), in scene units (= Å).
    property real atomScale: 0.4
    // Orientation vector: arrow atom[vectorStart] -> atom[vectorEnd] (0-based,
    // clamped). -1 means "no vector".
    property int vectorStart: -1
    property int vectorEnd: -1
    property color vectorColor: EaStyle.Colors.themeForeground
    property real vectorRadius: 0.25
    // The arrow is drawn over the atoms; this lets them show through it.
    property real vectorOpacity: 0.6

    color: EaStyle.Colors.mainContentBackground

    // CPK colours and van der Waals radii (Å), shared with the Shape views.
    MoleculeSketch { id: sketch }

    // --- View framing + derived geometry, recomputed when atoms change -------

    property real _camDist: 600   // camera distance (fits the molecule)
    property real _boundR: 1      // molecule bounding radius (max dist from centre)

    // Orientation arrow, in scene space (local +Y of _arrowNode = direction).
    property bool _hasVector: false
    property vector3d _vecPos: Qt.vector3d(0, 0, 0)
    property quaternion _vecRot: Qt.quaternion(1, 0, 0, 0)
    property real _vecLen: 0

    onAtomsChanged: _recompute()
    onVectorStartChanged: _updateVector()
    onVectorEndChanged: _updateVector()

    function _recompute() {
        let maxR = 1
        for (let i = 0; i < atoms.length; ++i) {
            const a = atoms[i]
            const d = Math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            if (d > maxR)
                maxR = d
        }
        _boundR = maxR
        _fitMolecule()
        _updateVector()
    }

    // Zoom so the molecule (bounding sphere, radius _boundR) fills 0.9 of the
    // view. With a horizontal FOV the visible width is 2*dist*tan(fov/2) and the
    // visible height is that / aspect, so fit to whichever is smaller.
    function _fitMolecule() {
        if (typeof camera === "undefined" || view.height <= 0)
            return
        const aspect = view.width / view.height
        const halfTan = Math.tan(camera.fieldOfView * Math.PI / 180 / 2)
        _camDist = _boundR * Math.max(1, aspect) / (0.9 * halfTan)
    }

    // Quaternion rotating local +Y onto direction `d`.
    function _quatFromY(d) {
        const up = Qt.vector3d(0, 1, 0)
        const n = d.normalized()
        const c = Math.max(-1, Math.min(1, up.dotProduct(n)))
        if (c > 0.99999)
            return Qt.quaternion(1, 0, 0, 0)
        if (c < -0.99999)
            return Qt.quaternion(0, 0, 0, 1) // 180° about Z
        const axis = up.crossProduct(n).normalized()
        const ang = Math.acos(c)
        const s = Math.sin(ang / 2)
        return Qt.quaternion(Math.cos(ang / 2), axis.x * s, axis.y * s, axis.z * s)
    }

    // Quaternion from an orthonormal basis given as the world directions of the
    // local +X, +Y, +Z axes (columns of the rotation matrix).
    function _matToQuat(cx, cy, cz) {
        const m00 = cx.x, m10 = cx.y, m20 = cx.z
        const m01 = cy.x, m11 = cy.y, m21 = cy.z
        const m02 = cz.x, m12 = cz.y, m22 = cz.z
        const tr = m00 + m11 + m22
        let w, x, y, z, s
        if (tr > 0) {
            s = Math.sqrt(tr + 1.0) * 2
            w = 0.25 * s; x = (m21 - m12) / s; y = (m02 - m20) / s; z = (m10 - m01) / s
        } else if (m00 > m11 && m00 > m22) {
            s = Math.sqrt(1.0 + m00 - m11 - m22) * 2
            w = (m21 - m12) / s; x = 0.25 * s; y = (m01 + m10) / s; z = (m02 + m20) / s
        } else if (m11 > m22) {
            s = Math.sqrt(1.0 + m11 - m00 - m22) * 2
            w = (m02 - m20) / s; x = (m01 + m10) / s; y = 0.25 * s; z = (m12 + m21) / s
        } else {
            s = Math.sqrt(1.0 + m22 - m00 - m11) * 2
            w = (m10 - m01) / s; x = (m02 + m20) / s; y = (m12 + m21) / s; z = 0.25 * s
        }
        return Qt.quaternion(w, x, y, z)
    }

    // Camera rotation that frames the vector `dir` side-on (forward ⟂ dir, so it
    // shows full length), running left->right (mint->mext) and tilted 30° up.
    function _viewRotForVector(dir) {
        const d = dir.normalized()
        let a = Qt.vector3d(0, 0, 1)
        if (Math.abs(d.dotProduct(a)) > 0.9)
            a = Qt.vector3d(0, 1, 0)
        const f = d.crossProduct(a).normalized()   // look axis, ⟂ dir
        const p = f.crossProduct(d).normalized()   // in-plane axis ⟂ dir
        const th = 30 * Math.PI / 180
        const r = d.times(Math.cos(th)).minus(p.times(Math.sin(th)))   // screen right
        const u = d.times(Math.sin(th)).plus(p.times(Math.cos(th)))    // screen up
        const z = r.crossProduct(u).normalized()                       // local +Z
        return _matToQuat(r, u, z)
    }

    function _updateVector() {
        _hasVector = false
        const n = atoms.length
        if (n === 0 || vectorStart < 0 || vectorEnd < 0)
            return
        const si = Math.max(0, Math.min(vectorStart, n - 1))
        const ei = Math.max(0, Math.min(vectorEnd, n - 1))
        if (si === ei)
            return
        const s = Qt.vector3d(atoms[si].x, atoms[si].y, atoms[si].z)
        const e = Qt.vector3d(atoms[ei].x, atoms[ei].y, atoms[ei].z)
        const dir = e.minus(s)
        _vecLen = dir.length()
        _vecPos = s
        _vecRot = _quatFromY(dir)
        _hasVector = _vecLen > 0
        // Initial view: vector side-on, running left->right (mint->mext) and
        // tilted 30° up. The user can orbit away after.
        if (_hasVector && typeof originNode !== "undefined")
            originNode.rotation = _viewRotForVector(dir)
    }

    // --- Atom labels ---------------------------------------------------------
    // Hover shows a transient label at the cursor; clicking an atom pins its
    // label so it stays, and pinned labels follow the atom as the view rotates.

    property int _hoverIndex: -1
    property real _hoverX: 0
    property real _hoverY: 0
    property int _pinnedIndex: -1   // single clicked atom label (-1 = none)

    function _elementAt(i) {
        return (i >= 0 && i < atoms.length) ? atoms[i].element : ""
    }

    // Always-on labels for the mint/mext atoms (the vector endpoints), using the
    // same clamped indices as the orientation arrow.
    readonly property var _markers: {
        const n = atoms.length
        const out = []
        if (n > 0 && vectorStart >= 0)
            out.push({ i: Math.max(0, Math.min(vectorStart, n - 1)), tag: "mint" })
        if (n > 0 && vectorEnd >= 0)
            out.push({ i: Math.max(0, Math.min(vectorEnd, n - 1)), tag: "mext" })
        return out
    }

    View3D {
        id: view
        anchors.fill: parent
        camera: camera

        // Keep the 0.9 molecule fit correct when the viewport is resized.
        onWidthChanged: root._fitMolecule()
        onHeightChanged: root._fitMolecule()

        environment: SceneEnvironment {
            clearColor: root.color
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        // Camera orbits this node (kept at the origin = molecule centroid).
        Node {
            id: originNode
            PerspectiveCamera {
                id: camera
                z: root._camDist
                clipFar: 100000
                // Horizontal FOV so the visible world-width at the molecule is
                // 2*dist*tan(fov/2), independent of the viewport aspect — this
                // lets us zoom so the vector length matches the view width.
                fieldOfViewOrientation: PerspectiveCamera.Horizontal

                // One light from the screen, lifted 15° so it falls from
                // slightly above. A child of the camera, so it stays fixed
                // to the view while the molecule turns.
                DirectionalLight { eulerRotation.x: -15; brightness: 1.0 }
            }
        }

        // Atoms.
        Node {
            id: moleculeNode
            Repeater3D {
                model: root.atoms
                delegate: Model {
                    id: atom
                    required property int index
                    required property var modelData
                    readonly property var info: sketch.info(modelData.element)
                    property int atomIndex: index
                    property string element: modelData.element
                    source: "#Sphere"
                    pickable: true
                    position: Qt.vector3d(modelData.x, modelData.y, modelData.z)
                    // #Sphere built-in mesh has radius 50 units → scale = R/50.
                    scale: {
                        const s = root.atomScale * info.r / 50
                        return Qt.vector3d(s, s, s)
                    }
                    materials: PrincipledMaterial {
                        baseColor: atom.info.c
                        roughness: 0.45
                        // 0.15 ambient floor: Qt Quick 3D has no global ambient
                        // term (that needs an IBL probe), so add a 15% self-lit
                        // emissive in the atom's own colour instead.
                        property color _base: atom.info.c
                        emissiveFactor: Qt.vector3d(_base.r * 0.15, _base.g * 0.15, _base.b * 0.15)
                    }
                }
            }

            // Bonds: a thin cylinder from atom centre to atom centre, each
            // half in its atom's colour, lit like the atoms; not pickable,
            // so hover and tap find atoms.
            Repeater3D {
                model: root.bonds.filter(pair => pair[0] < root.atoms.length
                                                 && pair[1] < root.atoms.length)
                delegate: Node {
                    id: bond
                    required property var modelData
                    readonly property var a: root.atoms[modelData[0]]
                    readonly property var b: root.atoms[modelData[1]]
                    readonly property vector3d dir: Qt.vector3d(b.x - a.x, b.y - a.y, b.z - a.z)
                    position: Qt.vector3d((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2)
                    // Local +Y runs from a to b
                    rotation: root._quatFromY(dir)

                    // -1: the half at a, 1: the half at b
                    Repeater3D {
                        model: [-1, 1]
                        delegate: Model {
                            id: half
                            required property var modelData
                            readonly property color colour: sketch.info(
                                (modelData < 0 ? bond.a : bond.b).element).c
                            source: "#Cylinder"
                            y: modelData * bond.dir.length() / 4
                            // #Cylinder is 100 units across and 100 tall,
                            // along +Y
                            scale: Qt.vector3d(root.bondRadius / 50, bond.dir.length() / 200,
                                               root.bondRadius / 50)
                            materials: PrincipledMaterial {
                                baseColor: half.colour
                                roughness: 0.45
                                emissiveFactor: Qt.vector3d(half.colour.r * 0.15,
                                                            half.colour.g * 0.15,
                                                            half.colour.b * 0.15)
                            }
                        }
                    }
                }
            }
        }

        // Hover an atom to show a transient label at the cursor.
        HoverHandler {
            id: hoverHandler
            acceptedDevices: PointerDevice.Mouse
            onPointChanged: {
                if (!hovered) {
                    root._hoverIndex = -1
                    return
                }
                const p = point.position
                const res = view.pick(p.x, p.y)
                root._hoverIndex = (res.objectHit && res.objectHit.atomIndex !== undefined)
                                   ? res.objectHit.atomIndex : -1
                root._hoverX = p.x
                root._hoverY = p.y
            }
            onHoveredChanged: if (!hovered) root._hoverIndex = -1
        }

        // Click an atom to pin its label (only one at a time — replaces any
        // previous; clicking the same one unpins it). Clicking empty space
        // clears it. The mint/mext labels are separate and always shown.
        TapHandler {
            onTapped: function (eventPoint) {
                const p = eventPoint.position
                const res = view.pick(p.x, p.y)
                if (res.objectHit && res.objectHit.atomIndex !== undefined) {
                    const idx = res.objectHit.atomIndex
                    root._pinnedIndex = (root._pinnedIndex === idx) ? -1 : idx
                } else {
                    root._pinnedIndex = -1
                }
            }
        }

    }

    // The arrow over the atoms: a transparent view of its own on top, its
    // camera following the main one, so no atom hides the arrow. Takes no
    // input; the main view's handlers below still get it.
    View3D {
        anchors.fill: view
        camera: arrowCamera

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        PerspectiveCamera {
            id: arrowCamera
            position: camera.scenePosition
            rotation: camera.sceneRotation
            fieldOfView: camera.fieldOfView
            fieldOfViewOrientation: camera.fieldOfViewOrientation
            clipNear: camera.clipNear
            clipFar: camera.clipFar
        }

        // Orientation arrow atom[vectorStart] -> atom[vectorEnd]: shaft + tip,
        // built along local +Y then placed/rotated onto the vector.
        Node {
            id: arrowNode
            visible: root._hasVector
            opacity: root.vectorOpacity
            position: root._vecPos
            rotation: root._vecRot

            // The tip keeps one size: 80% of what it has on POPC's 0 -> 130
            // vector (25.6 Å long, tip 0.0675 of it), so only the shaft
            // follows the vector's length and a short vector's tip isn't
            // squashed. The cone apex lands on the mext atom centre (total
            // length == _vecLen); the shaft runs further into the tip by
            // 0.5x the tip length so the rod reaches deeper towards mext.
            readonly property real tipLen: 25.6 * 0.0675 * 0.8
            readonly property real tipRadius: root.vectorRadius * 2.4 * 0.8

            Model { // shaft
                source: "#Cylinder"
                readonly property real len: Math.max(0, root._vecLen - arrowNode.tipLen * 0.5)
                position: Qt.vector3d(0, len / 2, 0)
                // Shaft radius halved (vectorRadius / 2).
                scale: Qt.vector3d(root.vectorRadius / 100, len / 100, root.vectorRadius / 100)
                // Unlit/flat so the arrow reads as an annotation, not a shaded
                // atom (it can otherwise be mistaken for an orange/yellow atom).
                materials: PrincipledMaterial {
                    baseColor: root.vectorColor
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            Model { // tip cone
                source: "#Cone"
                readonly property real len: arrowNode.tipLen
                // Elongated 3x; shifted towards mint by one pre-elongation
                // length (= tipLen / 3).
                position: Qt.vector3d(0, root._vecLen - len / 2 - arrowNode.tipLen / 3, 0)
                scale: Qt.vector3d(arrowNode.tipRadius / 50, len / 100, arrowNode.tipRadius / 50)
                materials: PrincipledMaterial {
                    baseColor: root.vectorColor
                    lighting: PrincipledMaterial.NoLighting
                }
            }
        }
    }

    // Left-drag turns, right-drag pans, the wheel zooms the camera distance
    // (camera.z is bound to it).
    TrackballControl {
        anchors.fill: view
        origin: originNode
        camera: camera
        onZoomed: (factor) => root._camDist = Math.max(2, root._camDist * factor)
    }

    // Single clicked-atom label, projected so it follows the molecule as it
    // rotates/zooms/pans. Referencing camera.scenePosition makes the projection
    // re-evaluate whenever the view changes.
    Rectangle {
        id: pin
        readonly property vector3d _atomPos: {
            const a = root.atoms[root._pinnedIndex]
            return a ? Qt.vector3d(a.x, a.y, a.z) : Qt.vector3d(0, 0, 0)
        }
        readonly property vector3d _screen: {
            const _ = camera.scenePosition   // dependency: re-project on view change
            if (root._pinnedIndex < 0)
                return Qt.vector3d(0, 0, -1)   // nothing pinned: skip projection
            return view.mapFrom3DScene(_atomPos)
        }
        visible: root._pinnedIndex >= 0 && _screen.z > 0
        x: Math.round(_screen.x) + 8
        y: Math.round(_screen.y) + 8
        width: pinText.implicitWidth + 10
        height: pinText.implicitHeight + 6
        radius: 3
        color: EaStyle.Colors.themeBackground
        Text {
            id: pinText
            anchors.centerIn: parent
            color: EaStyle.Colors.themeForeground
            font.pixelSize: 12
            text: root._pinnedIndex + " (" + root._elementAt(root._pinnedIndex) + ")"
        }
    }

    // Always-on labels for the mint/mext atoms, projected so they follow the
    // molecule as it rotates/zooms/pans (gold to match the arrow).
    Repeater {
        model: root._markers
        delegate: Rectangle {
            id: marker
            required property var modelData
            readonly property vector3d _atomPos: {
                const a = root.atoms[modelData.i]
                return a ? Qt.vector3d(a.x, a.y, a.z) : Qt.vector3d(0, 0, 0)
            }
            readonly property vector3d _screen: {
                const _ = camera.scenePosition   // dependency: re-project on view change
                return view.mapFrom3DScene(_atomPos)
            }
            visible: _screen.z > 0
            x: Math.round(_screen.x) + 8
            y: Math.round(_screen.y) + 8
            width: markerText.implicitWidth + 10
            height: markerText.implicitHeight + 6
            radius: 3
            color: EaStyle.Colors.themeBackground
            Text {
                id: markerText
                anchors.centerIn: parent
                color: EaStyle.Colors.themeForeground
                font.pixelSize: 12
                text: marker.modelData.tag + " " + marker.modelData.i
                      + " (" + root._elementAt(marker.modelData.i) + ")"
            }
        }
    }

    // Transient label for the atom currently under the cursor.
    Rectangle {
        visible: root._hoverIndex >= 0
        x: Math.round(root._hoverX) + 8
        y: Math.round(root._hoverY) + 8
        width: hoverText.implicitWidth + 10
        height: hoverText.implicitHeight + 6
        radius: 3
        color: EaStyle.Colors.themeBackground
        Text {
            id: hoverText
            anchors.centerIn: parent
            color: EaStyle.Colors.themeForeground
            font.pixelSize: 12
            text: root._hoverIndex + " (" + root._elementAt(root._hoverIndex) + ")"
        }
    }

}
