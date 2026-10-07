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

    // Solvent — single selection (None / TIP3 / Ethanol).
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Solvent")
        }

        EaElements.ComboBox {
            width: EaStyle.Sizes.sideBarContentWidth * 0.25
            model: Globals.BackendWrapper.bufferSolventOptions
            // Blank collapsed label for the "(None)" sentinel (index 0).
            displayText: currentIndex <= 0 ? "" : currentText
            Component.onCompleted: currentIndex = model.indexOf(Globals.BackendWrapper.bufferSolvent)
            onActivated: (i) => Globals.BackendWrapper.bufferSolvent = model[i]
        }
    }

    // Buffer components — row list of salts / buffering agents.
    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr("Buffer Components")
        }

        EaComponents.ListView {
            id: bufferComponentsList
            defaultInfoText: qsTr("Load or import buffer components")
            multiSelection: true

            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 2.5,
                -1,
                -1,
                EaStyle.Sizes.tableRowHeight
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
                    text: qsTr("Concentration, mM")
                    color: EaStyle.Colors.themeForegroundMinor
                    horizontalAlignment: Text.AlignHCenter
                }
                EaComponents.TableViewLabel {}
            }

            model: Globals.BackendWrapper.bufferComponents

            delegateModelAccess: DelegateModel.ReadWrite

            delegate: EaComponents.ListViewDelegate {
                required property int index
                required property string name
                required property real concentration

                EaComponents.TableViewLabel {
                    text: index + 1
                    horizontalAlignment: Text.AlignHCenter
                    enabled: false
                }
                EaComponents.TableViewLabel {
                    text: name
                }
                EaComponents.ListViewTextInput {
                    text: concentration
                    onEditingFinished: concentration = parseFloat(text)
                    validator: DoubleValidator { bottom: 0; decimals: 3; notation: DoubleValidator.StandardNotation }
                }
                EaComponents.TableViewButton {
                    fontIcon: "minus-circle"
                    ToolTip.text: qsTr("Remove this component")
                    onClicked: Globals.BackendWrapper.bufferComponentsRemove(index)
                }
            }
        }
    }

    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: "file-import"
            text: qsTr("Load components")
            width: root.halfWidth
            onClicked: loadBufferComponentLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: "upload"
            text: qsTr("Import components")
            width: root.halfWidth
            onClicked: importBufferFolderDialog.open()
        }
    }

    Loader {
        id: loadBufferComponentLoader
        source: "../Popups/LoadExistingBufferComponent.qml"
    }

    // Folder-based import, matching the other Import buttons.
    FolderDialog {
        id: importBufferFolderDialog
        title: qsTr("Import buffer components from a directory")
        onAccepted: console.debug(`Import buffer components from folder '${selectedFolder}'`)
    }
}
