// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Components as EaComponents

EaComponents.ListView {
    defaultInfoText: qsTr("Missing components")
    selectionActive: false

    columnWidths: [
        EaStyle.Sizes.fontPixelSize * 6,
        -1,
        EaStyle.Sizes.fontPixelSize * 8,
        EaStyle.Sizes.fontPixelSize * 8,
    ]

    header: EaComponents.ListViewHeader {
        EaComponents.TableViewLabel {
            text: qsTr("Present")
            color: EaStyle.Colors.themeForegroundMinor
        }
        EaComponents.TableViewLabel {} // filler
        EaComponents.TableViewLabel {
            text: qsTr("Component name")
            color: EaStyle.Colors.themeForegroundMinor
        }
        EaComponents.TableViewLabel {
            text: qsTr("Molar ratio")
            color: EaStyle.Colors.themeForegroundMinor
        }
    }

    model: ListModel {
        ListElement { name: "POPC"; fracs: 100; present: true }
        ListElement { name: "DOPC"; fracs: 100; present: true }
        ListElement { name: "DPPC"; fracs: 100; present: true }
    }

    delegateModelAccess: DelegateModel.ReadWrite

    delegate: EaComponents.ListViewDelegate {
        required property int index
        required property string name
        required property double fracs
        required property bool present

        EaComponents.TableViewCheckBox {
            checked: present
            onToggled: present = checked
        }
        EaComponents.TableViewLabel {} // filler
        EaComponents.TableViewLabel {
            text: name
            enabled: false
        }
        EaComponents.ListViewTextInput {
            text: present ? fracs : 0
            enabled: present
            onEditingFinished: fracs = parseFloat(text)
            validator: DoubleValidator { bottom: 0 }
        }
    }
}
