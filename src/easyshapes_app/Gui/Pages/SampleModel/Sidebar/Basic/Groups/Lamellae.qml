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
            required property int index
            required property double rmin
            required property double innerLeafletDmin
            required property double outerLeafletDmin
            required property double shellThickness
            required property bool symmetric

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.ListViewTextInput {
                text: rmin
                warned: !acceptableInput
                onEditingFinished: rmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: innerLeafletDmin
                warned: !acceptableInput
                onEditingFinished: innerLeafletDmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: outerLeafletDmin
                warned: !acceptableInput
                onEditingFinished: outerLeafletDmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: shellThickness
                warned: !acceptableInput
                onEditingFinished: shellThickness = parseFloat(text)
                validator: DoubleValidator { bottom: 0 }
            }
            EaComponents.TableViewCheckBox {
                checked: symmetric
                onToggled: symmetric = checked
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this lamella")
                onClicked: Globals.BackendWrapper.lamellaeRemove(index)
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
