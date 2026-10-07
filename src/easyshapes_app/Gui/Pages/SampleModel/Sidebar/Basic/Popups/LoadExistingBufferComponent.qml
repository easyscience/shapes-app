// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


EaElements.Dialog {
    id: bufferComponentLoadDialog

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 35

    title: qsTr("Load Buffer Components from the Asset Library")
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        var indexes = loadBufferComponentListView.selectedIndexes

        for (var i = 0; i < indexes.length; ++i) {
            var item = Globals.BackendWrapper.bufferComponentsAvailable.get(indexes[i].row)
            Globals.BackendWrapper.bufferComponentsAppend(item)
        }
        loadBufferComponentListView.clearSelection()
    }
    onRejected: {
        loadBufferComponentListView.clearSelection()
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Available in the Asset Library")
        }
        EaComponents.ListView {
            id: loadBufferComponentListView
            defaultInfoText: qsTr("No buffer components found")
            multiSelection: true
            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
                EaStyle.Sizes.fontPixelSize * 10,
                -1,
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
                    text: qsTr("Description")
                    color: EaStyle.Colors.themeForegroundMinor
                }
            }

            model: Globals.BackendWrapper.bufferComponentsAvailable

            delegate: EaComponents.ListViewDelegate {
                required property int index
                required property string name
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
                    text: description
                    ToolTip.text: description
                }
            }
        }
    }
}
