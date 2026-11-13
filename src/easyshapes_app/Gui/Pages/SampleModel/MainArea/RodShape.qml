// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle


// Schematic of the rod body for the Rod structure's Shape view. The rod is a
// capsule: two half-sphere end caps joined by a cylindrical body. The body is
// filled with evenly spaced ribs, one per turn (so the rod grows with `turns`).
// With the library's sizes known, the capsule keeps their proportions and the
// dimensions give the length from cap tip to cap tip and the outer radius;
// otherwise it keeps typical ones and a "turns N" dimension.
Canvas {
    id: rod

    property int turns: 1
    // In nm; null while no component has a bone length
    property var outerRadius: null
    property var length: null
    property bool showDimensions: false

    property color strokeColor: EaStyle.Colors.themeForegroundDisabled
    property color dimColor: EaStyle.Colors.themeForegroundMinor
    property color clearColor: EaStyle.Colors.mainContentBackground

    onTurnsChanged: requestPaint()
    onOuterRadiusChanged: requestPaint()
    onLengthChanged: requestPaint()
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
        const known = typeof rod.outerRadius === 'number' && rod.outerRadius > 0
                      && typeof rod.length === 'number' && rod.length > 0

        const leftPad = 18                       // left-aligned with padding
        let capR, bodyW
        if (known) {
            // nm to px: the capsule fits the target width, the caps the
            // corner's height; with one turn the caps meet
            const s = Math.min(width * 0.6 / rod.length, height * 0.22 / rod.outerRadius)
            capR = rod.outerRadius * s
            bodyW = (rod.length - 2 * rod.outerRadius) * s
        } else {
            // Typical proportions (length grows with turns, fixed radius),
            // scaled uniformly to fit a target width. So more turns -> longer
            // rod -> scaled down -> visibly thinner, which reads as a more
            // realistic rod.
            capR = Math.min(24, height * 0.22)
            bodyW = n * 3                        // body length per turn before scaling
            const totalW = bodyW + 2 * capR
            const avail = width * 0.6             // narrower target so the rod isn't too wide
            if (totalW > avail) {
                const s = avail / totalW
                capR *= s; bodyW *= s             // uniform scale: width and height shrink together
            }
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

        // ---- Dimensions (gated by the Dimensions toggle) ----
        if (!rod.showDimensions)
            return

        ctx.strokeStyle = rod.dimColor
        ctx.fillStyle = rod.dimColor
        ctx.lineWidth = 1
        const px = Math.max(10, EaStyle.Sizes.fontPixelSize * 0.8)
        ctx.font = px + "px sans-serif"

        function dimHead(tx, ty, ang) {
            const hl = 7, ha = Math.PI / 7
            ctx.beginPath()
            ctx.moveTo(tx, ty)
            ctx.lineTo(tx - hl * Math.cos(ang - ha), ty - hl * Math.sin(ang - ha))
            ctx.lineTo(tx - hl * Math.cos(ang + ha), ty - hl * Math.sin(ang + ha))
            ctx.closePath()
            ctx.fill()
        }

        // Underneath: cap tip to cap tip when known, else the body between
        // the half-spheres
        const x0 = known ? startX : bodyL
        const x1 = known ? bodyR + capR : bodyR
        const top = known ? cy + 4 : cy + capR + 4
        const dy = cy + capR + 18
        ctx.beginPath()
        ctx.moveTo(x0, top); ctx.lineTo(x0, dy + 4)
        ctx.moveTo(x1, top); ctx.lineTo(x1, dy + 4)
        ctx.moveTo(x0, dy); ctx.lineTo(x1, dy)
        ctx.stroke()
        dimHead(x0, dy, Math.PI)
        dimHead(x1, dy, 0)

        // label with a cleared gap punched behind it
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        const text = known ? qsTr("%1 nm, turns %2").arg(rod.length.toFixed(2)).arg(n)
                           : qsTr("turns %1").arg(n)
        const w = ctx.measureText(text).width + 6
        const lx = (x0 + x1) / 2
        ctx.fillStyle = rod.clearColor
        ctx.fillRect(lx - w / 2, dy - px * 0.75, w, px * 1.5)
        ctx.fillStyle = rod.dimColor
        ctx.fillText(text, lx, dy)

        // The outer radius: from the right cap's centre out at 45°, its
        // value past the cap
        if (known) {
            const ang = -Math.PI / 4
            const ex = bodyR + capR * Math.cos(ang)
            const ey = cy + capR * Math.sin(ang)
            ctx.beginPath()
            ctx.moveTo(bodyR, cy); ctx.lineTo(ex, ey)
            ctx.stroke()
            dimHead(ex, ey, ang)
            ctx.textAlign = "left"
            ctx.fillText(qsTr("%1 nm").arg(rod.outerRadius.toFixed(2)), bodyR + capR + 6, ey)
        }
    }
}
