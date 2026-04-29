// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Elements as EaElements
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Logic as EaLogic

import Gui.Globals as Globals

EaElements.GroupColumn {
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164
    EaComponents.ListView {
        id: layers
        defaultInfoText: qsTr("Add at least one layer")
        selectable: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 6,
            EaStyle.Sizes.fontPixelSize * 6,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {} // filler
            EaComponents.TableViewLabel {
                text: qsTr("Dmin")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Rmin")
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: ListModel {
            id: layersModel
            ListElement { dmin: 0.25; rmin: 0.5; }
        }

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property double dmin
            required property double rmin

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {} // filler
            EaComponents.ListViewTextInput {
                text: dmin
                onEditingFinished: dmin = parseFloat(text)
                validator: DoubleValidator  { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: rmin
                onEditingFinished: rmin = parseFloat(text)
                validator: DoubleValidator  { bottom: 0.25 }
            }
            EaComponents.TableViewButton {
                id: deleteRowColumn
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this layer")
                onClicked: layersModel.remove(index)
            }
        }
    }
    Item {
        width: layers.width
        height: addLayerButton.height

        EaElements.SideBarButton {
            id: addLayerButton
            anchors.right: parent.right
            anchors.rightMargin: EaStyle.Sizes.tableColumnSpacing
            fontIcon: 'plus-circle'
            text: qsTr('Add layer')
            width: buttonWidth
            onClicked: layersModel.append({ dmin: 0.25, rmin: 0.5 })
        }
    }
    EaComponents.ListView {
        id: fractions
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
            id: fractionsModel
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
            EaComponents.TableViewLabel{} // filler
            EaComponents.TableViewLabel{
                text: name
                enabled: false
            }
            EaComponents.ListViewTextInput {
                text: present ? fracs : 0
                enabled: present
                onEditingFinished: fracs = parseFloat(text)
                validator: DoubleValidator  { bottom: 0 }
            }
        }
    }
}
