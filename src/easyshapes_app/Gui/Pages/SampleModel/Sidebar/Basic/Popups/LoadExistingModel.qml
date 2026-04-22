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

    title: qsTr("Load a Sample Model from the Asset Library")

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    property alias availableModelsModel: availableSambleModelsModel

    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        console.log("Ok Clicked")

        var indexes = selectionModel.selectedIndexes

        if (indexes.length > 0) {
            var row = indexes[0].row
            var item = availableSambleModelsModel.get(row)

            console.log("Selected SampleModel: ", item.name)

            targetModel.clear()
            targetModel.append(item)
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
                    width: EaStyle.Sizes.fontPixelSize * 10
                    text: qsTr("Name")
                    color: EaStyle.Colors.themeForegroundMinor
                    leftPadding: EaStyle.Sizes.fontPixelSize * 0.7
                }

                EaComponents.TableViewLabel {
                    id: modelTypeColumnName
                    width: EaStyle.Sizes.fontPixelSize * 6
                    text: qsTr("Type")
                    color: EaStyle.Colors.themeForegroundMinor
                }

                EaComponents.TableViewLabel {
                    id: modelDescrColumnName
                    width: EaStyle.Sizes.fontPixelSize * 22
                    text: qsTr("Description")
                    color: EaStyle.Colors.themeForegroundMinor
                }
            }

            model: ListModel {
                id: availableSambleModelsModel
                ListElement { name: "Samle1_aluv"; structure_type: "Vesicle"; description: "In order to avoid a prolonged pro-inflammatory neutrophil response, signaling downstream of an agonist-activated G protein-coupled receptor (GPCR) has to be rapidly terminated. Among the family of GPCR kinases (GRKs) that regulate receptor phosphorylation and signaling termination, GRK2, which is highly expressed by immune cells, plays an important role." }
                ListElement { name: "Sample2_nanodisc"; structure_type: "Ring"; description: "The medium chain fatty acid receptor GPR84 as well as formyl peptide receptor 2 (FPR2)" }
                ListElement { name: "Sample3_cubosome"; structure_type: "Lattice"; description: "receptors expressed in neutrophils, play a key role in regulating inflammation. In this study, we investigated the effects of GRK2 inhibitors on neutrophil functions induced by GPR84 and FPR2 agonists." }
                ListElement { name: "Sample4"; structure_type: "Ring"; description: "GRK2 was shown to be expressed in human neutrophils and analysis of subcellular fractions" }
                ListElement { name: "Sample5"; structure_type: "Ball"; description: "revealed a cytosolic localization. The GRK2 inhibitors enhanced and prolonged neutrophil production " }
                ListElement { name: "Sample6"; structure_type: "Vesicle"; description: "production of reactive oxygen species (ROS) induced by GPR84- but not FPR2-agonists" }
                ListElement { name: "Sample7"; structure_type: "Rod"; description: "suggesting a receptor selective function of GRK2. This suggestion was supported by β-arrestin recruitment data. The ROS production induced by a non β-arrestin recruiting GPR84" }
                ListElement { name: "Sample8"; structure_type: "Bilayer"; description: "This suggestion was supported by β-arrestin recruitment data. The ROS production induced by a non β-arrestin recruiting GPR84 agonist was not affected by the GRK2 inhibitor." }
                ListElement { name: "Sample9"; structure_type: "Monolayer"; description: "Termination of this β-arrestin independent response relied, similar to the response induced by FPR2 agonists, primarily on the actin cytoskeleton." }
                ListElement { name: "Samplewithareallylongname"; structure_type: "Lattice"; description: "In summary, we show that GPR84 utilizes GRK2 in concert with β-arrestin and actin cytoskeleton dependent processes to fine-tune the activity of the ROS generating NADPH-oxidase in neutrophils." }
            }

            property var itemSelectionModel: ItemSelectionModel {
                id: selectionModel
                model: availableSambleModelsModel
            }

            property bool activeSelection: true

            delegate: EaComponents.TableViewDelegate {

                required property int index
                required property string name
                required property string structure_type
                required property string description

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
                    width: EaStyle.Sizes.fontPixelSize * 10
                    text: name
                    leftPadding: EaStyle.Sizes.fontPixelSize * 0.7
                }

                EaComponents.TableViewLabel {
                    id: typeColumn
                    width: EaStyle.Sizes.fontPixelSize * 6
                    text: structure_type
                }

                EaComponents.TableViewLabel {
                    id: descrColumn
                    width: EaStyle.Sizes.fontPixelSize * 22
                    text: description
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
