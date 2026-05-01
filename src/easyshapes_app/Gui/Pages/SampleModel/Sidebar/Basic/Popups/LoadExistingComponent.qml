// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Style as EaStyle

import Gui.Globals as Globals


EaElements.Dialog{
    id: sampleModelLoadDialog

    property var targetModel
    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35
    property alias availableComponentsModel: availableComponentsModel

    title: qsTr("Load Components from the Asset Library")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        let selected = loadComponentListView.selectedIndexes
        for (let i = 0; i < selected.length; ++i) {
            var row = selected[i].row
            var item = availableComponentsModel.get(row)

            targetModel.append({
                name: item.name,
                component_type: item.component_type,
                mint: item.mint,
                mext: item.mext,
                atoms: item.atoms
            })
        }
        loadComponentListView.clearSelection()
    }
    onRejected: {
        loadComponentListView.clearSelection()
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Available in the Asset Library")
        }

        EaComponents.ListView {
            id: loadComponentListView
            defaultInfoText: qsTr("No models found")
            multiSelection: true

            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
                -1,
                EaStyle.Sizes.fontPixelSize * 8,
                EaStyle.Sizes.fontPixelSize * 6,
                EaStyle.Sizes.fontPixelSize * 6,
                EaStyle.Sizes.fontPixelSize * 6,
                EaStyle.Sizes.tableRowHeight,
            ]

            header: EaComponents.ListViewHeader {
                EaComponents.TableViewLabel {
                    text: qsTr("№")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {
                    text: qsTr("Name")
                    color: EaStyle.Colors.themeForegroundMinor
                }
                EaComponents.TableViewLabel {
                    text: qsTr("Type")
                    color: EaStyle.Colors.themeForegroundMinor
                }
                EaComponents.TableViewLabel {
                    text: qsTr("Atoms")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {
                    text: qsTr("Mint")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {
                    text: qsTr("Mext")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            model: ListModel {
                id: availableComponentsModel
                ListElement { name: "DPPC"; component_type: "Lipid"; atoms: 130; mint: 0; mext: 130 }
                ListElement { name: "DOPC"; component_type: "Lipid"; atoms: 138; mint: 0; mext: 138 }
                ListElement { name: "POPC"; component_type: "Lipid"; atoms: 134; mint: 0; mext: 134 }
                ListElement { name: "DMPC"; component_type: "Lipid"; atoms: 118; mint: 0; mext: 118 }
                ListElement { name: "Cholesterol"; component_type: "Lipid"; atoms: 74; mint: 0; mext: 74 }
                ListElement { name: "SDS"; component_type: "Surfactant"; atoms: 42; mint: 0; mext: 42 }
                ListElement { name: "CTAB"; component_type: "Surfactant"; atoms: 62; mint: 0; mext: 62 }
                ListElement { name: "Triton-X100"; component_type: "Surfactant"; atoms: 85; mint: 0; mext: 85 }
                ListElement { name: "Tween-20"; component_type: "Surfactant"; atoms: 98; mint: 0; mext: 98 }
                ListElement { name: "D2O-buffer"; component_type: "Other"; atoms: 3; mint: 0; mext: 3 }
            }

            delegateModelAccess: DelegateModel.ReadOnly

            delegate: EaComponents.ListViewDelegate {
                required property int index
                required property string name
                required property string component_type
                required property int atoms
                required property int mint
                required property int mext

                EaComponents.TableViewLabel {
                    text: index + 1
                    horizontalAlignment: Text.AlignHCenter
                    enabled: false
                }
                EaComponents.TableViewLabel {
                    text: name
                }
                EaComponents.TableViewLabel {
                    text: component_type
                }
                EaComponents.TableViewLabel {
                    text: atoms
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {
                    text: mint
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {
                    text: mext
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewButton {
                    fontIcon: "minus-circle"
                    ToolTip.text: qsTr("Remove this component")
                    onClicked: availableComponentsModel.remove(index)
                }
            }
        }
    }
}
