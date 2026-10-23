// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Style as EaStyle

import Gui.Globals as Globals


EaElements.Dialog {
    id: libraryAssetLoadDialog

    property int inputFieldWidth: EaStyle.Sizes.fontPixelSize * 30

    title: qsTr("Load an Asset from the Library")
    standardButtons: Dialog.Ok | Dialog.Cancel

    // The library's assets of the editor's types, as a ListModel: the
    // list's selection needs a model, not a JS array
    readonly property ListModel catalog: ListModel {}

    onAboutToShow: {
        catalog.clear()
        for (const type of Globals.BackendWrapper.libraryAssetsTypeOptions)
            for (const name of Globals.BackendWrapper.libraryAvailableAssets[type] ?? [])
                catalog.append({ name: name, type: type })
    }
    onAccepted: {
        var indexes = loadLibraryAssetListView.selectedIndexes
        if (indexes.length > 0) {
            const item = catalog.get(indexes[0].row)
            Globals.BackendWrapper.libraryAssetsLoad(item.type, item.name)
        }
        loadLibraryAssetListView.clearSelection()
    }
    onRejected: {
        loadLibraryAssetListView.clearSelection()
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Available in the Asset Library")
        }

        EaComponents.ListView {
            id: loadLibraryAssetListView
            defaultInfoText: qsTr("No assets found")
            multiSelection: false

            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
                -1,
                EaStyle.Sizes.fontPixelSize * 10
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

            model: libraryAssetLoadDialog.catalog

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
