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
//   - Two leaflets mirrored about the midplane (y = 0). Each has N+1
//     mint->mext vectors (N = present components; the first component owns
//     two, mirroring the ring layout), spaced by `dmin`, each as long as the
//     component's real bone (componentBoneLength, nm). A component without
//     one (Mint = Mext, or no structure) draws nothing: its slot stays
//     empty.
//   - The leaflets run level, left to right; the top one is offset to the
//     right by 0.5*dmin.
//   - Placement follows the library's layer generator. Each leaflet's
//     baseline is the plane its reference atoms sit on, half a gap from the
//     midplane; the gap is zsep, or dmin when zsep is 0.
//       Bilayer, zsep 0:   mint on the baseline, arrows point out.
//       Bilayer, zsep > 0: mext on the baseline, arrows point out.
//       Monolayer (`reversed`): mext on the baseline, arrows point in.
//     A dot marks the end on the baseline.
Item {
    id: root

    property var components: Globals.BackendWrapper.componentsLoaded
    property var fractions: Globals.BackendWrapper.compositionItems

    property real dmin: 0.5
    property real zsep: 0.0
    property int nside: 1            // not used for the schematic vector count
    property bool reversed: false    // Monolayer flips the mint->mext direction

    property bool showComponentNames: false
    property bool showDimensions: false
    property bool showMolecules: false

    property color baselineColor: EaStyle.Colors.themeForegroundDisabled
    property color vectorColor: EaStyle.Colors.themeForegroundDisabled
    property color labelColor: EaStyle.Colors.themeForeground
    property color dimColor: EaStyle.Colors.themeForegroundMinor
    property color clearColor: EaStyle.Colors.mainContentBackground

    onDminChanged: canvas.requestPaint()
    onZsepChanged: canvas.requestPaint()
    onReversedChanged: canvas.requestPaint()
    onShowComponentNamesChanged: canvas.requestPaint()
    onShowDimensionsChanged: canvas.requestPaint()
    onShowMoleculesChanged: canvas.requestPaint()
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
            if (row && row.present && row.molRatio > 0)
                out.push(i)
        }
        return out
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

    MoleculeSketch { id: sketch }

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
            // Shown molecules reach past their vectors: the fit makes room
            const reaches = {}
            if (root.showMolecules)
                for (const i of comps)
                    reaches[i] = sketch.reachOf(root.components, i)

            const d = Math.max(root.dmin, 1e-3)
            const zsep = Math.max(0, root.zsep)

            // Half the gap between the baselines, and the atom on them (see
            // the header).
            const zini = (zsep > 0 ? zsep : d) / 2
            const refMext = zsep > 0 || root.reversed
            // Arrow direction along a leaflet's outward normal.
            const dir = root.reversed ? -1 : 1

            // N+1 vectors per leaflet (slot k -> comps[k % m]); centre the row.
            const halfSpan = m * d / 2
            // Bottom leaflet faces out down (-y), top up (+y); the top one is
            // shifted right by half a dmin.
            const leaflets = [{ y: -zini, out: -1, xs: 0 }, { y: zini, out: 1, xs: 0.5 * d }]

            // ---- bounds over world points ----
            let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity
            function track(x, y) {
                if (x < minX) minX = x
                if (x > maxX) maxX = x
                if (y < minY) minY = y
                if (y > maxY) maxY = y
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
                    const bone = Globals.BackendWrapper.componentBoneLength(compIndex)
                    if (bone <= 1e-3)   // no bone: the slot stays empty
                        continue
                    const step = lf.out * dir * bone
                    const mintY = refMext ? lf.y - step : lf.y
                    const mextY = refMext ? lf.y : lf.y + step
                    vecs.push({ from: { x: x, y: mintY }, to: { x: x, y: mextY },
                                bx: x, by: lf.y, compIndex: compIndex })
                    track(x, mintY); track(x, mextY)
                    if (root.showMolecules)
                        for (const c of sketch.corners(Qt.point(x, mintY), Qt.point(x, mextY),
                                                       reaches[compIndex]))
                            track(c.x, c.y)
                }
            }

            // dimension anchor points (so they are framed too); dmin goes on
            // the side of the bottom baseline its vectors leave clear
            const dOff = 0.4 * d
            const dimY = -zini + (refMext ? -dir : dir) * dOff
            const showDmin = root.showDimensions
            const showZsep = root.showDimensions && zsep > 0
            if (showDmin) { track(-halfSpan, dimY); track(-halfSpan + d, dimY) }
            const zsepX = baselines[1].x1 + dOff   // right end
            if (showZsep) { track(zsepX, -zini); track(zsepX, zini) }

            // ---- world -> screen (fit, flip Y) ----
            const margin = 0.82
            const spanX = Math.max(maxX - minX, 1e-3)
            const spanY = Math.max(maxY - minY, 1e-3)
            const scale = Math.min((width * margin) / spanX, (height * margin) / spanY)
            const cx = (minX + maxX) / 2
            const cy = (minY + maxY) / 2
            function S(x, y) {
                return Qt.point((x - cx) * scale + width / 2, height / 2 - (y - cy) * scale)
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
            }

            // ---- molecules over the vectors, then names over both ----
            const onScreen = vecs.map(v => ({ compIndex: v.compIndex,
                                              from: S(v.from.x, v.from.y),
                                              to: S(v.to.x, v.to.y) }))
            if (root.showMolecules)
                sketch.drawMolecules(ctx, root.components, onScreen, scale)
            if (root.showComponentNames) {
                for (const v of onScreen) {
                    const a = v.from, b = v.to
                    drawLabel((a.x + b.x) / 2, (a.y + b.y) / 2, Math.atan2(b.y - a.y, b.x - a.x),
                              root._compName(v.compIndex),
                              compFontPx, root.clearColor, root.labelColor)
                }
            }

            // ---- dimensions ----
            if (showDmin) {
                ctx.strokeStyle = root.dimColor
                ctx.fillStyle = root.dimColor
                ctx.lineWidth = 1
                // dmin between the first two bottom-leaflet vectors, offset to
                // the side they leave clear.
                const a0 = S(-halfSpan, -zini), e0 = S(-halfSpan, dimY)
                const a1 = S(-halfSpan + d, -zini), e1 = S(-halfSpan + d, dimY)
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
                const b0 = S(baselines[0].x1, -zini), w0 = S(xz, -zini)
                const b1 = S(baselines[1].x1, zini), w1 = S(xz, zini)
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
