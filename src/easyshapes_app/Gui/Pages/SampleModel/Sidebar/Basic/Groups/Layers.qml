// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

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
            EaComponents.TableViewLabel {
                text: qsTr("Thickness, nm")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {}
        }

        model: Globals.BackendWrapper.layersItems

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property double dmin
            required property double rmin
            // null while no component the layer places has a bone length
            required property var thickness

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {}
            EaComponents.ListViewTextInput {
                text: dmin
                warned: !acceptableInput
                onEditingFinished: dmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: rmin
                warned: !acceptableInput
                onEditingFinished: rmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            // Greyed: the longest bone, worked out, not for editing
            EaComponents.TableViewLabel {
                text: typeof thickness === 'number' ? thickness.toFixed(2) : "—"
                enabled: false
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this layer")
                onClicked: Globals.BackendWrapper.layersRemove(index)
            }
        }
    }

    // The last layer's rmin plus its thickness
    EaElements.Label {
        readonly property var fullRadius: Globals.BackendWrapper.layersFullRadius
        text: qsTr("Full radius, nm: %1").arg(typeof fullRadius === 'number' ? fullRadius.toFixed(2) : "—")
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
