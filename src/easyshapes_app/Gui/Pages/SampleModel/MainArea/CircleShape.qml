// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle


// Schematic of a round unit for the Ring, Ball and Vesicle Shape views, as
// RodShape is for the rod: two circles per ring, layer or lamella, one at
// its rmin and one at its outer edge. Drawn at a fixed size, as nothing
// beside it gives a scale: the outer radius fills it, and only that radius
// gets a dimension.
Canvas {
    id: circle

    // In nm; null while unknown
    property var outerRadius: null
    // [rmin, outer edge] in nm per ring, layer or lamella; an outer edge is
    // null while unknown
    property var rings: []
    property bool showDimensions: false

    property color strokeColor: EaStyle.Colors.themeForegroundDisabled
    property color dimColor: EaStyle.Colors.themeForegroundMinor

    onOuterRadiusChanged: requestPaint()
    onRingsChanged: requestPaint()
    onShowDimensionsChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)

        // A fifth smaller than the rod, in the lower left corner: the same
        // gap below and to the left, 0.6 of what a centre at 60% height
        // leaves below
        const r = 0.8 * Math.min(height * 0.3, width * 0.25)
        const gap = 0.6 * (height * 0.4 - r)
        const cx = gap + r
        const cy = height - gap - r

        ctx.strokeStyle = circle.strokeColor
        function drawCircle(radius, lineWidth) {
            ctx.lineWidth = lineWidth
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
            ctx.stroke()
        }

        // The outer radius sets the scale; while unknown, the largest
        // radius known does
        const known = typeof circle.outerRadius === 'number'
        const radii = [].concat(...(circle.rings || [])).filter(v => typeof v === 'number' && v > 0)
        const reference = known ? circle.outerRadius : Math.max(0, ...radii)
        if (reference <= 0) {
            drawCircle(r, 2)
            return
        }
        const scale = r / reference
        // rmin circles thin, outer edges as the rod's outline
        for (const [inner, outer] of circle.rings || []) {
            if (typeof inner === 'number')
                drawCircle(inner * scale, 1)
            if (typeof outer === 'number')
                drawCircle(outer * scale, 2)
        }

        if (!circle.showDimensions || !known)
            return

        // From the centre out at 45° to the outer circle
        const ang = -Math.PI / 4
        const ex = cx + r * Math.cos(ang)
        const ey = cy + r * Math.sin(ang)
        ctx.strokeStyle = circle.dimColor
        ctx.fillStyle = circle.dimColor
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(cx, cy); ctx.lineTo(ex, ey)
        ctx.stroke()

        const hl = 7, ha = Math.PI / 7
        ctx.beginPath()
        ctx.moveTo(ex, ey)
        ctx.lineTo(ex - hl * Math.cos(ang - ha), ey - hl * Math.sin(ang - ha))
        ctx.lineTo(ex - hl * Math.cos(ang + ha), ey - hl * Math.sin(ang + ha))
        ctx.closePath()
        ctx.fill()

        // The value on top of the line, parallel to it
        const px = Math.max(10, EaStyle.Sizes.fontPixelSize * 0.8)
        const lift = px * 0.8
        ctx.save()
        ctx.translate((cx + ex) / 2 + Math.sin(ang) * lift, (cy + ey) / 2 - Math.cos(ang) * lift)
        ctx.rotate(ang)
        ctx.font = px + "px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(qsTr("%1 nm").arg(circle.outerRadius.toFixed(2)), 0, 0)
        ctx.restore()
    }
}
