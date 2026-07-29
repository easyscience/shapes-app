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
            EaStyle.Sizes.tableColumnAuto,    // №
            EaStyle.Sizes.tableColumnFlex,    // filler
            EaStyle.Sizes.tableColumnAuto,    // Dmin, nm
            EaStyle.Sizes.tableColumnAuto,    // Rmin, nm
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
            EaComponents.TableViewLabel {}
        }

        model: Globals.BackendWrapper.layersItems

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property double dmin
            required property double rmin

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {}
            EaComponents.ListViewTextInput {
                text: dmin
                onEditingFinished: Globals.BackendWrapper.layersSetDmin(index, parseFloat(text))
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: rmin
                onEditingFinished: Globals.BackendWrapper.layersSetRmin(index, parseFloat(text))
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this layer")
                onClicked: Globals.BackendWrapper.layersRemove(index)
            }
        }
    }

    Grid {
        columns: 1

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Add layer")
            width: root.thirdWidth
            onClicked: Globals.BackendWrapper.layersAppend({ dmin: 0.5, rmin: 0.25 })
        }
    }

    Column {
        id: fractionsSection
        visible: layers.selectedIndexes.length > 0
        width: parent.width

        readonly property int selectedRow: layers.selectedIndexes.length > 0 ? layers.selectedIndexes[0].row : -1
        readonly property var selectedFractionsModel: {
            // Re-evaluate when the per-layer Fractions array is rebuilt.
            void Globals.BackendWrapper.layersFractionsRevision
            return selectedRow >= 0 ? Globals.BackendWrapper.layersFractionsModelAt(selectedRow) : null
        }

        EaElements.Label {
            enabled: false
            text: qsTr("Layer %1 Fractions").arg(fractionsSection.selectedRow >= 0 ? fractionsSection.selectedRow + 1 : 1)
        }
        Local.Fractions {
            fractionsModel: fractionsSection.selectedFractionsModel
        }
    }
}
