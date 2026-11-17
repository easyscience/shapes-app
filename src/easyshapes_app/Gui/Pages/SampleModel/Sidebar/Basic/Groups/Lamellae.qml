// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals

import "../Components" as Local

EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    EaComponents.ListView {
        id: lamellae
        defaultInfoText: qsTr("Add at least one lamella")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.columnWidthAuto,    // №
            EaStyle.Sizes.columnWidthAuto,    // Rmin, nm
            EaStyle.Sizes.columnWidthAuto,    // Inner Dmin, nm
            EaStyle.Sizes.columnWidthAuto,    // Outer Dmin, nm
            EaStyle.Sizes.columnWidthAuto,    // Shell thickness, nm
            EaStyle.Sizes.columnWidthAuto,    // Symmetric (checkbox)
            EaStyle.Sizes.tableRowHeight      // delete button
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Rmin, nm")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Inner dmin, nm")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Outer dmin, nm")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Shell thickness, nm")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Symmetric")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {}
        }

        model: Globals.BackendWrapper.lamellaeItems

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            id: lamellaRow
            required property int index
            required property double rmin
            required property double innerLeafletDmin
            required property double outerLeafletDmin
            // Worked out when the lamella is added, then as set
            required property double shellThickness
            required property bool symmetric
            // Worked out from rmin, shell and the outer leaflet's molecules
            required property var outerLeafletRmin
            // shortcut: 1.6 copies shapespyer's _RMIN_PER_DMIN (structure.py),
            // under which it refuses to build; read it from the backend if it changes
            readonly property bool innerCrowded: rmin < 1.6 * innerLeafletDmin
            readonly property bool outerCrowded: typeof outerLeafletRmin === 'number'
                                                 && outerLeafletRmin < 1.6 * outerLeafletDmin

            EaComponents.TableViewLabel {
                text: lamellaRow.index + 1
                enabled: false
            }
            // Rmin and inner dmin red too while rmin is under 1.6 inner dmin
            EaComponents.ListViewTextInput {
                text: lamellaRow.rmin
                warned: !acceptableInput || lamellaRow.innerCrowded
                onEditingFinished: lamellaRow.rmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: lamellaRow.innerLeafletDmin
                warned: !acceptableInput || lamellaRow.innerCrowded
                onEditingFinished: lamellaRow.innerLeafletDmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            // Outer dmin and shell red too while the outer leaflet starts
            // under 1.6 outer dmin
            EaComponents.ListViewTextInput {
                text: lamellaRow.outerLeafletDmin
                warned: !acceptableInput || lamellaRow.outerCrowded
                onEditingFinished: lamellaRow.outerLeafletDmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            // 0 or less is red and not sent. A thin shell is taken: the
            // leaflets crowd, as the Shape view shows
            EaComponents.ListViewTextInput {
                id: shellInput
                text: lamellaRow.shellThickness
                warned: !acceptableInput || lamellaRow.outerCrowded
                onEditingFinished: lamellaRow.shellThickness = parseFloat(text)
                validator: DoubleValidator { bottom: 0.01 }

                EaElements.ToolTip {
                    text: qsTr("From rmin to the outer leaflet's end. Worked out from the leaflets' "
                               + "molecules when the lamella is added; then it stays as set")
                    // By id: qmllint types a popup's parent as a plain Item
                    visible: shellInput.hovered && EaGlobals.Vars.showToolTips
                }
            }
            EaComponents.TableViewCheckBox {
                checked: lamellaRow.symmetric
                onToggled: lamellaRow.symmetric = checked
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this lamella")
                onClicked: Globals.BackendWrapper.lamellaeRemove(lamellaRow.index)
            }
        }
    }

    Grid {
        columns: 1

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Add lamella")
            width: root.thirdWidth
            onClicked: Globals.BackendWrapper.lamellaeAdd()
        }
    }

    Column {
        id: fractionsSection
        visible: lamellae.selectedIndexes.length > 0
        width: parent.width
        spacing: EaStyle.Sizes.groupBoxSpacing

        readonly property int selectedRow: lamellae.selectedIndexes.length > 0 ? lamellae.selectedIndexes[0].row : -1
        readonly property var selectedOuterComposition: Globals.BackendWrapper.lamellaeOuterLeafletCompositions[selectedRow] ?? null
        // A symmetric lamella has no outer composition of its own
        readonly property bool selectedSymmetric: !selectedOuterComposition

        Column {
            width: parent.width

            EaElements.Label {
                enabled: false
                text: fractionsSection.selectedSymmetric
                    ? qsTr("Lamella %1 Fractions").arg(fractionsSection.selectedRow + 1)
                    : qsTr("Lamella %1 Inner Leaflet Fractions").arg(fractionsSection.selectedRow + 1)
            }
            Local.Fractions {
                fractionsModel: Globals.BackendWrapper.lamellaeInnerLeafletCompositions[fractionsSection.selectedRow] ?? null
            }
        }

        Column {
            width: parent.width
            visible: !fractionsSection.selectedSymmetric

            EaElements.Label {
                enabled: false
                text: qsTr("Lamella %1 Outer Leaflet Fractions").arg(fractionsSection.selectedRow + 1)
            }
            Local.Fractions {
                fractionsModel: fractionsSection.selectedOuterComposition
            }
        }
    }
}
