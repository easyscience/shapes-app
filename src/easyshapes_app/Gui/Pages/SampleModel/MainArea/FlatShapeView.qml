// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Shape view for the flat structures (Bilayer / Monolayer). Like the layered
// ring view but with NO curvature: the baselines are straight lines.
//
//   - Two leaflets, a bottom one (y = 0) and a top one (y = zsep). `zsep` plays
//     the role the shell thickness plays for the vesicle.
//   - Each leaflet has N+1 mint->mext vectors (N = present components; the first
//     component owns two, mirroring the ring layout), spaced by `dmin`.
//   - The top leaflet is offset to the right by 0.5*dmin, and the whole sketch is
//     rotated by `rotationDeg`, so it reads like the other (radial) shapes.
//   - Bilayer: vectors point INTO the gap (heads on the outer surfaces, tails in
//     the middle). Monolayer: `reversed` flips them (heads in the middle).
//   - Vector length is the real molecular mint->mext distance (Å) / lengthDivisor.
Item {
    id: root

    property var components: Globals.BackendWrapper.componentsLoaded
    property var fractions: Globals.BackendWrapper.fractionsModel

    property real dmin: 0.5
    property real zsep: 0.0
    property int nside: 1            // not used for the schematic vector count
    property bool reversed: false    // Monolayer flips the mint->mext direction

    property real lengthDivisor: 5
    property real rotationDeg: -45   // tilt the whole sketch clockwise, like the radial views

    property bool showComponentNames: false
    property bool showDimensions: false

    property color baselineColor: EaStyle.Colors.themeForegroundDisabled
    property color vectorColor: EaStyle.Colors.themeForegroundDisabled
    property color labelColor: EaStyle.Colors.themeForeground
    property color dimColor: EaStyle.Colors.themeForegroundMinor
    property color clearColor: EaStyle.Colors.mainContentBackground

    onDminChanged: canvas.requestPaint()
    onZsepChanged: canvas.requestPaint()
    onReversedChanged: canvas.requestPaint()
    onLengthDivisorChanged: canvas.requestPaint()
    onRotationDegChanged: canvas.requestPaint()
    onShowComponentNamesChanged: canvas.requestPaint()
    onShowDimensionsChanged: canvas.requestPaint()
    onFractionsChanged: canvas.requestPaint()
    onBaselineColorChanged: canvas.requestPaint()
    onVectorColorChanged: canvas.requestPaint()
    onLabelColorChanged: canvas.requestPaint()
    onDimColorChanged: canvas.requestPaint()
    onClearColorChanged: canvas.requestPaint()

    function _presentComps() {
        const out = []
        const fm = fractions
        if (!fm || fm.count === undefined) {
            for (let i = 0; i < components.count; ++i)
                out.push(i)
            return out
        }
        const n = Math.min(fm.count, components.count)
        for (let i = 0; i < n; ++i) {
            const row = fm.get(i)
            if (row && row.present && row.fracs > 0)
                out.push(i)
        }
        return out
    }

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
        return Math.sqrt(dx * dx + dy * dy + dz * dz) / 10.0 / div
    }

    function _compName(compIndex) {
        if (compIndex >= 0 && compIndex < components.count) {
            const row = components.get(compIndex)
            if (row && row.name)
                return row.name
        }
        return qsTr("Comp %1").arg(compIndex + 1)
    }

    Connections {
        target: root.components
        function onCountChanged() { canvas.requestPaint() }
        function onDataChanged(topLeft, bottomRight, roles) { canvas.requestPaint() }
    }
    Connections {
        target: root.fractions
        ignoreUnknownSignals: true
        function onCountChanged() { canvas.requestPaint() }
        function onDataChanged(topLeft, bottomRight, roles) { canvas.requestPaint() }
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

            const comps = root._presentComps()
            const m = comps.length
            if (m === 0)
                return

            const d = Math.max(root.dmin, 1e-3)
            const zsep = Math.max(0, root.zsep)
            const phi = root.rotationDeg * Math.PI / 180
            const cphi = Math.cos(phi), sphi = Math.sin(phi)

            // N+1 vectors per leaflet (slot k -> comps[k % m]); centre the row.
            const halfSpan = m * d / 2
            // Bottom leaflet points up (+y), top points down (-y) and is shifted
            // right by half a dmin.
            const leaflets = [{ y: 0, nrm: 1, xs: 0 }, { y: zsep, nrm: -1, xs: 0.5 * d }]

            // ---- bounds over rotated world points ----
            let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity
            function track(x, y) {
                const rx = x * cphi - y * sphi, ry = x * sphi + y * cphi
                if (rx < minX) minX = rx
                if (rx > maxX) maxX = rx
                if (ry < minY) minY = ry
                if (ry > maxY) maxY = ry
            }

            const vecs = []
            const baselines = []
            for (let l = 0; l < leaflets.length; ++l) {
                const lf = leaflets[l]
                const x0 = -halfSpan - 0.5 * d + lf.xs
                const x1 = halfSpan + 0.5 * d + lf.xs
                baselines.push({ y: lf.y, x0: x0, x1: x1 })
                track(x0, lf.y); track(x1, lf.y)
                for (let k = 0; k <= m; ++k) {
                    const x = k * d - halfSpan + lf.xs
                    const compIndex = comps[k % m]
                    let vlen = root._vectorLengthNm(compIndex)
                    if (vlen <= 1e-3)
                        vlen = d
                    const baseY = lf.y
                    const freeY = lf.y + lf.nrm * vlen
                    const from = root.reversed ? { x: x, y: freeY } : { x: x, y: baseY }
                    const to = root.reversed ? { x: x, y: baseY } : { x: x, y: freeY }
                    vecs.push({ from: from, to: to, bx: x, by: baseY, fx: x, fy: freeY,
                                compIndex: compIndex })
                    track(x, baseY); track(x, freeY)
                }
            }

            // dimension anchor points (so they are framed too)
            const dOff = 0.4 * d
            const showDmin = root.showDimensions
            const showZsep = root.showDimensions && zsep > 0
            if (showDmin) { track(-halfSpan, -dOff); track(-halfSpan + d, -dOff) }
            const zsepX = baselines[1].x1 + dOff   // right end (bottom after the CW rotation)
            if (showZsep) { track(zsepX, 0); track(zsepX, zsep) }

            // ---- world -> screen (rotate, fit, flip Y) ----
            const margin = 0.82
            const spanX = Math.max(maxX - minX, 1e-3)
            const spanY = Math.max(maxY - minY, 1e-3)
            const scale = Math.min((width * margin) / spanX, (height * margin) / spanY)
            const cx = (minX + maxX) / 2
            const cy = (minY + maxY) / 2
            function S(x, y) {
                const rx = x * cphi - y * sphi, ry = x * sphi + y * cphi
                return Qt.point((rx - cx) * scale + width / 2,
                                height / 2 - (ry - cy) * scale)
            }

            const headAng = Math.PI / 7
            const fontPx = EaStyle.Sizes.fontPixelSize
            const compFontPx = Math.round(fontPx * 0.7)
            const dimFont = Math.max(10, fontPx * 0.8)

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
            function dimHead(tx, ty, ang) {
                const hl = 7, ha = Math.PI / 7
                ctx.beginPath()
                ctx.moveTo(tx, ty)
                ctx.lineTo(tx - hl * Math.cos(ang - ha), ty - hl * Math.sin(ang - ha))
                ctx.lineTo(tx - hl * Math.cos(ang + ha), ty - hl * Math.sin(ang + ha))
                ctx.closePath()
                ctx.fill()
            }

            // ---- baselines ----
            ctx.lineWidth = 2
            ctx.strokeStyle = root.baselineColor
            for (let b = 0; b < baselines.length; ++b) {
                const p0 = S(baselines[b].x0, baselines[b].y)
                const p1 = S(baselines[b].x1, baselines[b].y)
                ctx.beginPath()
                ctx.moveTo(p0.x, p0.y); ctx.lineTo(p1.x, p1.y)
                ctx.stroke()
            }

            // ---- vectors ----
            for (let k = 0; k < vecs.length; ++k) {
                const v = vecs[k]
                const a = S(v.from.x, v.from.y)
                const b = S(v.to.x, v.to.y)
                const shaftLen = Math.hypot(b.x - a.x, b.y - a.y)
                const headLen = Math.max(8, Math.min(shaftLen * 0.3, 18))
                const ang = Math.atan2(b.y - a.y, b.x - a.x)
                const tbx = b.x - headLen * Math.cos(ang)
                const tby = b.y - headLen * Math.sin(ang)

                ctx.lineWidth = 3
                ctx.strokeStyle = root.vectorColor
                ctx.beginPath()
                ctx.moveTo(a.x, a.y); ctx.lineTo(tbx, tby)
                ctx.stroke()

                ctx.fillStyle = root.vectorColor
                ctx.beginPath()
                ctx.moveTo(b.x, b.y)
                ctx.lineTo(b.x - headLen * Math.cos(ang - headAng),
                           b.y - headLen * Math.sin(ang - headAng))
                ctx.lineTo(b.x - headLen * Math.cos(ang + headAng),
                           b.y - headLen * Math.sin(ang + headAng))
                ctx.closePath()
                ctx.fill()

                const baseS = S(v.bx, v.by)
                ctx.beginPath()
                ctx.arc(baseS.x, baseS.y, 3.5, 0, 2 * Math.PI)
                ctx.fill()

                if (root.showComponentNames) {
                    const freeS = S(v.fx, v.fy)
                    const vAng = Math.atan2(freeS.y - baseS.y, freeS.x - baseS.x)
                    drawLabel((baseS.x + freeS.x) / 2, (baseS.y + freeS.y) / 2, vAng,
                              root._compName(v.compIndex),
                              compFontPx, Qt.rgba(1, 1, 1, 0.5), root.labelColor)
                }
            }

            // ---- dimensions ----
            if (showDmin) {
                ctx.strokeStyle = root.dimColor
                ctx.fillStyle = root.dimColor
                ctx.lineWidth = 1
                // dmin between the first two bottom-leaflet vectors, offset to the
                // outer side (away from the gap the vectors point into).
                const a0 = S(-halfSpan, 0), e0 = S(-halfSpan, -dOff)
                const a1 = S(-halfSpan + d, 0), e1 = S(-halfSpan + d, -dOff)
                ctx.beginPath()
                ctx.moveTo(a0.x, a0.y); ctx.lineTo(e0.x, e0.y)
                ctx.moveTo(a1.x, a1.y); ctx.lineTo(e1.x, e1.y)
                ctx.moveTo(e0.x, e0.y); ctx.lineTo(e1.x, e1.y)
                ctx.stroke()
                const dAng = Math.atan2(e1.y - e0.y, e1.x - e0.x)
                dimHead(e0.x, e0.y, dAng + Math.PI)
                dimHead(e1.x, e1.y, dAng)
                drawLabel((e0.x + e1.x) / 2, (e0.y + e1.y) / 2, dAng,
                          "dmin " + d.toFixed(2) + " nm",
                          dimFont, root.clearColor, root.dimColor)
            }
            if (showZsep) {
                ctx.strokeStyle = root.dimColor
                ctx.fillStyle = root.dimColor
                ctx.lineWidth = 1
                // zsep between the two baselines, off the right end.
                const xz = zsepX
                const b0 = S(baselines[0].x1, 0), w0 = S(xz, 0)
                const b1 = S(baselines[1].x1, zsep), w1 = S(xz, zsep)
                ctx.beginPath()
                ctx.moveTo(b0.x, b0.y); ctx.lineTo(w0.x, w0.y)
                ctx.moveTo(b1.x, b1.y); ctx.lineTo(w1.x, w1.y)
                ctx.moveTo(w0.x, w0.y); ctx.lineTo(w1.x, w1.y)
                ctx.stroke()
                const zAng = Math.atan2(w1.y - w0.y, w1.x - w0.x)
                dimHead(w0.x, w0.y, zAng + Math.PI)
                dimHead(w1.x, w1.y, zAng)
                drawLabel((w0.x + w1.x) / 2, (w0.y + w1.y) / 2, zAng,
                          "Zsep " + zsep.toFixed(2) + " nm",
                          dimFont, root.clearColor, root.dimColor)
            }
        }
    }

    EaElements.Label {
        anchors.centerIn: parent
        visible: !root.components || root.components.count === 0
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("No components yet — load or create one in the sidebar.")
    }
}
