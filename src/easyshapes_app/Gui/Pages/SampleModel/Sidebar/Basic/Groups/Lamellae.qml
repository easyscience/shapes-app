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
            EaStyle.Sizes.tableColumnAuto,    // №
            EaStyle.Sizes.tableColumnAuto,    // Rmin, nm
            EaStyle.Sizes.tableColumnAuto,    // Inner Dmin, nm
            EaStyle.Sizes.tableColumnAuto,    // Outer Dmin, nm
            EaStyle.Sizes.tableColumnAuto,    // Shell thickness, nm
            EaStyle.Sizes.tableColumnAuto,    // Symmetric (checkbox)
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
            required property double innerDmin
            required property double outerDmin
            required property double shell
            required property bool symmetric

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.ListViewTextInput {
                text: rmin
                onEditingFinished: Globals.BackendWrapper.lamellaeSetRmin(index, parseFloat(text))
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: innerDmin
                onEditingFinished: Globals.BackendWrapper.lamellaeSetInnerDmin(index, parseFloat(text))
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: outerDmin
                onEditingFinished: Globals.BackendWrapper.lamellaeSetOuterDmin(index, parseFloat(text))
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: shell
                onEditingFinished: Globals.BackendWrapper.lamellaeSetShell(index, parseFloat(text))
                validator: DoubleValidator { bottom: 0 }
            }
            EaComponents.TableViewCheckBox {
                checked: symmetric
                onToggled: Globals.BackendWrapper.lamellaeSetSymmetric(index, checked)
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
            onClicked: Globals.BackendWrapper.lamellaeAppend({ rmin: 0.5, innerDmin: 0.25, outerDmin: 0.3, shell: 1.0, symmetric: true })
        }
    }

    Column {
        id: fractionsSection
        visible: lamellae.selectedIndexes.length > 0
        width: parent.width
        spacing: EaStyle.Sizes.groupBoxSpacing

        readonly property int selectedRow: lamellae.selectedIndexes.length > 0 ? lamellae.selectedIndexes[0].row : -1
        readonly property bool selectedSymmetric: {
            // Re-evaluate when the selected row's symmetric flag changes.
            void Globals.BackendWrapper.lamellaeItemsRevision
            return selectedRow >= 0 && selectedRow < Globals.BackendWrapper.lamellaeItems.count
                ? Globals.BackendWrapper.lamellaeItems.get(selectedRow).symmetric
                : true
        }
        readonly property var selectedInnerFractionsModel: {
            // Re-evaluate when the per-lamella Fractions arrays are rebuilt.
            void Globals.BackendWrapper.lamellaeFractionsRevision
            return selectedRow >= 0 ? Globals.BackendWrapper.lamellaeInnerFractionsModelAt(selectedRow) : null
        }
        readonly property var selectedOuterFractionsModel: {
            void Globals.BackendWrapper.lamellaeFractionsRevision
            return selectedRow >= 0 ? Globals.BackendWrapper.lamellaeOuterFractionsModelAt(selectedRow) : null
        }

        Column {
            width: parent.width

            EaElements.Label {
                enabled: false
                text: fractionsSection.selectedSymmetric
                    ? qsTr("Lamella %1 Fractions").arg(fractionsSection.selectedRow + 1)
                    : qsTr("Lamella %1 Inner Leaflet Fractions").arg(fractionsSection.selectedRow + 1)
            }
            Local.Fractions {
                fractionsModel: fractionsSection.selectedInnerFractionsModel
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
                fractionsModel: fractionsSection.selectedOuterFractionsModel
            }
        }
    }
}
