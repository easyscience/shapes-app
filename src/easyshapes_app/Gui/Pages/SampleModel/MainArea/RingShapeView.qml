// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQml

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Shape view for ring-based structures. A simple 2D schematic focused on the
// per-component mint -> mext orientation vectors laid out along curved baselines.
//
// It draws one OR MORE concentric rings, all sharing the same centre:
//   - Ring structure: a single ring from `dmin` / `rmin` / `rev`.
//   - Ball structure: one ring per layer (the `layers` model). Each layer has
//     its own dmin / rmin, so the rings are concentric arcs at growing radii.
//     Layers alternate orientation: counting from 1, even-numbered layers
//     (2, 4, ...) are reversed by default; `rev` flips the parity.
//
// Layout rules per ring:
//   - N loaded components produce N+1 vectors. The first component owns TWO
//     vectors (one at each end of the baseline); every other component owns one.
//     Slot k (k = 0..N) belongs to component (k % N).
//   - Consecutive vectors are spaced by `dmin` along the baseline arc:
//         comp1 _dmin_ comp2 _dmin_ ... _dmin_ compN _dmin_ comp1
//   - The baseline is an arc of radius `rmin`. It starts 0.5*dmin before the
//     first vector and ends 0.5*dmin after the last, so its arc length is
//     (N+1)*dmin.
//   - Each vector is radial (perpendicular to the baseline). If NOT reversed,
//     the mint end is tied to the baseline and the arrow points outward (mext
//     outer). If reversed, the mext end is tied to the baseline and the arrow
//     points inward toward it (mint outer).
//   - The drawn length of each vector is the real molecular mint->mext distance:
//     |atom[mext] - atom[mint]| in Ångström, converted to nm and shrunk by
//     `lengthDivisor`. mint/mext are atom indices into the component's structure.
Item {
    id: root

    property var components: Globals.BackendWrapper.componentsLoaded

    // Single-ring parameters (used when `layers` is not set).
    property real dmin: 0.5
    property real rmin: 0.25
    property bool rev: false

    // Optional layers model (ListModel of rows with `dmin` / `rmin` roles). When
    // set, one ring is drawn per layer and the single-ring dmin/rmin are ignored.
    property var layers: null

    // Optional lamellae model (Vesicle). Rows: rmin, innerDmin, outerDmin, shell.
    // Each lamella becomes two leaflet rings (a bilayer): inner at `rmin`, outer
    // at `rmin + shell/2`, with opposite vector orientation. The shell thickness
    // `shell` spans from the inner baseline (rmin) out to the outer shell
    // (rmin + shell). Takes precedence over `layers` when set.
    property var lamellae: null

    // The real molecular mint->mext vector is long (POPC ~2.6 nm) versus the
    // baseline spacing (dmin >= 0.5 nm), so drawn 1:1 the vectors swamp the arc.
    // Shrink the schematic vector length by this divisor for legibility; the
    // real length is unchanged in the 3D Components viewer.
    property real lengthDivisor: 5

    // Rotate the whole schematic about its centre, degrees clockwise on screen.
    property real rotationDeg: 45

    // Length (nm) of the drawn rmin radius leader. It points along the radius
    // (as if from the centre) but is only this long, not the full radius.
    property real radiusLeaderNm: 0.3

    // Toggles (driven by the Shape view's checkboxes). Off by default.
    property bool showComponentNames: false
    property bool showDimensions: false

    // Theme colours pulled out as properties so a theme switch repaints.
    property color baselineColor: EaStyle.Colors.themeForegroundDisabled
    property color vectorColor: EaStyle.Colors.themeForegroundDisabled
    property color labelColor: EaStyle.Colors.themeForeground
    // Blueprint dimension annotations (lines + text), and the canvas background
    // used to punch a clear gap behind dimension text.
    property color dimColor: EaStyle.Colors.themeForegroundMinor
    property color clearColor: EaStyle.Colors.mainContentBackground

    onDminChanged: canvas.requestPaint()
    onRminChanged: canvas.requestPaint()
    onRevChanged: canvas.requestPaint()
    onLayersChanged: canvas.requestPaint()
    onLamellaeChanged: canvas.requestPaint()
    onLengthDivisorChanged: canvas.requestPaint()
    onRotationDegChanged: canvas.requestPaint()
    onRadiusLeaderNmChanged: canvas.requestPaint()
    onShowComponentNamesChanged: canvas.requestPaint()
    onShowDimensionsChanged: canvas.requestPaint()
    on_WatchedFractionsChanged: canvas.requestPaint()
    onBaselineColorChanged: canvas.requestPaint()
    onVectorColorChanged: canvas.requestPaint()
    onLabelColorChanged: canvas.requestPaint()
    onDimColorChanged: canvas.requestPaint()
    onClearColorChanged: canvas.requestPaint()

    // Global component indices that are actually present in a fractions set:
    // present === true AND mole ratio (fracs) > 0. With no fractions model, all
    // loaded components count as present.
    function _presentComps(fracModel) {
        const out = []
        if (!fracModel || fracModel.count === undefined) {
            for (let i = 0; i < components.count; ++i)
                out.push(i)
            return out
        }
        const n = Math.min(fracModel.count, components.count)
        for (let i = 0; i < n; ++i) {
            const row = fracModel.get(i)
            if (row && row.present && row.fracs > 0)
                out.push(i)
        }
        return out
    }

    // Ring definitions to draw: [{ dmin, rmin, reversed, showRmin, shell, comps }].
    //   - Vesicle (lamellae set): two leaflet rings per lamella.
    //   - Ball (layers set): one ring per layer.
    //   - Ring: a single ring from the plain properties.
    // `comps` is the list of present component indices for that ring (empty rings
    // are dropped). `showRmin` controls the rmin dimension; `shell` (> 0) requests
    // the outer-shell arc + shell-thickness dimension.
    function _ringDefs() {
        if (lamellae && lamellae.count !== undefined) {
            void Globals.BackendWrapper.lamellaeFractionsRevision
            const out = []
            for (let i = 0; i < lamellae.count; ++i) {
                const row = lamellae.get(i)
                if (!row)
                    continue
                const R = row.rmin   // absolute radius; lamellae overlap if set equal
                const T = row.shell
                // Symmetric lamellae edit a single (inner) fractions set, so both
                // leaflets mirror it; asymmetric leaflets read their own.
                const innerComps = _presentComps(Globals.BackendWrapper.lamellaeInnerFractionsModelAt(i))
                const outerComps = row.symmetric
                    ? innerComps
                    : _presentComps(Globals.BackendWrapper.lamellaeOuterFractionsModelAt(i))
                // Inner leaflet on the lamella baseline; carries the rmin + shell
                // annotations. Outer leaflet sits T/2 further out with reversed
                // vectors (the two leaflets point toward the bilayer midplane).
                out.push({ dmin: row.innerDmin, rmin: R, reversed: root.rev,
                           showRmin: true, shell: T, comps: innerComps })
                out.push({ dmin: row.outerDmin, rmin: R + T / 2, reversed: !root.rev,
                           showRmin: false, comps: outerComps })
            }
            return out
        }
        if (layers && layers.count !== undefined) {
            void Globals.BackendWrapper.layersFractionsRevision
            const out = []
            for (let i = 0; i < layers.count; ++i) {
                const row = layers.get(i)
                if (!row)
                    continue
                // Layers counted from 1: even-numbered layers (2, 4, ... =
                // indices 1, 3, ...) are reversed by default; `rev` flips parity.
                out.push({ dmin: row.dmin, rmin: row.rmin,
                           reversed: (i % 2 === 1) !== root.rev, showRmin: true,
                           comps: _presentComps(Globals.BackendWrapper.layersFractionsModelAt(i)) })
            }
            return out
        }
        return [{ dmin: root.dmin, rmin: root.rmin, reversed: root.rev, showRmin: true,
                  comps: _presentComps(Globals.BackendWrapper.fractionsModel) }]
    }

    // Fractions models to watch for repaint (per leaflet/layer/ring). Rebuilt
    // when the structure adds/removes rows (revision tokens).
    readonly property var _watchedFractions: {
        const out = []
        if (lamellae && lamellae.count !== undefined) {
            void Globals.BackendWrapper.lamellaeFractionsRevision
            for (let i = 0; i < lamellae.count; ++i) {
                out.push(Globals.BackendWrapper.lamellaeInnerFractionsModelAt(i))
                out.push(Globals.BackendWrapper.lamellaeOuterFractionsModelAt(i))
            }
        } else if (layers && layers.count !== undefined) {
            void Globals.BackendWrapper.layersFractionsRevision
            for (let i = 0; i < layers.count; ++i)
                out.push(Globals.BackendWrapper.layersFractionsModelAt(i))
        } else {
            out.push(Globals.BackendWrapper.fractionsModel)
        }
        return out.filter(Boolean)
    }

    // Schematic mint->mext length for a component, in nm. This is the real
    // |atom[mext] - atom[mint]| distance (Å) shrunk by `lengthDivisor` for the
    // schematic. Returns 0 if the component has no structure or no valid vector.
    function _vectorLengthNm(compIndex) {
        if (compIndex < 0 || compIndex >= components.count)
            return 0
        const row = components.get(compIndex)
        if (!row || row.mint < 0 || row.mext < 0)
            return 0
        const atoms = Globals.BackendWrapper.componentStructureAtoms(compIndex)
        const n = atoms ? atoms.length : 0
        if (n === 0)
            return 0
        const mi = Math.max(0, Math.min(row.mint, n - 1))
        const me = Math.max(0, Math.min(row.mext, n - 1))
        const a = atoms[mi], b = atoms[me]
        const dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z
        const div = root.lengthDivisor > 0 ? root.lengthDivisor : 1
        return Math.sqrt(dx * dx + dy * dy + dz * dz) / 10.0 / div   // Å -> nm, shrunk
    }

    function _compName(compIndex) {
        if (compIndex >= 0 && compIndex < components.count) {
            const row = components.get(compIndex)
            if (row && row.name)
                return row.name
        }
        return qsTr("Comp %1").arg(compIndex + 1)
    }

    // Repaint when components are added/removed (count) and when an existing
    // row's value is edited in place (dataChanged) — e.g. changing mint/mext in
    // the sidebar table, which alters the drawn vector length.
    Connections {
        target: root.components
        function onCountChanged() { canvas.requestPaint() }
        function onDataChanged(topLeft, bottomRight, roles) { canvas.requestPaint() }
    }

    // Same, for the layers model (Ball): adding/removing layers or editing a
    // layer's dmin/rmin must repaint.
    Connections {
        target: root.layers
        ignoreUnknownSignals: true
        function onCountChanged() { canvas.requestPaint() }
        function onDataChanged(topLeft, bottomRight, roles) { canvas.requestPaint() }
    }

    // Same, for the lamellae model (Vesicle).
    Connections {
        target: root.lamellae
        ignoreUnknownSignals: true
        function onCountChanged() { canvas.requestPaint() }
        function onDataChanged(topLeft, bottomRight, roles) { canvas.requestPaint() }
    }

    // One Connections per fractions model in play, so toggling a component's
    // presence or editing its mole ratio recomputes the depicted vectors.
    Instantiator {
        model: root._watchedFractions
        delegate: Connections {
            required property var modelData
            target: modelData
            ignoreUnknownSignals: true
            function onCountChanged() { canvas.requestPaint() }
            function onDataChanged(topLeft, bottomRight, roles) { canvas.requestPaint() }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            const N = root.components ? root.components.count : 0
            if (N <= 0)
                return

            const defs = root._ringDefs()
            if (defs.length === 0)
                return

            const rot = root.rotationDeg * Math.PI / 180
            const arcSamples = 80

            // outward direction for a baseline angle: theta = 0 -> up (+y).
            // Increasing theta turns clockwise on screen (+y is up in world).
            function outward(theta) { return Qt.point(Math.sin(theta), Math.cos(theta)) }

            // ---- Build all rings in world coords, track bounds ----
            let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity
            function track(p) {
                if (p.x < minX) minX = p.x
                if (p.x > maxX) maxX = p.x
                if (p.y < minY) minY = p.y
                if (p.y > maxY) maxY = p.y
            }

            const geos = []
            for (let g = 0; g < defs.length; ++g) {
                const r = Math.max(defs[g].rmin, 1e-3)
                const d = Math.max(defs[g].dmin, 1e-3)
                const reversed = !!defs[g].reversed
                const showRmin = defs[g].showRmin !== false
                const shell = defs[g].shell > 0 ? defs[g].shell : 0
                // Present components for this ring; drop the ring if none.
                const comps = defs[g].comps || []
                const m = comps.length
                if (m === 0)
                    continue
                const Lfull = (m + 1) * d
                // Cap the baseline at 0.7 of the full circle it lies on; any
                // vector whose anchor falls past the cut-off is not drawn.
                const maxLen = 0.7 * 2 * Math.PI * r
                const L = Math.min(Lfull, maxLen)
                // -L/r/2 centres the (drawn) arc midpoint at the up axis; +rot turns it.
                const a0 = -(L / r) / 2 + rot

                const arc = []
                for (let i = 0; i <= arcSamples; ++i) {
                    const o = outward(a0 + (i / arcSamples) * L / r)
                    const p = Qt.point(r * o.x, r * o.y)
                    arc.push(p); track(p)
                }

                const vecs = []
                for (let k = 0; k <= m; ++k) {
                    const s = 0.5 * d + k * d
                    if (s > L)   // anchor past the cut-off baseline: not shown
                        continue
                    const o = outward(a0 + s / r)
                    const compIndex = comps[k % m]
                    let vlen = root._vectorLengthNm(compIndex)
                    if (vlen <= 1e-3)
                        vlen = d
                    const base = Qt.point(r * o.x, r * o.y)                  // on baseline
                    const free = Qt.point((r + vlen) * o.x, (r + vlen) * o.y) // outer end
                    // Arrow goes mint -> mext. Anchored (baseline) end is mint
                    // unless reversed, in which case it is mext.
                    const from = reversed ? free : base   // mint
                    const to = reversed ? base : free      // mext (arrowhead here)
                    vecs.push({ from: from, to: to, base: base, free: free,
                                compIndex: compIndex })
                    track(base); track(free)
                }

                // Point on the arc 0.25*dmin before the first vector (for the
                // rmin radius leader).
                const ro = outward(a0 + (0.25 * d) / r)
                const arcMid = Qt.point(r * ro.x, r * ro.y)

                // Vesicle outer shell: an arc at radius r+shell over the same
                // angular sweep, plus the radial thickness endpoints (inner
                // baseline -> outer shell). The thickness dimension mirrors the
                // rmin leader to the far end: 0.25*dmin past the last vector, or
                // the cut-off edge of the baseline, whichever comes first.
                let shellArc = null, shellInner = null, shellOuter = null
                if (shell > 0) {
                    const rs = r + shell
                    shellArc = []
                    for (let i = 0; i <= arcSamples; ++i) {
                        const o = outward(a0 + (i / arcSamples) * L / r)
                        const p = Qt.point(rs * o.x, rs * o.y)
                        shellArc.push(p); track(p)
                    }
                    const sShell = Math.min((N + 0.75) * d, L)
                    const om = outward(a0 + sShell / r)
                    shellInner = Qt.point(r * om.x, r * om.y)
                    shellOuter = Qt.point(rs * om.x, rs * om.y)
                }

                geos.push({ r: r, d: d, arc: arc, vecs: vecs, arcMid: arcMid,
                            showRmin: showRmin, shell: shell,
                            shellArc: shellArc, shellInner: shellInner,
                            shellOuter: shellOuter })
            }

            // ---- World -> screen mapping (fit with margin, flip Y) ----
            const margin = 0.82
            const spanX = Math.max(maxX - minX, 1e-3)
            const spanY = Math.max(maxY - minY, 1e-3)
            const scale = Math.min((width * margin) / spanX, (height * margin) / spanY)
            const cx = (minX + maxX) / 2
            const cy = (minY + maxY) / 2
            function S(p) {
                return Qt.point((p.x - cx) * scale + width / 2,
                                height / 2 - (p.y - cy) * scale)
            }
            const centerS = S(Qt.point(0, 0))

            const headAng = Math.PI / 7
            const fontPx = EaStyle.Sizes.fontPixelSize
            const compFontPx = Math.round(fontPx * 0.7)

            // Text centred at (cxp,cyp) and rotated to run parallel to `angle`
            // (kept upright), on a coloured background plate.
            function drawLabel(cxp, cyp, angle, text, px, bg, fg) {
                let aa = angle
                if (aa > Math.PI / 2) aa -= Math.PI
                else if (aa < -Math.PI / 2) aa += Math.PI
                ctx.save()
                ctx.translate(cxp, cyp)
                ctx.rotate(aa)
                ctx.font = px + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                const w = ctx.measureText(text).width
                ctx.fillStyle = bg
                ctx.fillRect(-w / 2 - 3, -px * 0.7, w + 6, px * 1.4)
                ctx.fillStyle = fg
                ctx.fillText(text, 0, 0)
                ctx.restore()
            }

            // ---- Draw a ring's baseline + vectors ----
            function drawPolyline(pts) {
                ctx.beginPath()
                let p0 = S(pts[0])
                ctx.moveTo(p0.x, p0.y)
                for (let i = 1; i < pts.length; ++i) {
                    const p = S(pts[i])
                    ctx.lineTo(p.x, p.y)
                }
                ctx.stroke()
            }
            function drawRing(geo) {
                // baseline
                ctx.lineWidth = 2
                ctx.strokeStyle = root.baselineColor
                drawPolyline(geo.arc)

                // outer shell boundary (Vesicle), drawn lighter as a reference.
                if (geo.shellArc) {
                    ctx.lineWidth = 1
                    ctx.strokeStyle = root.dimColor
                    drawPolyline(geo.shellArc)
                }

                for (let k = 0; k < geo.vecs.length; ++k) {
                    const v = geo.vecs[k]
                    const a = S(v.from)
                    const b = S(v.to)
                    const baseS = S(v.base)
                    const freeS = S(v.free)

                    // arrowhead geometry at the mext end (b); size scales with shaft
                    const shaftLen = Math.hypot(b.x - a.x, b.y - a.y)
                    const headLen = Math.max(8, Math.min(shaftLen * 0.3, 18))
                    const ang = Math.atan2(b.y - a.y, b.x - a.x)
                    const bx = b.x - headLen * Math.cos(ang)
                    const by = b.y - headLen * Math.sin(ang)

                    // shaft (stop at the triangle base so it doesn't poke through)
                    ctx.lineWidth = 3
                    ctx.strokeStyle = root.vectorColor
                    ctx.beginPath()
                    ctx.moveTo(a.x, a.y)
                    ctx.lineTo(bx, by)
                    ctx.stroke()

                    // filled triangle arrowhead
                    ctx.fillStyle = root.vectorColor
                    ctx.beginPath()
                    ctx.moveTo(b.x, b.y)
                    ctx.lineTo(b.x - headLen * Math.cos(ang - headAng),
                               b.y - headLen * Math.sin(ang - headAng))
                    ctx.lineTo(b.x - headLen * Math.cos(ang + headAng),
                               b.y - headLen * Math.sin(ang + headAng))
                    ctx.closePath()
                    ctx.fill()

                    // dot marks the end tied to the baseline
                    ctx.beginPath()
                    ctx.arc(baseS.x, baseS.y, 3.5, 0, 2 * Math.PI)
                    ctx.fill()

                    // component name centred on the vector, parallel to it, on a
                    // translucent white plate.
                    if (root.showComponentNames) {
                        const mx = (baseS.x + freeS.x) / 2
                        const my = (baseS.y + freeS.y) / 2
                        const vAng = Math.atan2(freeS.y - baseS.y, freeS.x - baseS.x)
                        drawLabel(mx, my, vAng, root._compName(v.compIndex),
                                  compFontPx, Qt.rgba(1, 1, 1, 0.5), root.labelColor)
                    }
                }
            }

            // ---- Blueprint-style dimension helpers ----
            const dimFont = Math.max(10, fontPx * 0.8)
            function dimHead(tx, ty, ang) {
                const hl = 7, ha = Math.PI / 7
                ctx.beginPath()
                ctx.moveTo(tx, ty)
                ctx.lineTo(tx - hl * Math.cos(ang - ha), ty - hl * Math.sin(ang - ha))
                ctx.lineTo(tx - hl * Math.cos(ang + ha), ty - hl * Math.sin(ang + ha))
                ctx.closePath()
                ctx.fill()
            }
            // ---- Draw a ring's dmin + rmin dimensions ----
            function drawDims(geo) {
                ctx.strokeStyle = root.dimColor
                ctx.fillStyle = root.dimColor
                ctx.lineWidth = 1
                ctx.font = dimFont + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"

                // dmin: between the baseline ends of the first two vectors,
                // offset toward the centre (the clear zone). Needs both vectors
                // to survive the cut-off.
                if (geo.vecs.length >= 2) {
                    const q1 = S(geo.vecs[0].base)
                    const q2 = S(geo.vecs[1].base)
                    const midD = Qt.point((q1.x + q2.x) / 2, (q1.y + q2.y) / 2)
                    let inx = centerS.x - midD.x, iny = centerS.y - midD.y
                    const inl = Math.max(Math.hypot(inx, iny), 1e-3)
                    inx /= inl; iny /= inl
                    const dOff = 26
                    const e1 = Qt.point(q1.x + inx * dOff, q1.y + iny * dOff)
                    const e2 = Qt.point(q2.x + inx * dOff, q2.y + iny * dOff)
                    ctx.beginPath()
                    ctx.moveTo(q1.x, q1.y); ctx.lineTo(e1.x + inx * 4, e1.y + iny * 4)
                    ctx.moveTo(q2.x, q2.y); ctx.lineTo(e2.x + inx * 4, e2.y + iny * 4)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(e1.x, e1.y); ctx.lineTo(e2.x, e2.y)
                    ctx.stroke()
                    const dAng = Math.atan2(e2.y - e1.y, e2.x - e1.x)
                    dimHead(e1.x, e1.y, dAng + Math.PI)
                    dimHead(e2.x, e2.y, dAng)
                    drawLabel((e1.x + e2.x) / 2, (e1.y + e2.y) / 2, dAng,
                              "dmin " + geo.d.toFixed(2) + " nm",
                              dimFont, root.clearColor, root.dimColor)
                }

                // rmin: short radius leader pointing along the radius, arrowhead
                // at the arc, label running parallel along the leader.
                if (geo.showRmin) {
                    const arcMidS = S(geo.arcMid)
                    const rAng = Math.atan2(arcMidS.y - centerS.y, arcMidS.x - centerS.x)
                    const leaderPx = root.radiusLeaderNm * scale
                    const rStart = Qt.point(arcMidS.x - Math.cos(rAng) * leaderPx,
                                            arcMidS.y - Math.sin(rAng) * leaderPx)
                    ctx.beginPath()
                    ctx.moveTo(rStart.x, rStart.y)
                    ctx.lineTo(arcMidS.x, arcMidS.y)
                    ctx.stroke()
                    dimHead(arcMidS.x, arcMidS.y, rAng)
                    drawLabel((rStart.x + arcMidS.x) / 2, (rStart.y + arcMidS.y) / 2, rAng,
                              "R " + geo.r.toFixed(2) + " nm",
                              dimFont, root.clearColor, root.dimColor)
                }

                // shell thickness (Vesicle): full radial dimension from the inner
                // baseline out to the outer shell, with arrowheads at both ends.
                if (geo.shell > 0 && geo.shellInner && geo.shellOuter) {
                    const si = S(geo.shellInner)
                    const so = S(geo.shellOuter)
                    const sAng = Math.atan2(so.y - si.y, so.x - si.x)
                    ctx.beginPath()
                    ctx.moveTo(si.x, si.y); ctx.lineTo(so.x, so.y)
                    ctx.stroke()
                    dimHead(si.x, si.y, sAng + Math.PI)
                    dimHead(so.x, so.y, sAng)
                    drawLabel((si.x + so.x) / 2, (si.y + so.y) / 2, sAng,
                              "shell " + geo.shell.toFixed(2) + " nm",
                              dimFont, root.clearColor, root.dimColor)
                }
            }

            for (let g = 0; g < geos.length; ++g)
                drawRing(geos[g])
            if (root.showDimensions)
                for (let g2 = 0; g2 < geos.length; ++g2)
                    drawDims(geos[g2])
        }
    }

    // Empty state.
    EaElements.Label {
        anchors.centerIn: parent
        visible: !root.components || root.components.count === 0
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("No components yet — load or create one in the sidebar.")
    }
}
