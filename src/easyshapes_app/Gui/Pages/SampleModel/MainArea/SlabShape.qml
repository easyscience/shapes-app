// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle


// Schematic of a flat unit for the Bilayer and Monolayer Shape views, as
// RodShape is for the rod: an isometric slab, its square side the unit's
// width and its height the thickness. With both known the thickness is
// drawn to scale, kept between a twentieth and half the width so the slab
// stays readable; otherwise a typical 6 x 2. Dimensions give the known
// values.
Canvas {
    id: slab

    // In nm; null while unknown. Not width and thickness: width is the
    // canvas's own
    property var slabWidth: null
    property var slabThickness: null
    property bool showDimensions: false

    property color strokeColor: EaStyle.Colors.themeForegroundDisabled
    property color dimColor: EaStyle.Colors.themeForegroundMinor
    property color clearColor: EaStyle.Colors.mainContentBackground

    onSlabWidthChanged: requestPaint()
    onSlabThicknessChanged: requestPaint()
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

        const widthKnown = typeof slab.slabWidth === 'number' && slab.slabWidth > 0
        const thicknessKnown = typeof slab.slabThickness === 'number' && slab.slabThickness > 0
        const ratio = widthKnown && thicknessKnown
                      ? Math.min(0.5, Math.max(0.05, slab.slabThickness / slab.slabWidth))
                      : 2 / 6

        // Isometric axes: the two sides 30° up to the right and to the
        // left from the front corner, the thickness straight up. Scaled
        // to fit the target width and height, as the rod is
        const c = Math.cos(Math.PI / 6), s = Math.sin(Math.PI / 6)
        const side = Math.min(width * 0.6 / (2 * c), height * 0.6 / (2 * s + ratio))
        const t = side * ratio
        const leftPad = 18
        const p0 = { x: leftPad + side * c, y: height * 0.82 }
        function at(a, b, up) {   // front corner + a, b sides and up thickness
            return { x: p0.x + (a - b) * side * c, y: p0.y - (a + b) * side * s - up * t }
        }

        ctx.lineWidth = 2
        ctx.strokeStyle = slab.strokeColor
        ctx.beginPath()
        // The bottom edges in sight, then the three upright ones
        const left = at(0, 1, 0), right = at(1, 0, 0)
        ctx.moveTo(left.x, left.y); ctx.lineTo(p0.x, p0.y); ctx.lineTo(right.x, right.y)
        for (const p of [left, p0, right]) {
            ctx.moveTo(p.x, p.y); ctx.lineTo(p.x, p.y - t)
        }
        // The top face
        const top = [at(0, 0, 1), at(1, 0, 1), at(1, 1, 1), at(0, 1, 1)]
        ctx.moveTo(top[0].x, top[0].y)
        for (const p of top.slice(1))
            ctx.lineTo(p.x, p.y)
        ctx.closePath()
        ctx.stroke()

        if (!slab.showDimensions)
            return

        ctx.strokeStyle = slab.dimColor
        ctx.fillStyle = slab.dimColor
        ctx.lineWidth = 1
        const px = Math.max(10, EaStyle.Sizes.fontPixelSize * 0.8)
        ctx.font = px + "px sans-serif"
        ctx.textBaseline = "middle"

        function dimHead(tx, ty, ang) {
            const hl = 7, ha = Math.PI / 7
            ctx.beginPath()
            ctx.moveTo(tx, ty)
            ctx.lineTo(tx - hl * Math.cos(ang - ha), ty - hl * Math.sin(ang - ha))
            ctx.lineTo(tx - hl * Math.cos(ang + ha), ty - hl * Math.sin(ang + ha))
            ctx.closePath()
            ctx.fill()
        }

        // The width along the front-right bottom edge, set off below it
        if (widthKnown) {
            const nx = s, ny = c               // the edge's outward normal
            const a = { x: p0.x + nx * 14, y: p0.y + ny * 14 }
            const b = { x: right.x + nx * 14, y: right.y + ny * 14 }
            ctx.beginPath()
            ctx.moveTo(p0.x + nx * 4, p0.y + ny * 4); ctx.lineTo(p0.x + nx * 18, p0.y + ny * 18)
            ctx.moveTo(right.x + nx * 4, right.y + ny * 4); ctx.lineTo(right.x + nx * 18, right.y + ny * 18)
            ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y)
            ctx.stroke()
            const ang = Math.atan2(b.y - a.y, b.x - a.x)
            dimHead(b.x, b.y, ang)
            dimHead(a.x, a.y, ang + Math.PI)
            // label with a cleared gap punched behind it
            const text = qsTr("%1 nm").arg(slab.slabWidth.toFixed(2))
            const w = ctx.measureText(text).width + 6
            const lx = (a.x + b.x) / 2, ly = (a.y + b.y) / 2
            ctx.fillStyle = slab.clearColor
            ctx.fillRect(lx - w / 2, ly - px * 0.75, w, px * 1.5)
            ctx.fillStyle = slab.dimColor
            ctx.textAlign = "center"
            ctx.fillText(text, lx, ly)
        }

        // The thickness beside the right upright edge, its value past it
        if (thicknessKnown) {
            const x = right.x + 14
            ctx.beginPath()
            ctx.moveTo(right.x + 4, right.y); ctx.lineTo(x + 4, right.y)
            ctx.moveTo(right.x + 4, right.y - t); ctx.lineTo(x + 4, right.y - t)
            ctx.moveTo(x, right.y); ctx.lineTo(x, right.y - t)
            ctx.stroke()
            dimHead(x, right.y - t, -Math.PI / 2)
            dimHead(x, right.y, Math.PI / 2)
            ctx.textAlign = "left"
            ctx.fillText(qsTr("%1 nm").arg(slab.slabThickness.toFixed(2)), x + 8, right.y - t / 2)
        }
    }
}
