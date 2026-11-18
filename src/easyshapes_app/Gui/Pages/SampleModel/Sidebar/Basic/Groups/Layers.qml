// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Globals as EaGlobals

import Gui.Globals as Globals

import "../Components" as Local

EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    EaComponents.ListView {
        id: layers
        defaultInfoText: qsTr("Add at least one layer")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.columnWidthAuto,    // №
            EaStyle.Sizes.columnWidthFlex,    // filler
            EaStyle.Sizes.columnWidthAuto,    // Dmin, nm
            EaStyle.Sizes.columnWidthAuto,    // Rmin, nm
            EaStyle.Sizes.columnWidthAuto,    // Thickness, nm
            EaStyle.Sizes.tableRowHeight      // delete button
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {}
            EaComponents.TableViewLabel {
                text: qsTr("Dmin, nm")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Rmin, nm")
                color: EaStyle.Colors.themeForegroundMinor
            }
            // The tooltip sits here: the greyed cells get no hover
            EaComponents.TableViewLabel {
                id: thicknessTitle
                text: qsTr("Thickness, nm")
                color: EaStyle.Colors.themeForegroundMinor

                EaElements.ToolTip {
                    text: qsTr("Longest ticked molecule, first atom to last")
                    // By id: qmllint types a popup's parent as a plain Item
                    visible: thicknessTitle.hovered && EaGlobals.Vars.showToolTips
                }
            }
            EaComponents.TableViewLabel {}
        }

        model: Globals.BackendWrapper.layersItems

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            id: layerRow
            required property int index
            required property double dmin
            required property double rmin
            // null while no component the layer places has a molecule length
            required property var thickness
            // shortcut: 1.6 copies shapespyer's _RMIN_PER_DMIN (structure.py),
            // under which it refuses to build; read it from the backend if it changes
            readonly property bool crowded: rmin < 1.6 * dmin

            EaComponents.TableViewLabel {
                text: layerRow.index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {}
            // Red too while rmin is under 1.6 dmin
            EaComponents.ListViewTextInput {
                text: layerRow.dmin
                warned: !acceptableInput || layerRow.crowded
                onEditingFinished: layerRow.dmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: layerRow.rmin
                warned: !acceptableInput || layerRow.crowded
                onEditingFinished: layerRow.rmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            // Greyed: the longest ticked molecule, first atom to last, not for editing
            EaComponents.TableViewLabel {
                text: typeof layerRow.thickness === 'number' ? layerRow.thickness.toFixed(2) : "—"
                enabled: false
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this layer")
                onClicked: Globals.BackendWrapper.layersRemove(layerRow.index)
            }
        }
    }

    Grid {
        columns: 1

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Add layer")
            width: root.thirdWidth
            onClicked: Globals.BackendWrapper.layersAdd()
        }
    }

    Column {
        id: fractionsSection
        visible: layers.selectedIndexes.length > 0
        width: parent.width

        readonly property int selectedRow: layers.selectedIndexes.length > 0 ? layers.selectedIndexes[0].row : -1

        EaElements.Label {
            enabled: false
            text: qsTr("Layer %1 Fractions").arg(fractionsSection.selectedRow >= 0 ? fractionsSection.selectedRow + 1 : 1)
        }
        Local.Fractions {
            fractionsModel: Globals.BackendWrapper.layersCompositions[fractionsSection.selectedRow] ?? null
        }
    }
}
