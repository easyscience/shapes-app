// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import Gui.Globals as Globals


// Component molecules drawn flat on a Canvas, for the Shape views'
// "Molecules" toggle: each molecule lies along its mint->mext vector, the
// mint atom on the arrow start and the mext atom on the tip, with the
// bonds of its topology file, each half in its atom's colour. Also holds
// the CPK table and bond radius the 3D Components viewer (BaseMol3dQuick)
// uses.
QtObject {
    id: sketch

    // Circle radius = atomScale * vdW radius(element), as in the 3D viewer.
    property real atomScale: 0.4
    // Bond radius, Å
    property real bondRadius: 0.15
    // Lets the arrow under a molecule show through.
    property real opacity: 0.85

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

    function info(element) {
        return _cpk[element] !== undefined ? _cpk[element] : { c: "#ff40ff", r: 1.6 }
    }

    // How far component i's molecule reaches past its mint->mext vector,
    // in nm: back behind mint, front past mext, side off the line, atom
    // radii included. All 0 without atoms or a bone. The views fit it.
    function reachOf(components, i) {
        const atoms = Globals.BackendWrapper.componentStructureAtoms(i)
        const row = components.get(i)
        const none = { back: 0, front: 0, side: 0 }
        const n = atoms.length
        if (row.mint === row.mext || row.mint < 0 || row.mext < 0 || row.mint >= n || row.mext >= n)
            return none
        const o = atoms[row.mint], e = atoms[row.mext]
        const bone = Qt.vector3d(e.x - o.x, e.y - o.y, e.z - o.z)
        const len = bone.length()
        if (len < 1e-6)
            return none
        const v = bone.times(1 / len)
        let lo = 0, hi = len, side = 0
        for (const a of atoms) {
            const p = Qt.vector3d(a.x - o.x, a.y - o.y, a.z - o.z)
            const t = p.dotProduct(v)
            lo = Math.min(lo, t)
            hi = Math.max(hi, t)
            side = Math.max(side, p.minus(v.times(t)).length())
        }
        // The largest drawn atom radius, Å
        const pad = atomScale * 2.0
        return { back: (pad - lo) / 10, front: (hi - len + pad) / 10, side: (side + pad) / 10 }
    }

    // The four corners of the box a molecule takes around its vector,
    // from `from` (mint) to `to` (mext), world points in nm; `reach` from
    // reachOf. A vector of no length has none.
    function corners(from, to, reach) {
        const dx = to.x - from.x, dy = to.y - from.y
        const l = Math.hypot(dx, dy)
        if (l < 1e-9)
            return []
        const ux = dx / l, uy = dy / l
        const out = []
        for (const [p, k] of [[from, -reach.back], [to, reach.front]])
            for (const s of [-reach.side, reach.side])
                out.push(Qt.point(p.x + ux * k - uy * s, p.y + uy * k + ux * s))
        return out
    }

    // Draw each vector's component molecule over it. `vectors` holds
    // {compIndex, from, to} with the ends in screen pixels; `scale` is
    // pixels per nm. Reads each component's atoms and bonds once.
    function drawMolecules(ctx, components, vectors, scale) {
        const atomsOf = {}
        const bondsOf = {}
        ctx.save()
        ctx.globalAlpha = opacity
        for (const vec of vectors) {
            const i = vec.compIndex
            if (!(i in atomsOf)) {
                atomsOf[i] = Globals.BackendWrapper.componentStructureAtoms(i)
                bondsOf[i] = Globals.BackendWrapper.componentStructureBonds(i)
            }
            const row = components.get(i)
            _draw(ctx, atomsOf[i], bondsOf[i], row.mint, row.mext, vec.from, vec.to, scale / 10)
        }
        ctx.restore()
    }

    // One molecule, atoms in Å, from screen point `a` (mint) to `b` (mext);
    // bonds as [i, j] atom index pairs.
    function _draw(ctx, atoms, bonds, mint, mext, a, b, pxPerAng) {
        const n = atoms.length
        if (mint === mext || mint < 0 || mext < 0 || mint >= n || mext >= n)
            return
        const o = atoms[mint]
        const e = atoms[mext]
        const v = Qt.vector3d(e.x - o.x, e.y - o.y, e.z - o.z).normalized()
        const len = Math.hypot(b.x - a.x, b.y - a.y)
        if (len < 1e-6)
            return
        // Rotation taking the bone onto the arrow (Rodrigues), in screen
        // axes: x right, y down, z away from the viewer. Bone and arrow
        // opposite: half a turn about any axis normal to the bone.
        const u = Qt.vector3d((b.x - a.x) / len, (b.y - a.y) / len, 0)
        const c = v.dotProduct(u)
        let k = v.crossProduct(u)
        const s = k.length()
        if (s > 1e-6)
            k = k.times(1 / s)
        else if (c < 0)
            k = v.crossProduct(Math.abs(v.x) < 0.9 ? Qt.vector3d(1, 0, 0)
                                                    : Qt.vector3d(0, 1, 0)).normalized()

        const placed = []
        for (let i = 0; i < n; ++i) {
            const p = Qt.vector3d(atoms[i].x - o.x, atoms[i].y - o.y, atoms[i].z - o.z)
            const q = p.times(c).plus(k.crossProduct(p).times(s))
                       .plus(k.times(k.dotProduct(p) * (1 - c)))
            const el = info(atoms[i].element)
            placed.push({ x: a.x + q.x * pxPerAng, y: a.y + q.y * pxPerAng, z: q.z,
                          r: Math.max(0.5, atomScale * el.r * pxPerAng), c: el.c })
        }
        // Each bond as two halves, atom centre to the middle, in the
        // atom's colour; a half lies at the depth of its middle.
        const items = placed.slice()
        for (const [i, j] of bonds) {
            if (i >= n || j >= n)
                continue
            const mid = { x: (placed[i].x + placed[j].x) / 2, y: (placed[i].y + placed[j].y) / 2,
                          z: (placed[i].z + placed[j].z) / 2 }
            for (const p of [placed[i], placed[j]])
                items.push({ from: p, to: mid, z: (p.z + mid.z) / 2, c: p.c })
        }
        const bondWidth = Math.max(0.5, 2 * bondRadius * pxPerAng)
        // Far first, so near ones cover them.
        items.sort((p1, p2) => p2.z - p1.z)
        for (const p of items) {
            ctx.beginPath()
            if (p.from) {
                ctx.moveTo(p.from.x, p.from.y)
                ctx.lineTo(p.to.x, p.to.y)
                ctx.lineWidth = bondWidth
                ctx.strokeStyle = p.c
                ctx.stroke()
                continue
            }
            ctx.arc(p.x, p.y, p.r, 0, 2 * Math.PI)
            ctx.fillStyle = p.c
            ctx.fill()
            ctx.lineWidth = 0.75
            ctx.strokeStyle = Qt.darker(p.c, 1.6)
            ctx.stroke()
        }
    }
}
