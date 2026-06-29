// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: scattering data. The tab is always present, but stays empty
// until equilibration is finished, then shows the scattering image.
// DRAFT CONTAINER — the image is a static mockup asset for now.
// Drop the picture at Gui/Resources/Images/scattering.png to display it here.
Rectangle {
    id: root

    readonly property bool equilibrated: Globals.BackendWrapper.activeBackend.analysis.equilibrated === true

    color: EaStyle.Colors.mainContentBackground
    clip: true  // crop the image overflow from PreserveAspectCrop

    // Before equilibration — no content, just a hint.
    EaElements.Label {
        anchors.centerIn: parent
        visible: !root.equilibrated
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("Run Equilibrate to see the scattering data.")
    }

    // After equilibration — the scattering image (mockup asset). PreserveAspectCrop
    // scales the image to cover the whole window (matching width or height,
    // whichever needs the larger scale, based on the window vs image aspect ratio)
    // and crops the overflow — so the window is always fully filled, no bars.
    Image {
        id: scatteringImage
        anchors.fill: parent
        visible: root.equilibrated && status === Image.Ready
        fillMode: Image.PreserveAspectCrop
        source: "../../../Resources/Images/scattering.jpg"
    }

    // Fallback while the image asset isn't present yet.
    EaElements.Label {
        anchors.centerIn: parent
        visible: root.equilibrated && scatteringImage.status !== Image.Ready
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("Drop scattering.png into Gui/Resources/Images/ to show it here.")
    }

}
