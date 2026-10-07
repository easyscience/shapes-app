// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: combined engine output (GROMACS stdout + stderr; other
// engines later). The tab is always present, but stays empty until equilibration
// is finished.
// DRAFT CONTAINER — real engine streaming not implemented yet.
Rectangle {
    id: root

    readonly property bool equilibrated: Globals.BackendWrapper.activeBackend.analysis.equilibrated === true

    color: EaStyle.Colors.mainContentBackground

    // Before equilibration — no content, just a hint.
    EaElements.Label {
        anchors.centerIn: parent
        visible: !root.equilibrated
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("Run Equilibrate to see the engine output.")
    }

    // After equilibration — the combined stdout/stderr log (placeholder).
    EaElements.TextArea {
        anchors.fill: parent
        anchors.margins: EaStyle.Sizes.fontPixelSize
        visible: root.equilibrated
        readOnly: true
        font.family: EaStyle.Fonts.monoFontFamily
        text: qsTr("Engine stdout / stderr will stream here.\n\n" +
                   "(Placeholder — GROMACS wiring not implemented yet.)")
    }

}
