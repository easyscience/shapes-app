// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// The Structure tab's controls: background, slab, lighting, and whether
// the atoms stay loaded while the tab is hidden.
EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    readonly property var instancing: Globals.BackendWrapper.structureViewInstancing

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Background")
            }
            EaElements.ComboBox {
                width: root.thirdWidth
                model: [qsTr("Theme"), qsTr("Black"), qsTr("White"), qsTr("Grey 50%")]
                currentIndex: Globals.Vars.structureBackground
                onActivated: (index) => Globals.Vars.structureBackground = index
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Slab plane")
            }
            // By the plane the slab lies in; the index is the axis it is
            // cut across (0, 1, 2 = X, Y, Z)
            EaElements.ComboBox {
                width: root.thirdWidth
                model: [qsTr("YZ plane"), qsTr("XZ plane"), qsTr("XY plane")]
                currentIndex: root.instancing.slabAxis
                onActivated: (index) => root.instancing.slabAxis = index
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Lighting")
            }
            EaElements.ComboBox {
                width: root.thirdWidth
                model: [qsTr("Default"), qsTr("Volumetric"), qsTr("Vol-tint"), qsTr("Hygge"), qsTr("Outline")]
                currentIndex: Globals.Vars.structureLighting
                onActivated: (index) => Globals.Vars.structureLighting = index
            }
        }
    }

    // The slab's thickness, as a share of the structure's size along
    // the axis
    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("Slab thickness")
        }
        Row {
            spacing: EaStyle.Sizes.fontPixelSize

            EaElements.Slider {
                id: slider
                anchors.verticalCenter: parent.verticalCenter
                width: EaStyle.Sizes.sideBarContentWidth - percentLabel.width - parent.spacing
                from: 0
                to: 100
                stepSize: 1
                value: Math.round(root.instancing.slabFraction * 100)
                // Without continuous update Python cuts the new slab on
                // release only: at millions of atoms each cut takes a
                // moment
                onMoved: if (Globals.Vars.structureContinuousUpdate) root.instancing.slabFraction = value / 100
                onPressedChanged: if (!pressed) root.instancing.slabFraction = value / 100
            }
            EaElements.Label {
                id: percentLabel
                anchors.verticalCenter: parent.verticalCenter
                // As wide as "100 %", so the slider doesn't jump as it
                // changes
                width: percentWidth.width
                horizontalAlignment: Text.AlignRight
                text: slider.value.toFixed(0) + " %"

                TextMetrics {
                    id: percentWidth
                    font: percentLabel.font
                    text: "100 %"
                }
            }
        }
    }

    // Kept between launches by Globals.Vars
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Continuous update")
            ToolTip.text: qsTr("Cut the slab while the slider moves, not on release: slow for millions of atoms")
            checked: Globals.Vars.structureContinuousUpdate
            onToggled: Globals.Vars.structureContinuousUpdate = checked
        }

        EaElements.CheckBox {
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Keep structure loaded")
            ToolTip.text: qsTr("Off: each time the Structure tab opens, the structure is read again and the slab starts at 5 %")
            checked: Globals.Vars.structureKeepLoaded
            onToggled: Globals.Vars.structureKeepLoaded = checked
        }

        EaElements.CheckBox {
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Show bonds")
            ToolTip.text: qsTr("Sticks between bonded atoms, from the components' .itp files: about three times the VRAM of the atoms alone")
            checked: Globals.Vars.structureShowBonds
            onToggled: Globals.Vars.structureShowBonds = checked
        }
    }
}
