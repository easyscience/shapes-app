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

    // Molecule identity — Name and Formula.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Name")
            }
            // The residue name in the structure file: at most 5 letters
            // or digits. A name the sample holds turns red but Generate
            // stays on; adding the component refuses it. Right after
            // Generate the name is the new component's own: no red
            EaElements.TextField {
                width: root.halfWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("e.g. SDS, 5 characters max")
                validator: RegularExpressionValidator { regularExpression: /[A-Za-z0-9]{0,5}/ }
                warned: Globals.BackendWrapper.smilesNameTaken
                        && !Globals.BackendWrapper.smilesGenerated
                text: Globals.BackendWrapper.smilesName
                onEditingFinished: Globals.BackendWrapper.smilesSetName(text)
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
                validator: RegularExpressionValidator { regularExpression: /[A-Za-z0-9+\-]*/ }
                text: Globals.BackendWrapper.smilesFormula
                onEditingFinished: Globals.BackendWrapper.smilesSetFormula(text)
            }
        }
    }

    // The sample holds the name: the component Generate just added, or
    // a clash
    EaElements.Label {
        width: parent.width
        visible: Globals.BackendWrapper.smilesNameTaken
        wrapMode: Text.Wrap
        color: Globals.BackendWrapper.smilesGenerated ? EaStyle.Colors.green : EaStyle.Colors.red
        text: (Globals.BackendWrapper.smilesGenerated
               ? qsTr("%1 was generated and added to the sample.")
               : qsTr("The sample already holds a component named %1."))
              .arg(Globals.BackendWrapper.smilesName)
    }

    // The SMILES string: atoms, bonds, branches, rings, charges.
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
            validator: RegularExpressionValidator { regularExpression: /[A-Za-z0-9()\[\]{}=#$@+\-\/\\.%:]*/ }
            text: Globals.BackendWrapper.smilesString
            onEditingFinished: Globals.BackendWrapper.smilesSetString(text)
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
                warned: !acceptableInput
                text: Globals.BackendWrapper.smilesBoxX
                onEditingFinished: Globals.BackendWrapper.smilesSetBoxX(parseFloat(text))
            }
            EaElements.Parameter {
                width: root.thirdWidth
                title: qsTr("Ly")
                units: "nm"
                validator: DoubleValidator { bottom: 0 }
                warned: !acceptableInput
                text: Globals.BackendWrapper.smilesBoxY
                onEditingFinished: Globals.BackendWrapper.smilesSetBoxY(parseFloat(text))
            }
            EaElements.Parameter {
                width: root.thirdWidth
                title: qsTr("Lz")
                units: "nm"
                validator: DoubleValidator { bottom: 0 }
                warned: !acceptableInput
                text: Globals.BackendWrapper.smilesBoxZ
                onEditingFinished: Globals.BackendWrapper.smilesSetBoxZ(parseFloat(text))
            }
        }
    }

    // Generation flags. Flatten XZ only acts together with Align Z, so it is
    // disabled unless Align Z is on.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            width: root.thirdWidth
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Cis C=C")
            ToolTip.text: qsTr("Kink C=C double bonds as cis instead of trans")
            checked: Globals.BackendWrapper.smilesCis
            onToggled: Globals.BackendWrapper.smilesSetCis(checked)
        }
        EaElements.CheckBox {
            width: root.thirdWidth
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Align Z")
            ToolTip.text: qsTr("Rotate the molecule so a terminal bond lies along Z")
            checked: Globals.BackendWrapper.smilesAlignZ
            onToggled: Globals.BackendWrapper.smilesSetAlignZ(checked)
        }
        EaElements.CheckBox {
            width: root.thirdWidth
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Flatten XZ")
            ToolTip.text: qsTr("Flatten the aligned molecule into the XZ plane (only with Align Z)")
            enabled: Globals.BackendWrapper.smilesAlignZ
            checked: Globals.BackendWrapper.smilesFlattenXz
            onToggled: Globals.BackendWrapper.smilesSetFlattenXz(checked)
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
                width: root.thirdWidth
                model: Globals.BackendWrapper.smilesComponentTypes
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
                width: root.thirdWidth
                model: Globals.BackendWrapper.smilesExtensions
                Component.onCompleted: currentIndex = model.indexOf(Globals.BackendWrapper.smilesExtension)
                onActivated: (i) => Globals.BackendWrapper.smilesSetExtension(model[i])
            }
        }

        Column {
            // Empty spacer label so the button bottom-aligns with the dropdowns.
            EaElements.Label {
                enabled: false
                text: " "
            }
            // No sample model before Continue: nothing to add the component to
            EaElements.SideBarButton {
                fontIcon: "cogs"
                text: qsTr("Generate")
                width: root.thirdWidth
                ToolTip.text: qsTr("Build the molecule's structure file and add it to the sample's components")
                enabled: Globals.BackendWrapper.smilesReady
                         && Globals.BackendWrapper.sampleModelShape !== ""
                onClicked: Globals.BackendWrapper.smilesGenerate()
            }
        }
    }
}
