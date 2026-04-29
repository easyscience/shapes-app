// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Elements as EaElements
import Qt.labs.qmlmodels

import Gui.Globals as Globals

ApplicationWindow{

    width: 650
    height: 580
    color: EaStyle.Colors.contentBackground
    visible: true

    Grid {
        spacing: EaStyle.Sizes.fontPixelSize * 4
        leftPadding: 12

        Column {
            width: 600
            spacing: EaStyle.Sizes.fontPixelSize

            EaElements.ComboBox {
                model: [qsTr("Light"), qsTr("Dark"), qsTr("System")]
                onActivated: {
                    if (currentIndex === 0)
                        EaStyle.Colors.theme = EaStyle.Colors.LightTheme
                    else if (currentIndex === 1)
                        EaStyle.Colors.theme = EaStyle.Colors.DarkTheme
                    else if (currentIndex === 2)
                        EaStyle.Colors.theme = EaStyle.Colors.SystemTheme
                }
                Component.onCompleted: {
                    if (EaStyle.Colors.theme === EaStyle.Colors.LightTheme)
                        currentIndex = 0
                    else if (EaStyle.Colors.theme === EaStyle.Colors.DarkTheme)
                        currentIndex = 1
                    else if (EaStyle.Colors.theme === EaStyle.Colors.SystemTheme)
                        currentIndex = 2
                }
            }

            // groubox to test the element
            EaElements.GroupBox {
                title: qsTr('Test a group widget')
                icon: 'wrench'
                collapsed: false

                Loader { source: 'Gui/Pages/SampleModel/Sidebar/Basic/Groups/Layers.qml'}
            }

            EaComponents.ListView {
                id: whatverTable
                defaultInfoText: qsTr("No models found")
                enabled: true

                columnWidths: [
                    whatverTable.width * 0.25,
                    whatverTable.width * 0.15,
                    -1,
                ]

                scrollBarPolicy: ScrollBar.AlwaysOn // ScrollBar.AsNeeded // ScrollBar.AlwaysOn
                scrollBarInteractive: true

                header: EaComponents.ListViewHeader {

                    EaComponents.TableViewLabel {
                        id: modelNameColumnName
                        text: qsTr("Name")
                        color: EaStyle.Colors.themeForegroundMinor
                        leftPadding: EaStyle.Sizes.fontPixelSize * 0.7
                    }

                    EaComponents.TableViewLabel {
                        id: modelTypeColumnName
                        text: qsTr("Type")
                        color: EaStyle.Colors.themeForegroundMinor
                    }

                    EaComponents.TableViewLabel {
                        id: modelDescrColumnName
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
                    ListElement { name: "1"; structure_type: "2"; description: "3" }
                    ListElement { name: "1"; structure_type: "2"; description: "3" }
                    ListElement { name: "1"; structure_type: "2"; description: "3" }
                    ListElement { name: "end1"; structure_type: "end2"; description: "end3" }
                }

                delegate: EaComponents.ListViewDelegate {
                    required property int index
                    required property string name
                    required property string structure_type
                    required property string description

                    EaComponents.ListViewTextInput {
                        id: modelNameColumn
                        text: name
                    }

                    EaComponents.TableViewLabel {
                        id: typeColumn
                        text: structure_type
                        color: "#666" // new disabled
                    }

                    EaComponents.TableViewLabel {
                        id: descrColumn
                        text: description
                        color: "#555" // old disabled
                    }
                }

            }
        }
    }



    //Component.onCompleted: Globals.References.pages.samplemodel.sidebar.basic.popups.LoadExistingModel.open()

}
