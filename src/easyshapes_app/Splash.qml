// SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
// SPDX-License-Identifier: BSD-3-Clause

import QtQuick
import QtQuick.VectorImage


// The logo while the app starts, in its own process (main.py
// --splash), which ends when the app's window is up. No EasyApp
// imports, so it shows fast
Window {
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + (Screen.height - height) / 2
    width: 128
    height: 128
    visible: true
    flags: Qt.SplashScreen | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"

    // The still logo at once: the animated one takes Qt seconds to build
    Image {
        anchors.fill: parent
        visible: animated.status !== Loader.Ready
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(width, height)
        source: Qt.resolvedUrl("Gui/Resources/Logos/EasyShapes.svg")
    }

    // Built once the still logo is on screen: building blocks drawing
    // for seconds. The SVG spins by its own animation
    Loader {
        id: animated

        anchors.fill: parent
        active: false
        sourceComponent: VectorImage {
            fillMode: VectorImage.PreserveAspectFit
            source: Qt.resolvedUrl("Gui/Resources/Logos/EasyShapes.svg")
            preferredRendererType: VectorImage.CurveRenderer
            animations.loops: Animation.Infinite
        }
    }

    // Ticks once per drawn frame: by the third tick, the first frame,
    // with the still logo, is on screen
    FrameAnimation {
        running: true
        onTriggered: {
            if (currentFrame > 2) {
                stop()
                animated.active = true
            }
        }
    }
}
