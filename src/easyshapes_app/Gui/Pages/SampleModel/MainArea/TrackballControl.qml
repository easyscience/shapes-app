// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick3D


// Mouse control of a 3D view whose camera sits inside `origin`, as in the
// Components viewer. Lay it over the View3D. Left-drag turns the view,
// right-drag pans, the wheel asks for a zoom through `zoomed`, which the
// owner applies to its camera distance. Clicks and hover still reach the
// items below: a drag handler doesn't take them until a drag starts.
Item {
    id: root

    // The node the camera orbits, and the camera inside it
    property Node origin
    property Camera camera
    // Left-drag rotation, in degrees per pixel
    property real rotateSpeed: 0.6
    // Right-drag pan multiplier (1.0 = baseline)
    property real panSpeed: 2.0

    // Wheel: the factor to multiply the camera distance by
    signal zoomed(real factor)

    // Quaternion for a rotation of `deg` degrees about world axis `axis`.
    function _axisAngle(axis, deg) {
        const a = axis.normalized()
        const r = deg * Math.PI / 180
        const s = Math.sin(r / 2)
        return Qt.quaternion(Math.cos(r / 2), a.x * s, a.y * s, a.z * s)
    }

    // Hamilton product a * b (applies b, then a).
    function _qmul(a, b) {
        return Qt.quaternion(
            a.scalar * b.scalar - a.x * b.x - a.y * b.y - a.z * b.z,
            a.scalar * b.x + a.x * b.scalar + a.y * b.z - a.z * b.y,
            a.scalar * b.y - a.x * b.z + a.y * b.scalar + a.z * b.x,
            a.scalar * b.z + a.x * b.y - a.y * b.x + a.z * b.scalar)
    }

    // Left-drag trackball rotation. Each mouse delta rotates about the
    // CURRENT screen axes (camera right/up, read as world-space basis from
    // the origin) and is composed onto the current rotation. Because the
    // axes always follow the view, left-right stays consistent at any
    // orientation — no gimbal flip when tumbling past the poles.
    DragHandler {
        target: null
        acceptedButtons: Qt.LeftButton
        property real _lx: 0
        property real _ly: 0
        onActiveChanged: { _lx = 0; _ly = 0 }
        onTranslationChanged: {
            const dx = translation.x - _lx
            const dy = translation.y - _ly
            _lx = translation.x
            _ly = translation.y
            const qYaw = root._axisAngle(root.origin.up, -dx * root.rotateSpeed)
            const qPitch = root._axisAngle(root.origin.right, -dy * root.rotateSpeed)
            const dq = root._qmul(qYaw, qPitch)
            root.origin.rotation = root._qmul(dq, root.origin.rotation)
        }
    }

    // Right-drag pan (panSpeed x baseline): move the rig in the view plane,
    // faster the farther the camera is.
    DragHandler {
        target: null
        acceptedButtons: Qt.RightButton
        property real _lx: 0
        property real _ly: 0
        onActiveChanged: { _lx = 0; _ly = 0 }
        onTranslationChanged: {
            const dx = translation.x - _lx
            const dy = translation.y - _ly
            _lx = translation.x
            _ly = translation.y
            const k = root.camera.z * 0.0022 * root.panSpeed
            root.origin.position = root.origin.position
                .minus(root.origin.right.times(dx * k))
                .plus(root.origin.up.times(dy * k))
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        onWheel: function (ev) {
            root.zoomed(ev.angleDelta.y > 0 ? 0.9 : 1.1)
        }
    }
}
