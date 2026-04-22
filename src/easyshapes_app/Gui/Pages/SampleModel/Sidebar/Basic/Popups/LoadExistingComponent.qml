// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Elements as EaElements
import EasyApp.Gui.Style as EaStyle

import Gui.Globals as Globals



EaElements.Dialog{
    id: sampleModelLoadDialog

    property var targetModel

    title: qsTr("Load Components from the Asset Library")

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    property alias availableComponentsModel: availableComponentsModel

    standardButtons: Dialog.Ok // | Dialog.Cancel

    // Fields expected by targetModel (loadedComponentsModel in Components.qml):
    // name, component_type, mint, mext, atoms
    onAccepted: {
        console.log("Ok Clicked")

        var indexes = selectionModel.selectedIndexes

        if (indexes.length > 0) {
            var row = indexes[0].row
            var item = availableComponentsModel.get(row)

            console.log("Selected Component: ", item.name)

            targetModel.append({
                name: item.name,
                component_type: item.component_type,
                mint: item.mint,
                mext: item.mext,
                atoms: item.atoms
            })
            selectionModel.clear()
        }
    }
    onRejected: {
        console.log("Cancel Clicked")
        selectionModel.clear()
    }

    Column {


        EaElements.Label {
            enabled: false
            text: qsTr("Available in the Asset Library")
        }

        EaComponents.TableView {
            clip: true
            id: loadModelTableView
            defaultInfoText: qsTr("No models found")

            header: EaComponents.TableViewHeader {
                EaComponents.TableViewLabel {
                    id: modelNameColumnName
                    width: EaStyle.Sizes.fontPixelSize * 12
                    text: qsTr("Name")
                    color: EaStyle.Colors.themeForegroundMinor
                    leftPadding: EaStyle.Sizes.fontPixelSize * 0.7
                }

                EaComponents.TableViewLabel {
                    id: modelTypeColumnName
                    width: EaStyle.Sizes.fontPixelSize * 8
                    text: qsTr("Type")
                    color: EaStyle.Colors.themeForegroundMinor
                }

                EaComponents.TableViewLabel {
                    id: modelAtomsColumnName
                    width: EaStyle.Sizes.fontPixelSize * 6
                    text: qsTr("Atoms")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }

                EaComponents.TableViewLabel {
                    id: modelMintColumnName
                    width: EaStyle.Sizes.fontPixelSize * 6
                    text: qsTr("Mint")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }

                EaComponents.TableViewLabel {
                    id: modelMextColumnName
                    width: EaStyle.Sizes.fontPixelSize * 6
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

            property var itemSelectionModel: ItemSelectionModel {
                id: selectionModel
                model: availableComponentsModel
            }

            property bool activeSelection: true

            delegate: EaComponents.TableViewDelegate {

                required property int index
                required property string name
                required property string component_type
                required property int atoms
                required property int mint
                required property int mext

                color: {
                    if (!ListView.view.activeSelection) {
                        return index % 2 ?
                                    EaStyle.Colors.themeBackgroundHovered2 :
                                    EaStyle.Colors.themeBackgroundHovered1
                    }

                    ListView.view.itemSelectionModel.selection    // create dependency

                    return ListView.view.itemSelectionModel.isSelected(
                        ListView.view.itemSelectionModel.model.index(index, 0)
                    ) ? EaStyle.Colors.themeAccentMinor : EaStyle.Colors.themeBackgroundHovered1
                }

                EaComponents.TableViewLabel {
                    id: modelNameColumn
                    width: EaStyle.Sizes.fontPixelSize * 12
                    text: name
                    leftPadding: EaStyle.Sizes.fontPixelSize * 0.7
                }

                EaComponents.TableViewLabel {
                    id: typeColumn
                    width: EaStyle.Sizes.fontPixelSize * 8
                    text: component_type
                }

                EaComponents.TableViewLabel {
                    id: atomsColumn
                    width: EaStyle.Sizes.fontPixelSize * 6
                    text: atoms
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {
                    id: mintColumn
                    width: EaStyle.Sizes.fontPixelSize * 6
                    text: mint
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {
                    id: mextColumn
                    width: EaStyle.Sizes.fontPixelSize * 6
                    text: mext
                    horizontalAlignment: Text.AlignHCenter
                }

                mouseArea.onPressed: (mouse) => {
                    let idx = ListView.view.itemSelectionModel.model.index(index, 0)
                    ListView.view.itemSelectionModel.select(
                        idx,
                        ItemSelectionModel.ClearAndSelect
                    )
                }
            }
        }
    }
}
