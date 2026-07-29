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

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    title: qsTr("Load a Sample Model from the Asset Library")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        var indexes = loadModelListView.selectedIndexes

        if (indexes.length > 0) {
            var row = indexes[0].row
            var item = Globals.BackendWrapper.sampleModelAvailable.get(row)
            Globals.BackendWrapper.sampleModelSetLoaded(item)
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
                EaStyle.Sizes.fontPixelSize * 8,
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
                    text: qsTr("Shape")
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
                EaComponents.TableViewLabel {} // filler
            }

            model: Globals.BackendWrapper.sampleModelAvailable

            delegate: EaComponents.ListViewDelegate {
                required property int index
                required property string name
                required property string structure_type
                required property string type
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
                    text: type
                }
                EaComponents.TableViewLabel {
                    text: description
                }
                EaComponents.TableViewButton {
                    fontIcon: "minus-circle"
                    ToolTip.text: qsTr("Remove this component")
                    onClicked: Globals.BackendWrapper.sampleModelRemoveFromCatalog(index)
                }
            }
        }
    }
}
