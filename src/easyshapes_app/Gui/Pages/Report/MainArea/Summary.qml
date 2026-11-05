// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: the project as an outline of what its save writes,
// a text wall as in Engine output. Read again each time the page comes
// to the front, so it holds the latest changes. When the project can't
// be outlined, the reason shows in its place, in red.
Rectangle {
    id: root

    color: EaStyle.Colors.mainContentBackground

    // In front: the current item of every SwipeView it sits in, as in
    // the Structure tab
    readonly property bool _shown: {
        for (let item = parent; item; item = item.parent)
            if (item.SwipeView.view && !item.SwipeView.isCurrentItem)
                return false
        return true
    }
    on_ShownChanged: if (_shown) Globals.BackendWrapper.reportRefresh()
    Component.onCompleted: if (_shown) Globals.BackendWrapper.reportRefresh()

    // A Flickable with EasyApp's scroll bars, as in Engine output
    Flickable {
        anchors.fill: parent
        anchors.margins: EaStyle.Sizes.fontPixelSize
        clip: true

        TextArea.flickable: EaElements.TextArea {
            readOnly: true
            wrapMode: TextEdit.NoWrap
            font.family: EaStyle.Fonts.monoFontFamily
            // Selectable either way, so an error can be copied
            text: Globals.BackendWrapper.reportError || Globals.BackendWrapper.reportText
            color: Globals.BackendWrapper.reportError ? EaStyle.Colors.red : EaStyle.Colors.textViewForeground
        }

        ScrollBar.vertical: EaElements.ScrollBar {
            policy: size < 1.0 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
        }
        ScrollBar.horizontal: EaElements.ScrollBar {
            policy: size < 1.0 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
        }
    }
}
