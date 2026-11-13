// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle


// Schematic of a round unit for the Ring, Ball and Vesicle Shape views, as
// RodShape is for the rod: a circle whose radius stands for the unit's
// outer radius. Drawn at a fixed size, as nothing beside it gives a scale;
// with the radius known, a radius dimension gives its value.
Canvas {
    id: circle

    // In nm; null while unknown
    property var outerRadius: null
    property bool showDimensions: false

    property color strokeColor: EaStyle.Colors.themeForegroundDisabled
    property color dimColor: EaStyle.Colors.themeForegroundMinor

    onOuterRadiusChanged: requestPaint()
    onShowDimensionsChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)

        // Left-aligned with padding, as the rod; room for the label right
        const leftPad = 18
        const r = Math.min(height * 0.3, width * 0.25)
        const cx = leftPad + r
        const cy = height * 0.6

        ctx.lineWidth = 2
        ctx.strokeStyle = circle.strokeColor
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
        ctx.stroke()

        const known = typeof circle.outerRadius === 'number'
        if (!circle.showDimensions || !known)
            return

        // From the centre out at 45°, the value past the circle
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

        const px = Math.max(10, EaStyle.Sizes.fontPixelSize * 0.8)
        ctx.font = px + "px sans-serif"
        ctx.textAlign = "left"
        ctx.textBaseline = "middle"
        ctx.fillText(qsTr("%1 nm").arg(circle.outerRadius.toFixed(2)), ex + 6, ey)
    }
}
