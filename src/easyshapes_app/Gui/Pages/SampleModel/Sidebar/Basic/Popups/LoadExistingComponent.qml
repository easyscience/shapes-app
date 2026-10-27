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

    title: qsTr("Load Components from the Asset Library")
    standardButtons: Dialog.Ok | Dialog.Cancel

    // The library's lipids, surfactants and other components, as a
    // ListModel: the list's selection needs a model, not a JS array
    readonly property ListModel catalog: ListModel {}

    onAboutToShow: {
        catalog.clear()
        for (const type of ['Lipid', 'Surfactant', 'Component'])
            for (const name of Globals.BackendWrapper.libraryAvailableAssets[type] ?? [])
                catalog.append({ name: name, type: type })
    }
    onAccepted: {
        let selected = loadComponentListView.selectedIndexes
        for (let i = 0; i < selected.length; ++i) {
            const item = catalog.get(selected[i].row)
            Globals.BackendWrapper.componentsAppend(item.type, item.name)
        }
        loadComponentListView.clearSelection()
    }
    onRejected: {
        loadComponentListView.clearSelection()
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Available in the Asset Library")
        }

        EaComponents.ListView {
            id: loadComponentListView
            defaultInfoText: qsTr("No components found")
            multiSelection: true

            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
                -1,
                EaStyle.Sizes.fontPixelSize * 8
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
                    text: qsTr("Type")
                    color: EaStyle.Colors.themeForegroundMinor
                }
            }

            model: sampleModelLoadDialog.catalog

            delegateModelAccess: DelegateModel.ReadOnly

            delegate: EaComponents.ListViewDelegate {
                required property int index
                required property string name
                required property string type

                EaComponents.TableViewLabel {
                    text: index + 1
                    horizontalAlignment: Text.AlignHCenter
                    enabled: false
                }
                EaComponents.TableViewLabel {
                    text: name
                }
                EaComponents.TableViewLabel {
                    text: type
                }
            }
        }
    }
}
