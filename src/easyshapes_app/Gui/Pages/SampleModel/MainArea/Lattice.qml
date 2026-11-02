// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick3D

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: the lattice, one simple 3D shape per node standing in
// for the unit structure. Shown only for the Lattice type.
//
// Follows the library's Lattice.make (shapes.designs.protolattice):
//   - Nodes in cell units: CUB cell corners; BCC adds the body centre, FCC
//     three face centres; HCP stacks hexagonal AB layers, 2 x 2 x 2 nodes
//     a cell. A node is kept while every coordinate is below Nlat.
//   - A cell side, per axis, is (unit size + Sbuff) times 1 (CUB, HCP),
//     2/sqrt(3) (BCC) or sqrt(2) (FCC).
//   - Alpha and Theta turn each unit so its Z axis points along
//     (cos a cos t, sin a cos t, sin t); both 0 turn nothing. The library
//     turns the line from the unit's lowest atom to its highest; plain Z
//     here.
// Unit shapes are typical, not worked out from the structure: they show
// what the lattice holds, not its exact size (nm):
//   Ring:                disc in XY, radius 3, 1 thick.
//   Ball, Vesicle:       sphere, radius 3.
//   Rod:                 pill along Z, radius 1.5, body 3.2 long.
//   Bilayer, Monolayer:  box 6 x 6, 2 thick (one side a third).
// The library's Z is up on screen. Scene units are 100 per nm, so a
// built-in mesh (100 units across) takes its size in nm as its scale.
Rectangle {
    id: root

    // Same colour as the Shape views' lines
    property color unitColor: EaStyle.Colors.themeForegroundDisabled

    color: EaStyle.Colors.mainContentBackground

    // The unit's typical shape and size in nm (see the header); null for
    // a shape with no lattice view.
    readonly property var _unit: ({
        Ring: { kind: "disc", r: 3, h: 1 },
        Ball: { kind: "sphere", r: 3 },
        Vesicle: { kind: "sphere", r: 3 },
        Rod: { kind: "rod", r: 1.5, h: 3.2 },
        Bilayer: { kind: "box", side: 6, h: 2 },
        Monolayer: { kind: "box", side: 6, h: 2 }
    })[Globals.BackendWrapper.sampleModelShape] ?? null

    // The unit's size per axis, which the cell is built from.
    readonly property var _extent: {
        const u = _unit
        if (!u)
            return null
        switch (u.kind) {
        case "disc": return [2 * u.r, 2 * u.r, u.h]
        case "rod": return [2 * u.r, 2 * u.r, u.h + 2 * u.r]
        case "box": return [u.side, u.side, u.h]
        }
        return [2 * u.r, 2 * u.r, 2 * u.r]
    }

    // Unit centres in scene units, centred on the lattice, and the radius
    // (nm) that holds every unit.
    readonly property var _layout: {
        const ext = _extent
        if (!ext)
            return { positions: [], radius: 1 }
        const W = Globals.BackendWrapper
        const type = W.latticeStructureLatticeType
        const factor = { LBCC: 2 / Math.sqrt(3), LFCC: Math.SQRT2 }[type] || 1
        const cell = ext.map(e => (e + W.latticeStructureSbuff) * factor)
        const nodes = _nodes(type, Math.max(1, W.latticeStructureNlatx),
                             Math.max(1, W.latticeStructureNlaty),
                             Math.max(1, W.latticeStructureNlatz))
            .map(node => node.map((c, a) => c * cell[a]))
        const lo = [Infinity, Infinity, Infinity]
        const hi = [-Infinity, -Infinity, -Infinity]
        for (const p of nodes)
            for (let a = 0; a < 3; ++a) {
                lo[a] = Math.min(lo[a], p[a])
                hi[a] = Math.max(hi[a], p[a])
            }
        const mid = lo.map((l, a) => (l + hi[a]) / 2)
        let radius = 0
        const positions = nodes.map(p => {
            const q = p.map((c, a) => c - mid[a])
            radius = Math.max(radius, Math.hypot(q[0], q[1], q[2]))
            return Qt.vector3d(q[0] * 100, q[1] * 100, q[2] * 100)
        })
        return { positions: positions, radius: radius + Math.hypot(ext[0], ext[1], ext[2]) / 2 }
    }

    // Node coordinates in cell units, as Lattice.make keeps them; the
    // HCP sums keep the library's order so the Nlat cut matches.
    function _nodes(type, nx, ny, nz) {
        const n = Math.max(nx, ny, nz)
        const out = []
        if (type === "LHCP") {
            const s3o2 = Math.sqrt(3) / 2
            const s2o3 = Math.sqrt(2 / 3)
            for (let i = 0; i < 2 * n; ++i)
                for (let j = 0; j < 2 * n; ++j)
                    for (let k = 0; k < 2 * n; ++k) {
                        const p = [i + ((j + k) % 2) * 0.5, (j + (k % 2) / 3) * s3o2, k * s2o3]
                        if (p[0] * 0.5 < nx && p[1] * (0.5 / s3o2) < ny && p[2] * (0.5 / s2o3) < nz)
                            out.push(p)
                    }
            return out
        }
        // Cell corners, then the type's extra nodes in each cell
        const shifts = [[0, 0, 0]].concat({
            LBCC: [[0.5, 0.5, 0.5]],
            LFCC: [[0, 0.5, 0.5], [0.5, 0.5, 0], [0.5, 0, 0.5]]
        }[type] || [])
        for (const s of shifts)
            for (let i = 0; i < n; ++i)
                for (let j = 0; j < n; ++j)
                    for (let k = 0; k < n; ++k)
                        if (i + s[0] < nx && j + s[1] < ny && k + s[2] < nz)
                            out.push([i + s[0], j + s[1], k + s[2]])
        return out
    }

    // Turns the unit's Z onto the Alpha/Theta direction (see the header).
    readonly property quaternion _unitRotation: {
        const W = Globals.BackendWrapper
        if (W.latticeStructureAlpha === 0 && W.latticeStructureTheta === 0)
            return Qt.quaternion(1, 0, 0, 0)
        const a = W.latticeStructureAlpha * Math.PI / 180
        const t = W.latticeStructureTheta * Math.PI / 180
        const d = Qt.vector3d(Math.cos(a) * Math.cos(t), Math.sin(a) * Math.cos(t), Math.sin(t))
        const c = d.z
        if (c < -0.99999)
            return Qt.quaternion(0, 1, 0, 0)   // half a turn about X
        // Half-angle form of the shortest turn from Z to d
        return Qt.quaternion(1 + c, -d.y, d.x, 0).normalized()
    }

    readonly property string _bodySource: !_unit ? ""
                                          : _unit.kind === "sphere" ? "#Sphere"
                                          : _unit.kind === "box" ? "#Cube"
                                          : "#Cylinder"

    readonly property vector3d _bodyScale: {
        const u = _unit
        if (!u)
            return Qt.vector3d(1, 1, 1)
        switch (u.kind) {
        case "sphere": return Qt.vector3d(2 * u.r, 2 * u.r, 2 * u.r)
        case "box": return Qt.vector3d(u.side, u.side, u.h)
        // The built-in sphere's flat faces lie up to ~2% inside its
        // radius: a body 1% thinner hides most of them; 3% showed a
        // step
        case "rod": return Qt.vector3d(2 * u.r * 0.99, u.h, 2 * u.r * 0.99)
        }
        // A cylinder's axis is its local Y, turned onto Z below
        return Qt.vector3d(2 * u.r, u.h, 2 * u.r)
    }

    // Fits the lattice in the shorter side of the view (60° vertical FOV).
    readonly property real _camDist: _layout.radius * 100 / Math.tan(Math.PI / 6) * 1.2
                                     * Math.max(1, height / Math.max(width, 1))
    // The wheel's zoom on top of the fit
    property real _zoom: 1

    View3D {
        id: view
        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            clearColor: root.color
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        // Camera orbits this node, at the lattice centre.
        Node {
            id: originNode
            eulerRotation: Qt.vector3d(-20, 30, 0)
            PerspectiveCamera {
                id: camera
                z: root._camDist * root._zoom
                clipNear: 1
                clipFar: root._camDist * 10

                // As in the Components viewer: one light from the screen,
                // lifted 15°, fixed to the view.
                DirectionalLight { eulerRotation.x: -15; brightness: 1.0 }
            }
        }

        // The library's axes, Z turned up on screen.
        Node {
            eulerRotation.x: -90

            PrincipledMaterial {
                id: unitMaterial
                baseColor: root.unitColor
                roughness: 0.45
                // 15% self-lit floor, as in the Components viewer
                emissiveFactor: Qt.vector3d(root.unitColor.r * 0.15, root.unitColor.g * 0.15,
                                            root.unitColor.b * 0.15)
            }

            Repeater3D {
                model: root._layout.positions
                delegate: Node {
                    required property var modelData
                    position: modelData
                    rotation: root._unitRotation

                    // Sphere, disc, box or the rod's body
                    Model {
                        source: root._bodySource
                        scale: root._bodyScale
                        eulerRotation.x: root._bodySource === "#Cylinder" ? 90 : 0
                        materials: unitMaterial
                    }
                    // The rod's caps, at the body's ends
                    Repeater3D {
                        model: root._unit && root._unit.kind === "rod" ? [-1, 1] : []
                        delegate: Model {
                            required property var modelData
                            source: "#Sphere"
                            z: modelData * root._unit.h * 50
                            scale: Qt.vector3d(2 * root._unit.r, 2 * root._unit.r,
                                               2 * root._unit.r)
                            materials: unitMaterial
                        }
                    }
                }
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

    // Bottom left, as the Structure tab's atom count
    EaElements.Label {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: EaStyle.Sizes.fontPixelSize
        visible: root._unit !== null
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("%1 · %2 × %3 × %4 cells · %5 units")
              .arg(Globals.BackendWrapper.latticeStructureLatticeType)
              .arg(Globals.BackendWrapper.latticeStructureNlatx)
              .arg(Globals.BackendWrapper.latticeStructureNlaty)
              .arg(Globals.BackendWrapper.latticeStructureNlatz)
              .arg(root._layout.positions.length)
    }

    // Empty state.
    EaElements.Label {
        anchors.centerIn: parent
        visible: root._unit === null
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("No lattice view for the %1 structure.")
              .arg(Globals.BackendWrapper.sampleModelShape)
    }
}
