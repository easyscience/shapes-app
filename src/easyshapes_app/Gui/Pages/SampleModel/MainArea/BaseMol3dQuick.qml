// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

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
// Bonds (sticks) are not drawn yet — atoms only for now.
Rectangle {
    id: root

    // Parsed atoms: [{element: "C", x, y, z}] in Å, centred near the origin.
    property var atoms: []
    // Sphere radius = atomScale * vdW-radius(element), in scene units (= Å).
    property real atomScale: 0.4
    // Orientation vector: arrow atom[vectorStart] -> atom[vectorEnd] (0-based,
    // clamped). -1 means "no vector".
    property int vectorStart: -1
    property int vectorEnd: -1
    property color vectorColor: EaStyle.Colors.themeForeground
    property real vectorRadius: 0.25
    // Right-button pan sensitivity multiplier (1.0 = baseline).
    property real panSpeed: 2.0
    // Left-drag rotation sensitivity, in degrees per pixel (trackball).
    property real rotateSpeed: 0.6

    color: EaStyle.Colors.mainContentBackground

    // CPK-ish colours and van der Waals radii (Å) for the common elements;
    // anything else falls back to magenta / 1.6 Å so it stays visible.
    readonly property var _cpk: ({
        "H":  { c: "#ffffff", r: 1.20 },
        "C":  { c: "#909090", r: 1.70 },
        "N":  { c: "#3050f8", r: 1.55 },
        "O":  { c: "#ff0d0d", r: 1.52 },
        "P":  { c: "#ff8000", r: 1.80 },
        "S":  { c: "#ffff30", r: 1.80 },
        "F":  { c: "#90e050", r: 1.47 },
        "Cl": { c: "#1ff01f", r: 1.75 },
        "Br": { c: "#a62929", r: 1.85 },
        "Na": { c: "#ab5cf2", r: 2.27 },
        "K":  { c: "#8f40d4", r: 2.75 },
        "Ca": { c: "#3dff00", r: 2.31 },
        "Mg": { c: "#8aff00", r: 1.73 }
    })

    function _info(element) {
        return _cpk[element] !== undefined ? _cpk[element] : { c: "#ff40ff", r: 1.6 }
    }

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

    // Quaternion for a rotation of `deg` degrees about world axis `axis`.
    function _axisAngle(axis, deg) {
        const a = axis.normalized()
        const r = deg * Math.PI / 180
        const s = Math.sin(r / 2)
        return Qt.quaternion(Math.cos(r / 2), a.x * s, a.y * s, a.z * s)
    }

    // Hamilton product a * b (applies b, then a).
    function _qmul(a, b) {
        return Qt.quaternion(
            a.scalar * b.scalar - a.x * b.x - a.y * b.y - a.z * b.z,
            a.scalar * b.x + a.x * b.scalar + a.y * b.z - a.z * b.y,
            a.scalar * b.y - a.x * b.z + a.y * b.scalar + a.z * b.x,
            a.scalar * b.z + a.x * b.y - a.y * b.x + a.z * b.scalar)
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
            }
        }

        // Three lights spread over the sphere: azimuths ~120° apart AND
        // different elevations, so they don't share one plane (which produced
        // the "melon" banding). Tune the angles to taste.
        DirectionalLight { eulerRotation.x: -25; eulerRotation.y: -70; brightness: 0.6 }
        DirectionalLight { eulerRotation.x: 30; eulerRotation.y: 50; brightness: 0.4 }
        DirectionalLight { eulerRotation.x: -55; eulerRotation.y: 170; brightness: 0.2 }

        // Atoms.
        Node {
            id: moleculeNode
            Repeater3D {
                model: root.atoms
                delegate: Model {
                    required property int index
                    required property var modelData
                    readonly property var info: root._info(modelData.element)
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
                        baseColor: info.c
                        roughness: 0.45
                        // 0.15 ambient floor: Qt Quick 3D has no global ambient
                        // term (that needs an IBL probe), so add a 15% self-lit
                        // emissive in the atom's own colour instead.
                        property color _base: info.c
                        emissiveFactor: Qt.vector3d(_base.r * 0.15, _base.g * 0.15, _base.b * 0.15)
                    }
                }
            }
        }

        // Orientation arrow atom[vectorStart] -> atom[vectorEnd]: shaft + tip,
        // built along local +Y then placed/rotated onto the vector.
        Node {
            id: arrowNode
            visible: root._hasVector
            position: root._vecPos
            rotation: root._vecRot

            // Tip length as a fraction of the whole vector (0.3x the previous
            // 0.075). The cone apex lands on the mext atom centre (total length
            // == _vecLen); the shaft runs further into the tip by 0.5x the tip
            // length so the rod reaches deeper towards mext.
            readonly property real tipLen: root._vecLen * 0.0675

            Model { // shaft
                source: "#Cylinder"
                readonly property real len: root._vecLen - arrowNode.tipLen * 0.5
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
                scale: Qt.vector3d(root.vectorRadius * 2.4 / 50, len / 100, root.vectorRadius * 2.4 / 50)
                materials: PrincipledMaterial {
                    baseColor: root.vectorColor
                    lighting: PrincipledMaterial.NoLighting
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

        // Left-drag trackball rotation. Each mouse delta rotates about the
        // CURRENT screen axes (camera right/up, read as world-space basis from
        // originNode) and is composed onto the current rotation. Because the
        // axes always follow the view, left-right stays consistent at any
        // orientation — no gimbal flip when tumbling past the poles.
        DragHandler {
            target: null
            acceptedButtons: Qt.LeftButton
            property real _lx: 0
            property real _ly: 0
            onActiveChanged: { _lx = 0; _ly = 0 }
            onTranslationChanged: {
                const dx = translation.x - _lx
                const dy = translation.y - _ly
                _lx = translation.x
                _ly = translation.y
                const qYaw = root._axisAngle(originNode.up, -dx * root.rotateSpeed)
                const qPitch = root._axisAngle(originNode.right, -dy * root.rotateSpeed)
                const dq = root._qmul(qYaw, qPitch)
                originNode.rotation = root._qmul(dq, originNode.rotation)
            }
        }

        // Right-drag pan (panSpeed x baseline): move the rig in the view plane.
        DragHandler {
            target: null
            acceptedButtons: Qt.RightButton
            property real _lx: 0
            property real _ly: 0
            onActiveChanged: { _lx = 0; _ly = 0 }
            onTranslationChanged: {
                const dx = translation.x - _lx
                const dy = translation.y - _ly
                _lx = translation.x
                _ly = translation.y
                const k = root._camDist * 0.0022 * root.panSpeed
                originNode.position = originNode.position
                    .minus(originNode.right.times(dx * k))
                    .plus(originNode.up.times(dy * k))
            }
        }

        // Wheel zoom: change the camera distance (camera.z is bound to it).
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: function (ev) {
                const factor = ev.angleDelta.y > 0 ? 0.9 : 1.1
                root._camDist = Math.max(2, root._camDist * factor)
            }
        }
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
