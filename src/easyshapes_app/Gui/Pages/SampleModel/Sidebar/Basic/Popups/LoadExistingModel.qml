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
    property alias availableModelsModel: availableSambleModelsModel

    title: qsTr("Load a Sample Model from the Asset Library")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        var indexes = loadModelListView.selectedIndexes

        if (indexes.length > 0) {
            var row = indexes[0].row
            var item = availableSambleModelsModel.get(row)

            targetModel.clear()
            targetModel.append(item)
            loadModelListView.clearSelection()
        }
    }
    onRejected: {
        loadModelListView.clearSelection()
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Available in the Asset Library")
        }
        EaComponents.ListView {
            id: loadModelListView
            defaultInfoText: qsTr("No models found")
            multiSelection: false
            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
                EaStyle.Sizes.fontPixelSize * 10,
                EaStyle.Sizes.fontPixelSize * 6,
                -1,
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

            delegateModelAccess: DelegateModel.ReadOnly

            delegate: EaComponents.ListViewDelegate {
                required property int index
                required property string name
                required property string structure_type
                required property string description

                EaComponents.TableViewLabel {
                    text: index + 1
                    horizontalAlignment: Text.AlignHCenter
                    enabled: false
                }
                EaComponents.TableViewLabel {
                    text: name
                }
                EaComponents.TableViewLabel {
                    text: structure_type
                }
                EaComponents.TableViewLabel {
                    text: description
                }
                EaComponents.TableViewButton {
                    fontIcon: "minus-circle"
                    ToolTip.text: qsTr("Remove this component")
                    onClicked: availableSambleModelsModel.remove(index)
                }
            }
        }
    }
}
