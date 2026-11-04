// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements


// A title over a dropdown of rows, as the Components viewer's component
// selector. Each row shows its name with its status in the minor colour,
// as in Equilibration Files; a row without a status shows its name only.
// The Structure tab picks its stage with it, Engine output its log.
Column {
    id: root

    property alias title: titleLabel.text
    // Rows with the roles name and status, and a get(row)
    property var model: null
    property int currentIndex: -1
    // The current row's name and status, or null
    readonly property var selected: {
        root._revision
        return root.model && currentIndex >= 0 && currentIndex < root.model.count
               ? root.model.get(currentIndex) : null
    }

    signal activated(int index)

    // Rows change their status in place, which a read of one row doesn't
    // follow: each change counts here
    property int _revision: 0
    Connections {
        target: root.model
        function onDataChanged() { root._revision++ }
        function onRowsInserted() { root._revision++ }
        function onRowsRemoved() { root._revision++ }
        function onModelReset() { root._revision++ }
    }

    function _label(name, status) {
        return status ? `${name}&nbsp;&nbsp;<font color='$TEXT_COLOR'>${status}</font>` : name
    }

    EaElements.Label {
        id: titleLabel
        enabled: false
    }

    EaElements.ComboBox {
        id: picker
        width: EaStyle.Sizes.fontPixelSize * 14
        model: root.model
        currentIndex: root.currentIndex
        displayText: root.selected ? root._label(root.selected.name, root.selected.status) : ""
        onActivated: (index) => root.activated(index)

        // As EaElements.ComboBox's own, with the status after the name:
        // its textRole takes one role only
        delegate: EaElements.MenuItem {
            required property int index
            required property string name
            required property string status

            width: parent !== null ? parent.width : 0
            height: EaStyle.Sizes.comboBoxHeight
            font.family: picker.font.family
            textFormat: Text.RichText
            text: root._label(name, status).split('$TEXT_COLOR').join(EaStyle.Colors.themeForegroundMinor)
            highlighted: picker.highlightedIndex === index
            hoverEnabled: picker.hoverEnabled
        }
    }
}
