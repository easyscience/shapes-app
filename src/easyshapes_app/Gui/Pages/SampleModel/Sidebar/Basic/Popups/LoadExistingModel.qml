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

    // The library's sample models, as a ListModel: the list's selection
    // needs a model, not a JS array
    readonly property ListModel catalog: ListModel {}

    onAboutToShow: {
        catalog.clear()
        for (const name of Globals.BackendWrapper.libraryAvailableAssets['SampleModel'] ?? [])
            catalog.append({ name: name })
    }
    onAccepted: {
        const selected = loadModelListView.selectedIndexes
        if (selected.length > 0)
            Globals.BackendWrapper.sampleModelLoad(catalog.get(selected[0].row).name)
        loadModelListView.clearSelection()
    }
    onRejected: loadModelListView.clearSelection()

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
                -1
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

            model: sampleModelLoadDialog.catalog

            delegateModelAccess: DelegateModel.ReadOnly

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
