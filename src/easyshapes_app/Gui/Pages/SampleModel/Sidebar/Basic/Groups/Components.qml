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

    // Counter-ion options: a "(None)" sentinel (empty counterIon) plus the
    // library's ions.
    readonly property var cIonOptions: [qsTr("(None)")].concat(Globals.BackendWrapper.libraryAvailableIons)

    EaComponents.ListView {
        id: loadedComponents
        defaultInfoText: qsTr("Load or create components")
        multiSelection: true

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.fontPixelSize * 6,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.tableRowHeight
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
                text: qsTr("Type")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("C-ion")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Mint")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr("Mext")
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: Globals.BackendWrapper.componentsLoaded

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string name
            required property string componentType
            required property int mint
            required property int mext
            required property string counterIon
            required property string nameError

            EaComponents.TableViewLabel {
                text: index + 1
                enabled: false
            }

            EaComponents.ListViewTextInput {
                text: name
                warned: nameError !== ""
                onEditingFinished: name = text
            }

            EaComponents.TableViewLabel {
                text: componentType
                enabled: false
            }

            EaComponents.TableViewComboBox {
                horizontalAlignment: Text.AlignHCenter
                model: root.cIonOptions
                // Blank collapsed label for the "(None)" sentinel (0) or no match (-1).
                displayText: currentIndex <= 0 ? "" : currentText
                Component.onCompleted: currentIndex = counterIon === "" ? 0 : find(counterIon)
                onActivated: (i) => counterIon = (i === 0 ? "" : model[i])
            }

            EaComponents.ListViewTextInput {
                text: mint
                onEditingFinished: mint = parseInt(text)
                validator: IntValidator { bottom: 0 }
            }

            EaComponents.ListViewTextInput {
                text: mext
                onEditingFinished: mext = parseInt(text)
                validator: IntValidator { bottom: 0 }
            }

            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this component")
                onClicked: Globals.BackendWrapper.componentsRemove(index)
            }
        }
    }

    // Every value the backend refused, until it is fixed
    EaElements.Label {
        width: parent.width
        visible: text !== ""
        wrapMode: Text.Wrap
        color: EaStyle.Colors.red
        text: Globals.BackendWrapper.componentsErrors
    }

    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "file-import"
            text: qsTr("Load component(s)")
            width: root.halfWidth
            onClicked: loadExistingComponentLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: "upload"
            text: qsTr("Import component")
            width: root.halfWidth
            onClicked: importComponentFolderDialog.open()
        }
    }

    Loader {
        id: loadExistingComponentLoader
        source: "../Popups/LoadExistingComponent.qml"
    }

    // Folder-based import, matching Model Definition's Import.
    FolderDialog {
        id: importComponentFolderDialog
        title: qsTr("Import a component from a directory")
        onAccepted: console.debug(`Import component from folder '${selectedFolder}'`)
    }
}
