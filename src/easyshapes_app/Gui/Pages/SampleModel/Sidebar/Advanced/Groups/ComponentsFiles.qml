// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals


EaElements.GroupColumn {
    id: root
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    // Component selector + name editor + Create new, in one row of equal
    // thirds. The dropdown lists only components already loaded on the Basic
    // tab; picking one loads its files and name.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Component")
            }
            EaElements.ComboBox {
                id: componentSelector
                width: root.thirdWidth
                textRole: "name"
                model: Globals.BackendWrapper.componentsLoaded

                onActivated: (i) => {
                    const row = Globals.BackendWrapper.componentsLoaded.get(i)
                    if (row) Globals.BackendWrapper.componentsFilesSelect(row.name)
                }

                // Mirror the dropdown index from the backend's selected
                // component (set by picking a row, Create new, or Save to lib).
                function syncIndex() {
                    const sel = Globals.BackendWrapper.componentsFilesSelectedComponent
                    const m = Globals.BackendWrapper.componentsLoaded
                    if (sel !== "" && m) {
                        for (let i = 0; i < m.count; ++i) {
                            if (m.get(i).name === sel) {
                                currentIndex = i
                                return
                            }
                        }
                    }
                    currentIndex = -1
                }

                Component.onCompleted: syncIndex()
                Connections {
                    target: Globals.BackendWrapper.componentsLoaded
                    function onCountChanged() { componentSelector.syncIndex() }
                }
                Connections {
                    target: Globals.BackendWrapper
                    function onComponentsFilesSelectedComponentChanged() { componentSelector.syncIndex() }
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Name")
            }
            EaElements.TextField {
                width: root.thirdWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("Component name")
                text: Globals.BackendWrapper.componentsFilesEditName
                onEditingFinished: Globals.BackendWrapper.componentsFilesSetEditName(text)
            }
        }

        Column {
            // Empty spacer label so the button bottom-aligns with the fields.
            EaElements.Label {
                enabled: false
                text: " "
            }
            EaElements.SideBarButton {
                fontIcon: "plus-square"
                text: qsTr("Create new")
                width: root.thirdWidth
                ToolTip.text: qsTr("Start a new component — clears the selection, name and file list")
                onClicked: Globals.BackendWrapper.componentsFilesCreateNew()
            }
        }
    }

    EaComponents.ListView {
        id: componentFilesList
        defaultInfoText: qsTr("No files associated with this component")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.tableRowHeight,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Path")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: Globals.BackendWrapper.componentsFilesFiles

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string path

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {
                text: path
                elide: Text.ElideLeft
            }
            EaComponents.TableViewButton {
                fontIcon: "edit"
                ToolTip.text: qsTr("Edit this file")
                onClicked: Globals.BackendWrapper.componentsFilesEditFile(index)
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this file")
                onClicked: Globals.BackendWrapper.componentsFilesRemove(index)
            }
        }
    }

    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Add new file(s)")
            width: buttonWidth
            ToolTip.text: qsTr("Pick one or more files from disk and add them to this component")
            onClicked: addFilesLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: "save"
            text: qsTr("Save to lib")
            width: buttonWidth
            ToolTip.text: qsTr("Save this component to the asset library and load it on the Basic tab")
            enabled: Globals.BackendWrapper.componentsFilesEditName.trim() !== ""
            onClicked: Globals.BackendWrapper.componentsFilesSave()
        }

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: buttonWidth
            ToolTip.text: qsTr("Export the selected component to disk")
            enabled: Globals.BackendWrapper.componentsFilesSelectedComponent !== ""
            onClicked: Globals.BackendWrapper.componentsFilesExportComponent()
        }
    }

    Loader {
        id: addFilesLoader
        source: "../Popups/AddComponentFiles.qml"
    }
}
