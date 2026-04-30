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

import "../Components" as Local

EaElements.GroupColumn {
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164

    EaComponents.ListView {
        id: lamellae
        defaultInfoText: qsTr("Add at least one lamella")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.tableRowHeight,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {} // filler
            EaComponents.TableViewLabel {
                text: qsTr("Rmin")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Inner Dmin")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Outer Dmin")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Shell")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Sym")
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: ListModel {
            id: lamellaeModel
            ListElement { rmin: 0.5; innerDmin: 0.25; outerDmin: 0.25; shell: 0.5; symmetric: true }
        }

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
            EaComponents.TableViewLabel {} // filler
            EaComponents.ListViewTextInput {
                text: rmin
                onEditingFinished: rmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: innerDmin
                onEditingFinished: innerDmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: symmetric ? innerDmin : outerDmin
                enabled: !symmetric
                onEditingFinished: outerDmin = parseFloat(text)
                validator: DoubleValidator { bottom: 0.25 }
            }
            EaComponents.ListViewTextInput {
                text: shell
                onEditingFinished: shell = parseFloat(text)
                validator: DoubleValidator { bottom: 0 }
            }
            EaComponents.TableViewCheckBox {
                checked: symmetric
                onToggled: symmetric = checked
            }
            EaComponents.TableViewButton {
                id: deleteRowColumn
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this lamella")
                onClicked: lamellaeModel.remove(index)
            }
        }
    }

    Item {
        width: lamellae.width
        height: addLamellaButton.height

        EaElements.SideBarButton {
            id: addLamellaButton
            anchors.right: parent.right
            anchors.rightMargin: EaStyle.Sizes.tableColumnSpacing
            fontIcon: "plus-circle"
            text: qsTr("Add lamella")
            width: buttonWidth
            onClicked: lamellaeModel.append({ rmin: 0.5, innerDmin: 0.25, outerDmin: 0.25, shell: 0.5, symmetric: true })
        }
    }

    Column {
        id: fractionsSection
        visible: lamellae.selectedIndexes.length > 0
        width: parent.width

        readonly property int selectedRow: lamellae.selectedIndexes.length > 0 ? lamellae.selectedIndexes[0].row : -1
        readonly property bool selectedSymmetric: selectedRow >= 0 && lamellaeModel.get(selectedRow).symmetric

        EaElements.Label {
            enabled: false
            text: fractionsSection.selectedSymmetric
                ? qsTr("Lamella %1 Leaflet Fractions").arg(fractionsSection.selectedRow + 1)
                : qsTr("Lamella %1 Inner Leaflet Fractions").arg(fractionsSection.selectedRow + 1)
        }
        Local.Fractions {
            id: innerFractions
        }

        EaElements.Label {
            visible: !fractionsSection.selectedSymmetric
            enabled: false
            text: qsTr("Lamella %1 Outer Leaflet Fractions").arg(fractionsSection.selectedRow + 1)
        }
        Local.Fractions {
            id: outerFractions
            visible: !fractionsSection.selectedSymmetric
        }
    }
}
