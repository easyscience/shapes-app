// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


EaElements.GroupColumn {
    id: root
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    // Map the display type to the value stored on a component ('Other' rather
    // than 'Component (Other)', matching the components list).
    function storedComponentType(label) {
        return label === "Component (Other)" ? "Other" : label
    }

    // Molecule identity — Name and Formula.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Name")
            }
            EaElements.TextField {
                width: root.halfWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("e.g. SDS")
                text: Globals.BackendWrapper.smilesMoleculeName
                onEditingFinished: Globals.BackendWrapper.smilesSetMoleculeName(text)
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Formula")
            }
            EaElements.TextField {
                width: root.halfWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("(optional)")
                text: Globals.BackendWrapper.smilesFormula
                onEditingFinished: Globals.BackendWrapper.smilesSetFormula(text)
            }
        }
    }

    // The SMILES string. Hydrogens are added automatically by the generator.
    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("SMILES")
        }
        EaElements.TextField {
            width: EaStyle.Sizes.sideBarContentWidth
            horizontalAlignment: TextInput.AlignLeft
            placeholderText: qsTr("e.g. CCCCCCCCCCCCOS(=O)(=O)[O-]")
            text: Globals.BackendWrapper.smilesString
            onEditingFinished: Globals.BackendWrapper.smilesSetString(text)
        }
        EaElements.Label {
            enabled: false
            text: qsTr("Hydrogens are added automatically.")
        }
    }

    // Simulation box.
    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("Box")
        }
        Row {
            spacing: EaStyle.Sizes.fontPixelSize

            EaElements.Parameter {
                width: root.thirdWidth
                title: qsTr("Lx")
                units: "nm"
                validator: DoubleValidator { bottom: 0 }
                text: Globals.BackendWrapper.smilesBoxX
                onEditingFinished: Globals.BackendWrapper.smilesSetBoxX(parseFloat(text) || 0)
            }
            EaElements.Parameter {
                width: root.thirdWidth
                title: qsTr("Ly")
                units: "nm"
                validator: DoubleValidator { bottom: 0 }
                text: Globals.BackendWrapper.smilesBoxY
                onEditingFinished: Globals.BackendWrapper.smilesSetBoxY(parseFloat(text) || 0)
            }
            EaElements.Parameter {
                width: root.thirdWidth
                title: qsTr("Lz")
                units: "nm"
                validator: DoubleValidator { bottom: 0 }
                text: Globals.BackendWrapper.smilesBoxZ
                onEditingFinished: Globals.BackendWrapper.smilesSetBoxZ(parseFloat(text) || 0)
            }
        }
    }

    // Generation flags. Flatten-XZ only acts together with Align-to-Z, so it is
    // disabled unless Align-to-Z is on.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: root.thirdWidth
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Cis C=C")
            ToolTip.text: qsTr("Kink C=C double bonds to cis (dbcis)")
            checked: Globals.BackendWrapper.smilesCisDoubleBonds
            onToggled: Globals.BackendWrapper.smilesSetCisDoubleBonds(checked)
        }
        EaElements.CheckBox {
            width: root.thirdWidth
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Align Z")
            ToolTip.text: qsTr("Align the backbone to the Z axis")
            checked: Globals.BackendWrapper.smilesAlignZ
            onToggled: Globals.BackendWrapper.smilesSetAlignZ(checked)
        }
        EaElements.CheckBox {
            width: root.thirdWidth
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Flatten XZ")
            ToolTip.text: qsTr("Flatten into the XZ plane (only with Align Z)")
            enabled: Globals.BackendWrapper.smilesAlignZ
            checked: Globals.BackendWrapper.smilesFlatXZ
            onToggled: Globals.BackendWrapper.smilesSetFlatXZ(checked)
        }
    }

    // Component type + output format + Generate, in one row of thirds.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Type")
            }
            EaElements.ComboBox {
                id: componentTypeSelector
                width: root.thirdWidth
                model: Globals.BackendWrapper.smilesComponentTypeOptions
                Component.onCompleted: currentIndex = model.indexOf(Globals.BackendWrapper.smilesComponentType)
                onActivated: (i) => Globals.BackendWrapper.smilesSetComponentType(model[i])
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Format")
            }
            EaElements.ComboBox {
                id: formatSelector
                width: root.thirdWidth
                model: Globals.BackendWrapper.smilesFormatOptions
                Component.onCompleted: currentIndex = model.indexOf(Globals.BackendWrapper.smilesFormat)
                onActivated: (i) => Globals.BackendWrapper.smilesSetFormat(model[i])
            }
        }

        Column {
            // Empty spacer label so the button bottom-aligns with the dropdowns.
            EaElements.Label {
                enabled: false
                text: " "
            }
            EaElements.SideBarButton {
                fontIcon: "cogs"
                text: qsTr("Generate")
                width: root.thirdWidth
                ToolTip.text: qsTr("Generate the molecule and add it to the components")
                enabled: Globals.BackendWrapper.smilesReady
                onClicked: {
                    Globals.BackendWrapper.componentsAppend({
                        name: Globals.BackendWrapper.smilesMoleculeName,
                        component_type: root.storedComponentType(Globals.BackendWrapper.smilesComponentType),
                        c_ion: "",
                        mint: 0,
                        mext: 0
                    })
                    console.debug("SMILES generate → component",
                                  Globals.BackendWrapper.smilesMoleculeName,
                                  "dbcis=" + (Globals.BackendWrapper.smilesCisDoubleBonds ? "['C']" : "[]"),
                                  "alignZ=" + Globals.BackendWrapper.smilesAlignZ,
                                  "fxz=" + Globals.BackendWrapper.smilesFlatXZ)
                }
            }
        }
    }
}
