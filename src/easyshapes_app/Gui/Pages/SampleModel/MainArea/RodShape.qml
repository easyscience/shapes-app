// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle


// Schematic of the rod body for the Rod structure's Shape view. The rod is a
// capsule: two half-sphere end caps joined by a cylindrical body. The body is
// filled with evenly spaced ribs, one per turn (so the rod grows with `turns`).
// A "turns N" dimension is drawn underneath.
Canvas {
    id: rod

    property int turns: 1
    property bool showDimensions: false

    property color strokeColor: EaStyle.Colors.themeForegroundDisabled
    property color dimColor: EaStyle.Colors.themeForegroundMinor
    property color clearColor: EaStyle.Colors.mainContentBackground

    onTurnsChanged: requestPaint()
    onShowDimensionsChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onClearColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)

        const n = Math.max(1, rod.turns)

        // The rod keeps real proportions (length grows with turns, fixed radius)
        // and is scaled uniformly to fit a target width. So more turns -> longer
        // rod -> scaled down -> visibly thinner (height shrinks), which reads as a
        // more realistic rod.
        const leftPad = 18                       // left-aligned with padding
        let capR = Math.min(24, height * 0.22)
        const perTurn = 3                        // body length per turn before scaling
        let bodyW = n * perTurn
        let totalW = bodyW + 2 * capR
        const avail = width * 0.6                 // narrower target so the rod isn't too wide
        if (totalW > avail) {
            const s = avail / totalW
            capR *= s; bodyW *= s; totalW *= s    // uniform scale: width and height shrink together
        }

        const cy = height * 0.62                 // sit lower in the view; leave room for the dimension below
        const startX = leftPad
        const bodyL = startX + capR
        const bodyR = bodyL + bodyW

        // ---- Capsule outline ----
        ctx.lineWidth = 2
        ctx.strokeStyle = rod.strokeColor

        // top & bottom edges of the cylindrical body
        ctx.beginPath()
        ctx.moveTo(bodyL, cy - capR); ctx.lineTo(bodyR, cy - capR)
        ctx.moveTo(bodyL, cy + capR); ctx.lineTo(bodyR, cy + capR)
        ctx.stroke()

        // left half-sphere cap (bulges left), right cap (bulges right)
        ctx.beginPath()
        ctx.arc(bodyL, cy, capR, Math.PI / 2, Math.PI * 3 / 2)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(bodyR, cy, capR, -Math.PI / 2, Math.PI / 2)
        ctx.stroke()

        // ---- Turn ribs (one vertical line per turn, small spacing) ----
        ctx.lineWidth = 1
        const ribStep = bodyW / n
        for (let i = 0; i < n; ++i) {
            const x = bodyL + (i + 0.5) * ribStep
            ctx.beginPath()
            ctx.moveTo(x, cy - capR); ctx.lineTo(x, cy + capR)
            ctx.stroke()
        }

        // ---- "turns N" dimension underneath (gated by the Dimensions toggle) ----
        if (rod.showDimensions) {
            const dy = cy + capR + 18
            ctx.strokeStyle = rod.dimColor
            ctx.fillStyle = rod.dimColor
            ctx.lineWidth = 1
            // witness lines down from the body ends (between the half-spheres only)
            ctx.beginPath()
            ctx.moveTo(bodyL, cy + capR + 4); ctx.lineTo(bodyL, dy + 4)
            ctx.moveTo(bodyR, cy + capR + 4); ctx.lineTo(bodyR, dy + 4)
            // dimension line
            ctx.moveTo(bodyL, dy); ctx.lineTo(bodyR, dy)
            ctx.stroke()

            function dimHead(tx, ty, ang) {
                const hl = 7, ha = Math.PI / 7
                ctx.beginPath()
                ctx.moveTo(tx, ty)
                ctx.lineTo(tx - hl * Math.cos(ang - ha), ty - hl * Math.sin(ang - ha))
                ctx.lineTo(tx - hl * Math.cos(ang + ha), ty - hl * Math.sin(ang + ha))
                ctx.closePath()
                ctx.fill()
            }
            dimHead(bodyL, dy, Math.PI)
            dimHead(bodyR, dy, 0)

            // label with a cleared gap punched behind it
            const px = Math.max(10, EaStyle.Sizes.fontPixelSize * 0.8)
            ctx.font = px + "px sans-serif"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            const text = qsTr("turns %1").arg(n)
            const w = ctx.measureText(text).width + 6
            const lx = (bodyL + bodyR) / 2
            ctx.fillStyle = rod.clearColor
            ctx.fillRect(lx - w / 2, dy - px * 0.75, w, px * 1.5)
            ctx.fillStyle = rod.dimColor
            ctx.fillText(text, lx, dy)
        }
    }
}
