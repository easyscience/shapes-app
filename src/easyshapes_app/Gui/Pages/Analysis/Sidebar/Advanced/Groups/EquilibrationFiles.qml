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


// The files of the equilibration and of each stage run so far, picked in
// Files of. The equilibration holds its copies of the model and of the
// topologies (toppar/), which each run copies again, and its log; a
// stage holds the files gmx wrote for it, once it has finished.
EaElements.GroupColumn {
    id: root
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2

    readonly property var entries: Globals.BackendWrapper.equilibrationEntries
    readonly property var files: Globals.BackendWrapper.equilibrationFiles
    readonly property int fileCount: files ? files.count : 0

    // Row of the file picked in the list, -1 when nothing is selected. Drives
    // whether Export writes one file or the whole entry.
    readonly property int selectedFileRow: filesList.selectedIndexes.length > 0
                                           ? filesList.selectedIndexes[0].row
                                           : -1

    // Rows of entries change their status in place, which a read of one
    // row doesn't follow: each change counts here
    property int _revision: 0
    Connections {
        target: root.entries
        function onDataChanged() { root._revision++ }
        function onRowsInserted() { root._revision++ }
        function onModelReset() { root._revision++ }
    }
    readonly property var selectedEntry: {
        root._revision
        const index = Globals.BackendWrapper.equilibrationSelectedEntry
        return root.entries && index >= 0 && index < root.entries.count ? root.entries.get(index) : null
    }

    // An entry's name, with its status in the minor colour
    // ponytail: plain grey status text; the depiction of outdated is
    // still to be iterated in the mock
    function label(name, status) {
        return status ? `${name}&nbsp;&nbsp;<font color='$TEXT_COLOR'>${status}</font>` : name
    }

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Files of")
        }
        EaElements.ComboBox {
            id: picker
            width: root.halfWidth
            model: root.entries
            currentIndex: Globals.BackendWrapper.equilibrationSelectedEntry
            displayText: root.selectedEntry ? root.label(root.selectedEntry.name, root.selectedEntry.status) : ""
            onActivated: (index) => Globals.BackendWrapper.equilibrationSelectEntry(index)

            // As EaElements.ComboBox's own, with the status after the
            // name: its textRole takes one role only
            delegate: EaElements.MenuItem {
                required property int index
                required property string name
                required property string status

                width: parent !== null ? parent.width : 0
                height: EaStyle.Sizes.comboBoxHeight
                font.family: picker.font.family
                textFormat: Text.RichText
                text: root.label(name, status).split('$TEXT_COLOR').join(EaStyle.Colors.themeForegroundMinor)
                highlighted: picker.highlightedIndex === index
                hoverEnabled: picker.hoverEnabled
            }
        }
    }

    EaComponents.ListView {
        id: filesList
        defaultInfoText: root.selectedEntry && root.selectedEntry.status === "running"
                         ? qsTr("This stage runs: its files come once it has finished")
                         : qsTr("No files yet: run Equilibrate first")
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr("№")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("File")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Size")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: root.files

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string path
            required property string size
            required property bool editable

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }
            EaComponents.TableViewLabel {
                text: path
                elide: Text.ElideLeft
                ToolTip.text: path
            }
            EaComponents.TableViewLabel {
                text: size
                enabled: false
            }
            // Greyed on binary files, and on the copies each run makes
            // again
            EaComponents.TableViewButton {
                fontIcon: "edit"
                enabled: editable
                ToolTip.text: qsTr("Edit this file")
                onClicked: Globals.BackendWrapper.equilibrationEditFile(index)
            }
        }
    }

    // Where to edit what the copies come from
    EaElements.Label {
        width: parent.width
        visible: Globals.BackendWrapper.equilibrationSelectedEntry === 0 && root.fileCount > 0
        wrapMode: Text.Wrap
        color: EaStyle.Colors.themeForegroundMinor
        text: qsTr("Each Equilibrate copies toppar/ and the model's .gro and .top again: edit the components (Sample model page) and the force field instead.")
    }

    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: root.halfWidth
            ToolTip.text: qsTr("Export the selected file to disk, or, when no file is selected, the whole equilibration or stage, nested files included")
            enabled: root.fileCount > 0
            onClicked: exportDestinationDialog.open()
        }

        EaElements.SideBarButton {
            fontIcon: "folder-open"
            text: qsTr("Open folder")
            width: root.halfWidth
            ToolTip.text: qsTr("Open the folder of the files shown in the system file browser")
            enabled: root.fileCount > 0
            onClicked: Globals.BackendWrapper.equilibrationOpenFolder()
        }
    }

    // Destination picker for Export. What gets written is decided here rather
    // than on the button, so the selection is read when the user confirms.
    // A folder the export would replace files in asks first
    FolderDialog {
        id: exportDestinationDialog
        title: qsTr("Choose a destination directory")
        onAccepted: {
            const folder = EaLogic.Utils.urlToLocalFile(selectedFolder.toString())
            if (Globals.BackendWrapper.equilibrationExportTaken(folder, root.selectedFileRow)) {
                exportOverwriteDialog.folder = folder
                exportOverwriteDialog.open()
            } else {
                Globals.BackendWrapper.equilibrationExportTo(folder, root.selectedFileRow, false)
            }
        }
    }

    // Asks before an export replaces files; the folder dialog sets folder
    EaElements.Dialog {
        id: exportOverwriteDialog
        property string folder: ""
        title: qsTr("Replace exported files")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Globals.BackendWrapper.equilibrationExportTo(folder, root.selectedFileRow, true)
        onRejected: console.debug(`Export to ${folder} cancelled: the folder is taken`)

        // In a Column: a bare item under a titled dialog loops its
        // implicitWidth
        Column {
            EaElements.Label {
                text: root.selectedFileRow >= 0
                      ? qsTr("%1 already holds a file of this name. Replace it?").arg(exportOverwriteDialog.folder)
                      : qsTr("%1 is not empty. Export there anyway? Files of an earlier export of these files are replaced.").arg(exportOverwriteDialog.folder)
            }
        }
    }
}
