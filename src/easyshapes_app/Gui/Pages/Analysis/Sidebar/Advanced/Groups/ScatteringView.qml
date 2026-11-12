// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals


// The SANS curves with data: which are drawn on the Scattering tab, and so
// exported, and which are removed. A curve's colour is its row's, in the
// swatch here and on the chart.
EaElements.GroupColumn {
    id: root
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2

    readonly property var curves: Globals.BackendWrapper.scatteringCurves

    // Rows change Show in place, which a read of one row doesn't follow:
    // each change counts here
    property int _revision: 0
    Connections {
        target: root.curves
        function onDataChanged() { root._revision++ }
        function onRowsInserted() { root._revision++ }
        function onRowsRemoved() { root._revision++ }
        function onModelReset() { root._revision++ }
    }
    readonly property bool anyShown: {
        root._revision
        for (let row = 0; root.curves && row < root.curves.count; ++row)
            if (root.curves.get(row).shown)
                return true
        return false
    }

    // No selection: Export writes what the chart shows
    EaComponents.ListView {
        defaultInfoText: qsTr("No curves yet: pick a structure and Calculate")
        selectable: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            EaStyle.Sizes.fontPixelSize * 1.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.fontPixelSize * 3.5,
            EaStyle.Sizes.fontPixelSize * 3,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {}
            EaComponents.TableViewLabel {
                text: qsTr("Curve")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Status")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Rg, Å")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Show")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: root.curves

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string name
            required property string settings
            required property string status
            required property real rg
            required property bool shown

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            // The curve's line, in its colour, as the chart's legend shows
            // it; the name stays in the text colour
            Item {
                height: parent.height

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 3
                    radius: 1.5
                    color: Globals.Vars.scatteringColor(index)
                }
            }
            // Hovering shows how the curve was calculated
            EaComponents.TableViewLabel {
                horizontalAlignment: Text.AlignLeft
                text: name

                EaElements.ToolTip {
                    text: settings
                    visible: parent.hovered && EaGlobals.Vars.showToolTips
                }
            }
            EaComponents.TableViewLabel {
                text: status
                enabled: false
            }
            // Greyed as Fractions' component names: computed, not for editing
            EaComponents.TableViewLabel {
                text: rg.toFixed(1)
                enabled: false
            }
            EaComponents.TableViewCheckBox {
                checked: shown
                onToggled: Globals.BackendWrapper.scatteringSetCurveShown(index, checked)
            }
            // Not on the curve being calculated again
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                visible: name !== Globals.BackendWrapper.scatteringRunningCurve
                ToolTip.text: qsTr("Remove this curve and its files")
                onClicked: {
                    removeDialog.row = index
                    removeDialog.curveName = name
                    removeDialog.open()
                }
            }
        }
    }

    // Each further shown curve drawn lower, so overlapping curves come
    // apart. The chart only: export is unchanged
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.CheckBox {
            id: staggeredBox
            anchors.verticalCenter: parent.verticalCenter
            height: EaStyle.Sizes.fontPixelSize * 2.5
            text: qsTr("Staggered view")
            checked: Globals.Vars.scatteringStaggered
            onToggled: Globals.Vars.scatteringStaggered = checked
        }
        EaElements.Slider {
            id: decadesSlider
            anchors.verticalCenter: parent.verticalCenter
            width: EaStyle.Sizes.sideBarContentWidth - staggeredBox.width - decadesLabel.width
                   - 2 * parent.spacing
            enabled: Globals.Vars.scatteringStaggered
            from: 0.5
            to: 3
            stepSize: 0.5
            value: Globals.Vars.scatteringStaggerDecades
            onMoved: Globals.Vars.scatteringStaggerDecades = value
        }
        EaElements.Label {
            id: decadesLabel
            anchors.verticalCenter: parent.verticalCenter
            enabled: Globals.Vars.scatteringStaggered
            text: qsTr("%1 decades").arg(decadesSlider.value.toFixed(1))
        }
    }

    // Both write what the chart shows: the curves ticked Show
    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export data")
            width: root.halfWidth
            ToolTip.text: qsTr("Write one .dat per shown curve")
            enabled: root.anyShown
            onClicked: exportDestinationDialog.open()
        }

        EaElements.SideBarButton {
            fontIcon: "image"
            text: qsTr("Export as PNG")
            width: root.halfWidth
            ToolTip.text: qsTr("Save the Scattering tab's chart and legend as a PNG image")
            enabled: root.anyShown
            onClicked: pngDialog.open()
        }
    }

    // The system's save dialog asks before it replaces a file
    FileDialog {
        id: pngDialog
        title: qsTr("Save the chart as PNG")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("PNG images (*.png)")]
        defaultSuffix: "png"
        onAccepted: Globals.Vars.scatteringPngRequested(EaLogic.Utils.urlToLocalFile(selectedFile.toString()))
    }

    // Destination picker for Export. A folder the export would replace
    // files in asks first
    FolderDialog {
        id: exportDestinationDialog
        title: qsTr("Choose a destination directory")
        onAccepted: {
            const folder = EaLogic.Utils.urlToLocalFile(selectedFolder.toString())
            if (Globals.BackendWrapper.scatteringExportTaken(folder)) {
                exportOverwriteDialog.folder = folder
                exportOverwriteDialog.open()
            } else {
                Globals.BackendWrapper.scatteringExportTo(folder, false)
            }
        }
    }

    // Asks before an export replaces files; the folder dialog sets folder
    EaElements.Dialog {
        id: exportOverwriteDialog
        property string folder: ""
        title: qsTr("Replace exported files")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Globals.BackendWrapper.scatteringExportTo(folder, true)
        onRejected: console.debug(`Export to ${folder} cancelled: the folder is taken`)

        // In a Column: a bare item under a titled dialog loops its
        // implicitWidth
        Column {
            EaElements.Label {
                text: qsTr("%1 already holds .dat files of these curves. Replace them?").arg(exportOverwriteDialog.folder)
            }
        }
    }

    // Asks before a curve and its files go: a large structure takes long
    // to calculate again. Cancel only logs
    EaElements.Dialog {
        id: removeDialog
        property int row: -1
        property string curveName: ""
        title: qsTr("Remove curve")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Globals.BackendWrapper.scatteringRemoveCurve(row)
        onRejected: console.debug(`Removing ${curveName} cancelled`)

        Column {
            EaElements.Label {
                text: qsTr("Remove %1 and its files?").arg(removeDialog.curveName)
            }
        }
    }
}
