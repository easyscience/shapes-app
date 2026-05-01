// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals

import "../Components" as Local

EaElements.GroupColumn {
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164
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
            EaComponents.TableViewLabel {} // filler
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
            fontIcon: "plus-circle"
            text: qsTr("Add layer")
            width: buttonWidth
            onClicked: layersModel.append({ dmin: 0.25, rmin: 0.5 })
        }
    }
    Column {
        visible: layers.selectedIndexes.length > 0
        width: parent.width

        EaElements.Label {
            id: layerFractionsLabel
            enabled: false
            text: qsTr("Layer %1 Fractions").arg(layers.selectedIndexes.length > 0 ? layers.selectedIndexes[0].row + 1 : 1)
        }
        Local.Fractions {
            id: fractions
        }
    }
}
