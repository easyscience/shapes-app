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
    id: ionLoadDialog

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 25

    title: qsTr("Load an Ion from the Asset Library")
    standardButtons: Dialog.Ok | Dialog.Cancel

    // Block confirmation when the slot is full or no row is selected.
    Component.onCompleted: {
        var ok = standardButton(Dialog.Ok)
        if (ok) {
            ok.enabled = Qt.binding(function () {
                if (!Globals.BackendWrapper.ionsLoaded
                    || Globals.BackendWrapper.ionsLoaded.count >= 2) return false
                return loadIonListView.selectedIndexes.length > 0
            })
        }
    }

    onAccepted: {
        var indexes = loadIonListView.selectedIndexes

        if (indexes.length > 0) {
            var row = indexes[0].row
            var item = Globals.BackendWrapper.ionsAvailable.get(row)
            Globals.BackendWrapper.ionsAppend({ name: item.name })
            loadIonListView.clearSelection()
        }
    }
    onRejected: {
        loadIonListView.clearSelection()
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Available in the Asset Library")
        }
        EaComponents.ListView {
            id: loadIonListView
            defaultInfoText: qsTr("No ions found")
            multiSelection: false
            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
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
            }

            model: Globals.BackendWrapper.ionsAvailable

            delegate: EaComponents.ListViewDelegate {
                required property int index
                required property string name

                EaComponents.TableViewLabel {
                    text: index + 1
                    horizontalAlignment: Text.AlignHCenter
                    enabled: false
                }
                EaComponents.TableViewLabel {
                    text: name
                }
            }
        }
    }
}
