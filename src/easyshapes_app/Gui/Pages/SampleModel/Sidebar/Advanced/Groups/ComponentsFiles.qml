// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals


EaElements.GroupColumn {
    id: root
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    // Row of the file picked in the list, -1 when nothing is selected. Drives
    // whether Export writes one file or the whole component.
    readonly property int selectedFileRow: componentFilesList.selectedIndexes.length > 0
                                           ? componentFilesList.selectedIndexes[0].row
                                           : -1

    readonly property int fileCount: Globals.BackendWrapper.componentsFilesFiles
                                     ? Globals.BackendWrapper.componentsFilesFiles.count
                                     : 0

    readonly property bool picked: Globals.BackendWrapper.componentsFilesSelectedComponent !== ""
    // Why the components list refused the last name typed for the pick
    readonly property string nameError: Globals.BackendWrapper.componentsNameErrors[Globals.BackendWrapper.componentsFilesSelectedComponent] ?? ""

    // Component selector + name editor + Add new component, in one row of
    // equal thirds. The dropdown lists only components already loaded on the
    // Basic tab; picking one loads its files and name.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Select component")
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
                // component (set by picking a row, Add new component, or a rename).
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
            // Renames the pick with the components list's checks; a
            // refused name keeps the old one, the reason below in red
            EaElements.TextField {
                width: root.thirdWidth
                horizontalAlignment: TextInput.AlignLeft
                readOnly: !root.picked
                warned: root.nameError !== ""
                placeholderText: qsTr("Pick or add a component")
                text: Globals.BackendWrapper.componentsFilesSelectedComponent
                onEditingFinished: {
                    if (!root.picked)
                        return
                    try {
                        Globals.BackendWrapper.componentsRename(Globals.BackendWrapper.componentsFilesSelectedComponent, text)
                    } finally {
                        text = Qt.binding(() => Globals.BackendWrapper.componentsFilesSelectedComponent)
                    }
                }
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
                text: qsTr("Add new component")
                width: root.thirdWidth
                ToolTip.text: qsTr("Add an empty component to the sample, named by its id; rename it in the name field")
                onClicked: Globals.BackendWrapper.componentsFilesCreate()
            }
        }
    }

    // The components list's reason for refusing the name typed above
    EaElements.Label {
        width: parent.width
        visible: text !== ""
        wrapMode: Text.Wrap
        color: EaStyle.Colors.red
        text: root.nameError
    }

    EaComponents.ListView {
        id: componentFilesList
        defaultInfoText: qsTr("No files associated with this component")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 5,
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
                text: qsTr("Size")
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
            required property string size

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {
                text: path
                elide: Text.ElideLeft
            }
            EaComponents.TableViewLabel {
                text: size
                enabled: false
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
            width: root.thirdWidth
            ToolTip.text: qsTr("Pick one or more files from disk and add them to this component")
            enabled: root.picked
            onClicked: addFilesLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: "save"
            text: qsTr("Save to lib")
            width: root.thirdWidth
            ToolTip.text: qsTr("Save this component to the asset library")
            enabled: root.picked
            // A name the library holds asks first
            onClicked: {
                if (Globals.BackendWrapper.componentsFilesNameTaken())
                    saveOverwriteDialog.open()
                else
                    Globals.BackendWrapper.componentsFilesSave(false)
            }
        }

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: root.thirdWidth
            ToolTip.text: qsTr("Export the selected file to disk, or the whole component directory when no file is selected")
            enabled: root.fileCount > 0
            onClicked: exportDestinationDialog.open()
        }
    }

    Loader {
        id: addFilesLoader
        source: "../Popups/AddComponentFiles.qml"
    }

    // Destination picker for Export. What gets written is decided here rather
    // than on the button, so the selection is read when the user confirms.
    // A folder the export would replace files in asks first
    FolderDialog {
        id: exportDestinationDialog
        title: qsTr("Choose a destination directory")
        onAccepted: {
            const folder = EaLogic.Utils.urlToLocalFile(selectedFolder.toString())
            if (Globals.BackendWrapper.componentsFilesExportTaken(folder, root.selectedFileRow)) {
                exportOverwriteDialog.folder = folder
                exportOverwriteDialog.open()
            } else {
                Globals.BackendWrapper.componentsFilesExportTo(folder, root.selectedFileRow, false)
            }
        }
    }

    // Asks before replacing the library's entry of this component's name
    EaElements.Dialog {
        id: saveOverwriteDialog
        title: qsTr("Replace library asset")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Globals.BackendWrapper.componentsFilesSave(true)
        onRejected: console.debug(`Save of ${Globals.BackendWrapper.componentsFilesSelectedComponent} cancelled: the name is taken`)

        // In a Column, as in Library assets: a bare item under a titled
        // dialog loops its implicitWidth
        Column {
            EaElements.Label {
                text: qsTr("The library already holds a component named %1. Replace it?")
                      .arg(Globals.BackendWrapper.componentsFilesSelectedComponent)
            }
        }
    }

    // Asks before an export replaces files; the folder dialog sets folder
    EaElements.Dialog {
        id: exportOverwriteDialog
        property string folder: ""
        title: qsTr("Replace exported files")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Globals.BackendWrapper.componentsFilesExportTo(folder, root.selectedFileRow, true)
        onRejected: console.debug(`Export to ${folder} cancelled: the folder is taken`)

        Column {
            EaElements.Label {
                text: root.selectedFileRow >= 0
                      ? qsTr("%1 already holds a file of this name. Replace it?").arg(exportOverwriteDialog.folder)
                      : qsTr("%1 is not empty. Export there anyway? Files of an earlier export of this component are replaced.").arg(exportOverwriteDialog.folder)
            }
        }
    }
}
