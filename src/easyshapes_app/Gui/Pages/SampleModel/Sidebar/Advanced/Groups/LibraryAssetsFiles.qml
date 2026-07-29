// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals


EaElements.GroupColumn {
    id: root
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    readonly property string assetType: Globals.BackendWrapper.libraryAssetsType
    readonly property bool isSalt: assetType === "Salt"

    readonly property int fileCount: Globals.BackendWrapper.libraryAssetsPaths
                                     ? Globals.BackendWrapper.libraryAssetsPaths.count
                                     : 0

    // Row of the file picked in the list, -1 when nothing is selected (or the
    // list is hidden for a salt). Drives whether Export writes one file or the
    // whole asset.
    readonly property int selectedFileRow: !isSalt && assetPathsList.selectedIndexes.length > 0
                                           ? assetPathsList.selectedIndexes[0].row
                                           : -1

    // Component-only fields (C-ion/Mint/Mext) show for the molecule types and
    // hide for Ion/Solvent/Salt, mirroring the asset class hierarchy.
    readonly property bool isMolecule: assetType === "Lipid"
                                       || assetType === "Surfactant"
                                       || assetType === "Component (Other)"

    // Ion options: a leading "(None)" sentinel (empty value) plus the shared
    // ion library. Used by both the C-ion picker and the salt composition.
    readonly property var ionOptions: {
        const lib = Globals.BackendWrapper.ionsAvailable
        let opts = [qsTr("(None)")]
        for (let i = 0; i < lib.count; ++i)
            opts.push(lib.get(i).name)
        return opts
    }

    // Row 1 — Create new / Load from lib.
    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "plus-square"
            text: qsTr("Create new")
            width: root.halfWidth
            ToolTip.text: qsTr("Start a new library asset — clears the fields and unlocks the type")
            onClicked: Globals.BackendWrapper.libraryAssetsCreateNew()
        }

        EaElements.SideBarButton {
            fontIcon: "file-import"
            text: qsTr("Load from lib")
            width: root.halfWidth
            ToolTip.text: qsTr("Browse and load an existing asset from the library")
            onClicked: loadLibraryAssetLoader.item.open()
        }
    }

    // Row 2 — Type + Name. Type is editable only while creating.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Type")
            }
            EaElements.ComboBox {
                id: typeSelector
                width: root.halfWidth
                model: Globals.BackendWrapper.libraryAssetsTypeOptions
                enabled: Globals.BackendWrapper.libraryAssetsMode === "create"
                displayText: currentIndex < 0 ? "" : currentText

                function syncIndex() {
                    currentIndex = model
                        ? model.indexOf(Globals.BackendWrapper.libraryAssetsType)
                        : -1
                }
                Component.onCompleted: syncIndex()
                onActivated: (i) => Globals.BackendWrapper.libraryAssetsSetType(model[i])
                Connections {
                    target: Globals.BackendWrapper
                    function onLibraryAssetsTypeChanged() { typeSelector.syncIndex() }
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Name")
            }
            EaElements.TextField {
                width: root.halfWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("Asset name")
                text: Globals.BackendWrapper.libraryAssetsName
                onEditingFinished: Globals.BackendWrapper.libraryAssetsSetName(text)
            }
        }
    }

    // Row 3 — component-only fields (C-ion / Mint / Mext).
    Row {
        visible: root.isMolecule
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("C-ion")
            }
            EaElements.ComboBox {
                id: cIonSelector
                width: root.thirdWidth
                model: root.ionOptions
                // Blank collapsed label for the "(None)" sentinel (index 0) or
                // no match (-1); the dropdown still lists "(None)".
                displayText: currentIndex <= 0 ? "" : currentText

                function syncIndex() {
                    const v = Globals.BackendWrapper.libraryAssetsCIon
                    currentIndex = v === "" ? 0 : find(v)
                }
                Component.onCompleted: syncIndex()
                onActivated: (i) => Globals.BackendWrapper.libraryAssetsSetCIon(i === 0 ? "" : model[i])
                Connections {
                    target: Globals.BackendWrapper
                    function onLibraryAssetsCIonChanged() { cIonSelector.syncIndex() }
                }
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Mint")
            }
            EaElements.TextField {
                width: root.thirdWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: IntValidator { bottom: 0 }
                text: Globals.BackendWrapper.libraryAssetsMint
                onEditingFinished: Globals.BackendWrapper.libraryAssetsSetMint(parseInt(text) || 0)
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Mext")
            }
            EaElements.TextField {
                width: root.thirdWidth
                horizontalAlignment: TextInput.AlignLeft
                validator: IntValidator { bottom: 0 }
                text: Globals.BackendWrapper.libraryAssetsMext
                onEditingFinished: Globals.BackendWrapper.libraryAssetsSetMext(parseInt(text) || 0)
            }
        }
    }

    // Salt composition — shown only for the Salt type (replaces the file list).
    // Two ion slots with stoichiometric counts.
    Column {
        visible: root.isSalt
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("Salt composition")
        }

        EaComponents.ListView {
            id: saltComposition
            multiSelection: false

            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
                EaStyle.Sizes.fontPixelSize * 7,
                EaStyle.Sizes.fontPixelSize * 6,
                EaStyle.Sizes.tableColumnFlex
            ]

            header: EaComponents.ListViewHeader {
                EaComponents.TableViewLabel {
                    text: qsTr("№")
                    color: EaStyle.Colors.themeForegroundMinor
                }
                EaComponents.TableViewLabel {
                    text: qsTr("Name")
                    color: EaStyle.Colors.themeForegroundMinor
                }
                EaComponents.TableViewLabel {
                    text: qsTr("Count")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {} // filler, takes the remaining space
            }

            model: Globals.BackendWrapper.libraryAssetsSaltComposition

            delegate: EaComponents.ListViewDelegate {
                id: saltRow
                required property int index
                required property string ion
                required property int count

                EaComponents.TableViewLabel {
                    text: index + 1
                    enabled: false
                }

                EaComponents.TableViewComboBox {
                    id: ionCombo
                    model: root.ionOptions
                    displayText: currentIndex <= 0 ? "" : currentText

                    function sync() { currentIndex = saltRow.ion === "" ? 0 : find(saltRow.ion) }
                    Component.onCompleted: sync()
                    onActivated: (i) => Globals.BackendWrapper.libraryAssetsSetSaltIon(saltRow.index, i === 0 ? "" : model[i])
                    Connections {
                        target: saltRow
                        function onIonChanged() { ionCombo.sync() }
                    }
                }

                EaComponents.ListViewTextInput {
                    text: count
                    validator: IntValidator { bottom: 1 }
                    onEditingFinished: Globals.BackendWrapper.libraryAssetsSetSaltCount(saltRow.index, parseInt(text) || 1)
                }

                EaComponents.TableViewLabel {} // filler, matches the header
            }
        }
    }

    // Asset composition — the files making up this asset. Hidden for salts.
    EaComponents.ListView {
        id: assetPathsList
        visible: !root.isSalt
        defaultInfoText: qsTr("No files in this asset")
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

        model: Globals.BackendWrapper.libraryAssetsPaths

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
                onClicked: Globals.BackendWrapper.libraryAssetsEditPath(index)
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this file")
                onClicked: Globals.BackendWrapper.libraryAssetsRemovePath(index)
            }
        }
    }

    // Row — Add new file / Save to lib / Export.
    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Add new file")
            width: root.thirdWidth
            ToolTip.text: qsTr("Pick one or more files from disk and add them to this asset")
            enabled: Globals.BackendWrapper.libraryAssetsMode !== "empty" && !root.isSalt
            onClicked: addAssetFilesDialog.open()
        }

        EaElements.SideBarButton {
            fontIcon: "save"
            text: qsTr("Save to lib")
            width: root.thirdWidth
            ToolTip.text: qsTr("Save this asset to the library")
            enabled: root.isSalt
                     ? Globals.BackendWrapper.libraryAssetsSaltReady
                     : (Globals.BackendWrapper.libraryAssetsName.trim() !== ""
                        && Globals.BackendWrapper.libraryAssetsPaths
                        && Globals.BackendWrapper.libraryAssetsPaths.count > 0)
            onClicked: Globals.BackendWrapper.libraryAssetsSave()
        }

        EaElements.SideBarButton {
            fontIcon: "file-export"
            text: qsTr("Export")
            width: root.thirdWidth
            ToolTip.text: qsTr("Export the selected file to disk, or the whole asset directory when no file is selected")
            // A salt carries no files, so it falls back to the composition
            // readiness check used by Save.
            enabled: root.isSalt
                     ? Globals.BackendWrapper.libraryAssetsSaltReady
                     : root.fileCount > 0
            onClicked: exportDestinationDialog.open()
        }
    }

    // Destination picker for Export. What gets written is decided here rather
    // than on the button, so the selection is read when the user confirms.
    FolderDialog {
        id: exportDestinationDialog
        title: qsTr("Choose a destination directory")
        onAccepted: {
            const destination = selectedFolder.toString()
            if (root.selectedFileRow >= 0)
                Globals.BackendWrapper.libraryAssetsExportPath(root.selectedFileRow, destination)
            else
                Globals.BackendWrapper.libraryAssetsExport(destination)
        }
    }

    FileDialog {
        id: addAssetFilesDialog
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            "Any (*)",
            "Structure files (*.gro *.pdb *.xyz)",
            "Topology files (*.itp *.top)",
            "Smiles files (*.sml)"
        ]
        onAccepted: {
            for (let i = 0; i < selectedFiles.length; ++i) {
                Globals.BackendWrapper.libraryAssetsAppendPath(selectedFiles[i].toString())
            }
        }
    }

    Loader {
        id: loadLibraryAssetLoader
        source: "../Popups/LoadLibraryAsset.qml"
    }
}
