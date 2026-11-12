// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals

import "../../../MainArea" as MainArea


// The SANS calculation's setup: the structure, the kernel and the
// solvent; the q values and the polydispersity; the deuterated
// components. A wrong value stays red and is not sent; Calculate reads
// fieldsValid. Off while a calculation runs: the run uses what was set at
// its start.
EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3
    property double quarterWidth: (EaStyle.Sizes.sideBarContentWidth - 3 * EaStyle.Sizes.fontPixelSize) / 4

    // Both q fields are red while q min is not below q max; an empty or
    // unfinished field is red by itself
    readonly property bool qMisordered: parseFloat(qMinField.text) >= parseFloat(qMaxField.text)
    readonly property bool fieldsValid: sldField.acceptableInput
                                        && qMinField.acceptableInput && qMaxField.acceptableInput
                                        && !qMisordered
                                        && pointsField.acceptableInput && spreadField.acceptableInput

    enabled: !Globals.BackendWrapper.scatteringFilesLocked

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        // The sample model, named after it, then the finished stages with
        // their status
        MainArea.StagePicker {
            title: qsTr("Structure")
            pickerWidth: root.thirdWidth
            model: Globals.BackendWrapper.scatteringStructures
            currentIndex: Globals.BackendWrapper.scatteringSelectedStructure
            onActivated: (index) => Globals.BackendWrapper.scatteringSelectStructure(index)
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Kernel")
            }
            // Exact by default; users pick the fast one themselves
            EaElements.ComboBox {
                width: root.thirdWidth
                model: [qsTr("Exact"), qsTr("Fast")]
                currentIndex: Globals.BackendWrapper.scatteringKernel === 'average' ? 1 : 0
                onActivated: (index) => Globals.BackendWrapper.scatteringSetKernel(index === 1 ? 'average' : 'auto')

                EaElements.ToolTip {
                    text: qsTr("Use Exact for any shape, can be slow. Fast can take just seconds even "
                               + "for a million atoms, but use it only for round aggregates")
                    visible: parent.hovered && EaGlobals.Vars.showToolTips
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Solvent SLD, 10⁻⁶ Å⁻²")
            }
            // Any number, negative too: buffer salts move it off the
            // H2O/D2O line
            EaElements.TextField {
                id: sldField
                width: root.thirdWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: DoubleValidator {}
                warned: !acceptableInput
                text: Globals.BackendWrapper.scatteringSolventSld
                onEditingFinished: Globals.BackendWrapper.scatteringSetSolventSld(parseFloat(text))

                EaElements.ToolTip {
                    text: qsTr("The SLD of the solvent around the aggregate, buffer salts included. "
                               + "H2O −0.56, D2O 6.36")
                    visible: parent.hovered && EaGlobals.Vars.showToolTips
                }
            }
        }
    }

    // The q values of the curve, then the spread of sizes it averages
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("q min, Å⁻¹")
            }
            // The validator's bottom keeps 0 out: q must be above it
            EaElements.TextField {
                id: qMinField
                width: root.quarterWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: DoubleValidator { bottom: 1e-6 }
                warned: !acceptableInput || root.qMisordered
                text: Globals.BackendWrapper.scatteringQMin
                onEditingFinished: Globals.BackendWrapper.scatteringSetQMin(parseFloat(text))
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("q max, Å⁻¹")
            }
            EaElements.TextField {
                id: qMaxField
                width: root.quarterWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: DoubleValidator { bottom: 1e-6 }
                warned: !acceptableInput || root.qMisordered
                text: Globals.BackendWrapper.scatteringQMax
                onEditingFinished: Globals.BackendWrapper.scatteringSetQMax(parseFloat(text))
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("q points")
            }
            // Not "Points": SasView's Npts are the sizes of its
            // polydispersity average
            EaElements.TextField {
                id: pointsField
                width: root.quarterWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: IntValidator { bottom: 5 }
                warned: !acceptableInput
                text: Globals.BackendWrapper.scatteringQPoints
                onEditingFinished: Globals.BackendWrapper.scatteringSetQPoints(parseInt(text))

                EaElements.ToolTip {
                    text: qsTr("How many q values, evenly spaced on a log scale")
                    visible: parent.hovered && EaGlobals.Vars.showToolTips
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Polydispersity")
            }
            // SasView's PD of a size: the backend's size spread. σ/R is in
            // the tooltip: a quarter is too narrow for it in the title
            EaElements.TextField {
                id: spreadField
                width: root.quarterWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: DoubleValidator { bottom: 0 }
                warned: !acceptableInput
                text: Globals.BackendWrapper.scatteringSizeSpread
                onEditingFinished: Globals.BackendWrapper.scatteringSetSizeSpread(parseFloat(text))

                EaElements.ToolTip {
                    text: qsTr("Spread of aggregate sizes, σ/R. 0 is one size; 0.25 puts about 2 in 3 "
                               + "aggregates within ±25 % of the simulated size")
                    visible: parent.hovered && EaGlobals.Vars.showToolTips
                }
            }
        }
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Deuterate")
        }
        // One box per component of the structure, wrapping onto new lines
        Flow {
            width: EaStyle.Sizes.sideBarContentWidth
            spacing: EaStyle.Sizes.fontPixelSize

            Repeater {
                model: Globals.BackendWrapper.scatteringComponents

                EaElements.CheckBox {
                    required property string modelData
                    height: EaStyle.Sizes.fontPixelSize * 2.5
                    text: modelData
                    checked: Globals.BackendWrapper.scatteringDeuterated.includes(modelData)
                    onToggled: Globals.BackendWrapper.scatteringSetDeuterated(modelData, checked)
                }
            }
        }
    }
}
