// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtCore

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Globals as EaGlobals

import Gui.Globals as Globals


// Main-area window: "Shape". A simple geometric schematic of the sample model,
// focused on the per-component mint-mext vectors and their spacing (dmin) along
// the structure baseline. Always available.
//
// The schematic depends on the selected structure type:
//   - Ring: a single ring (dmin / rmin / rev).
//   - Ball: one concentric ring per layer, alternating orientation.
//   - Vesicle: one bilayer (two leaflet rings) per lamella, plus outer shell.
//   - Rod: a single ring (like Ring).
//   - Bilayer / Monolayer: two flat (uncurved) leaflets, zsep (or dmin) apart,
//     drawn by FlatShapeView. Monolayer reverses the mint->mext direction.
// Each also has the whole unit sketched in the lower left, with its sizes
// under Dimensions: a circle for Ring, Ball and Vesicle (outer radius), a
// capsule for Rod (length, outer radius), a slab for Bilayer and Monolayer
// (width, thickness). Other types fall back to a placeholder.
Rectangle {
    id: root

    readonly property string structureType: Globals.BackendWrapper.sampleModelShape
    readonly property bool isRod: structureType === "Rod"
    readonly property bool isFlat: structureType === "Bilayer" || structureType === "Monolayer"
    readonly property bool isRadial: structureType === "Ring"
                                     || structureType === "Ball"
                                     || structureType === "Vesicle"
                                     || isRod
    readonly property bool supported: isRadial || isFlat

    color: EaStyle.Colors.mainContentBackground

    RingShapeView {
        id: shapeView
        anchors.fill: parent
        visible: root.isRadial

        showComponentNames: namesCheck.checked
        showDimensions: dimsCheck.checked
        showMolecules: moleculesCheck.checked

        // Single-ring parameters (Ring, and Rod which reuses the ring layout).
        dmin: root.isRod
              ? Globals.BackendWrapper.rodStructureDmin
              : Globals.BackendWrapper.ringStructureDmin
        rmin: root.isRod
              ? Globals.BackendWrapper.rodStructureRmin
              : Globals.BackendWrapper.ringStructureRmin

        // Each structure has its own rev flag.
        rev: root.structureType === "Ball"
             ? Globals.BackendWrapper.ballStructureRev
             : root.structureType === "Vesicle"
               ? Globals.BackendWrapper.vesicleStructureRev
               : root.isRod
                 ? Globals.BackendWrapper.rodStructureRev
                 : Globals.BackendWrapper.ringStructureRev

        // Ball: one ring per layer. Ring/Rod: no layers -> single ring above.
        layers: root.structureType === "Ball"
                ? Globals.BackendWrapper.layersItems
                : null

        // Vesicle: one bilayer per lamella.
        lamellae: root.structureType === "Vesicle"
                  ? Globals.BackendWrapper.lamellaeItems
                  : null
    }

    // Bilayer / Monolayer: flat leaflets.
    FlatShapeView {
        anchors.fill: parent
        visible: root.isFlat

        showComponentNames: namesCheck.checked
        showDimensions: dimsCheck.checked
        showMolecules: moleculesCheck.checked

        // Monolayer is the opposite of Bilayer.
        reversed: root.structureType === "Monolayer"

        dmin: root.structureType === "Monolayer"
              ? Globals.BackendWrapper.monolayerStructureDmin
              : Globals.BackendWrapper.bilayerStructureDmin
        zsep: root.structureType === "Monolayer"
              ? Globals.BackendWrapper.monolayerStructureZsep
              : Globals.BackendWrapper.bilayerStructureZsep
        nside: root.structureType === "Monolayer"
               ? Globals.BackendWrapper.monolayerStructureNside
               : Globals.BackendWrapper.bilayerStructureNside
    }

    // Rod body capsule, drawn in the lower-left quadrant for the Rod structure.
    RodShape {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width * 0.45
        height: parent.height * 0.45
        visible: root.isRod
        turns: Globals.BackendWrapper.rodStructureTurns
        outerRadius: Globals.BackendWrapper.rodStructureOuterRadius
        length: Globals.BackendWrapper.rodStructureLength
        showDimensions: dimsCheck.checked
    }

    // Ring, Ball, Vesicle: the unit's outer circle, in the rod's place
    CircleShape {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width * 0.45
        height: parent.height * 0.45
        visible: root.isRadial && !root.isRod
        outerRadius: root.structureType === "Ball"
                     ? Globals.BackendWrapper.layersFullRadius
                     : root.structureType === "Vesicle"
                       ? Globals.BackendWrapper.lamellaeFullRadius
                       : Globals.BackendWrapper.ringStructureOuterRadius
        showDimensions: dimsCheck.checked
    }

    // Bilayer, Monolayer: the unit's slab, in the rod's place
    SlabShape {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width * 0.45
        height: parent.height * 0.45
        visible: root.isFlat
        slabWidth: root.structureType === "Monolayer"
                   ? Globals.BackendWrapper.monolayerStructureWidth
                   : Globals.BackendWrapper.bilayerStructureWidth
        slabThickness: root.structureType === "Monolayer"
                       ? Globals.BackendWrapper.monolayerStructureThickness
                       : Globals.BackendWrapper.bilayerStructureThickness
        showDimensions: dimsCheck.checked
    }

    // Display toggles (top-right), available for every supported view.
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: EaStyle.Sizes.fontPixelSize
        spacing: EaStyle.Sizes.fontPixelSize
        visible: root.supported

        EaElements.CheckBox {
            id: namesCheck
            text: qsTr("Component names")
            checked: false
        }
        EaElements.CheckBox {
            id: dimsCheck
            text: qsTr("Dimensions")
            checked: false
        }
        EaElements.CheckBox {
            id: moleculesCheck
            text: qsTr("Molecules")
            checked: false
        }
    }

    // The toggles are kept between launches, in the app's settings file,
    // as the project folder is
    Settings {
        location: EaGlobals.Vars.settingsFile
        category: 'SampleModel.Shape'
        property alias showComponentNames: namesCheck.checked
        property alias showDimensions: dimsCheck.checked
        property alias showMolecules: moleculesCheck.checked
    }

    // Placeholder for structure types whose Shape view is not implemented yet.
    Column {
        anchors.centerIn: parent
        spacing: EaStyle.Sizes.fontPixelSize
        visible: !root.supported

        EaElements.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: EaStyle.Sizes.fontPixelSize * 1.5
            color: EaStyle.Colors.themeForegroundMinor
            text: qsTr("Shape")
        }
        EaElements.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: EaStyle.Colors.themeForegroundMinor
            text: qsTr("No Shape view yet for the %1 structure.").arg(root.structureType)
        }
    }
}
