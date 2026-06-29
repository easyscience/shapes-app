// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

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
    property color vectorColor: "magenta"
    property real vectorRadius: 0.25
    // Right-button pan sensitivity multiplier (1.0 = baseline).
    property real panSpeed: 2.0

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
        _camDist = maxR * 2.4 + 8
        _updateVector()
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
    }

    // --- Tap-to-label state --------------------------------------------------

    property int _pickedIndex: -1
    property string _pickedElement: ""
    property real _labelX: 0
    property real _labelY: 0

    View3D {
        id: view
        anchors.fill: parent

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
            }
        }

        DirectionalLight { eulerRotation.x: -30; eulerRotation.y: -70 }
        DirectionalLight { eulerRotation.x: -110; eulerRotation.y: 60; brightness: 0.6 }

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

            Model { // shaft
                source: "#Cylinder"
                readonly property real len: root._vecLen * 0.85
                position: Qt.vector3d(0, len / 2, 0)
                scale: Qt.vector3d(root.vectorRadius / 50, len / 100, root.vectorRadius / 50)
                materials: PrincipledMaterial { baseColor: root.vectorColor }
            }
            Model { // tip cone
                source: "#Cone"
                readonly property real len: root._vecLen * 0.15
                position: Qt.vector3d(0, root._vecLen * 0.85 + len / 2, 0)
                scale: Qt.vector3d(root.vectorRadius * 2.4 / 50, len / 100, root.vectorRadius * 2.4 / 50)
                materials: PrincipledMaterial { baseColor: root.vectorColor }
            }
        }

        // Tap an atom to label it; tap empty space to clear. TapHandler only
        // fires on a tap (not a drag), so it coexists with the orbit controller.
        TapHandler {
            onTapped: function (eventPoint) {
                const p = eventPoint.position
                const res = view.pick(p.x, p.y)
                if (res.objectHit && res.objectHit.atomIndex !== undefined) {
                    root._pickedIndex = res.objectHit.atomIndex
                    root._pickedElement = res.objectHit.element
                    root._labelX = p.x
                    root._labelY = p.y
                } else {
                    root._pickedIndex = -1
                }
            }
        }
    }

    // Left-drag to orbit, wheel to zoom. Pan is handled separately below so its
    // sensitivity can be tuned, so the controller's own pan is disabled.
    OrbitCameraController {
        id: orbit
        anchors.fill: view
        origin: originNode
        camera: camera
        panEnabled: false

        // Right-button pan, `panSpeed`x more responsive than the baseline.
        // Moves the orbit origin in the camera's view plane (Node.right/up are
        // world-space basis vectors), scaled by distance so it feels constant.
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
    }

    // 2D label for the tapped atom.
    Rectangle {
        visible: root._pickedIndex >= 0
        x: Math.round(root._labelX) + 8
        y: Math.round(root._labelY) + 8
        width: pickedLabel.implicitWidth + 10
        height: pickedLabel.implicitHeight + 6
        radius: 3
        color: "#cc000000"
        Text {
            id: pickedLabel
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 12
            text: root._pickedIndex + " (" + root._pickedElement + ")"
        }
    }

}
