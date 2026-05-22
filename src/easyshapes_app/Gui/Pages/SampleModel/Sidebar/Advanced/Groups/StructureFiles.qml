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
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.48

    EaComponents.ListView {
        id: structureFilesList
        defaultInfoText: qsTr('No structure files available')
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.tableRowHeight
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr('№')
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr('File')
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: Globals.BackendWrapper.structureFilesFiles

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
                fontIcon: 'minus-circle'
                ToolTip.text: qsTr('Remove this file')
                onClicked: Globals.BackendWrapper.structureFilesRemove(index)
            }
        }
    }

    Grid {
        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: 'save'
            text: qsTr('Save to lib')
            width: buttonWidth
            ToolTip.text: qsTr('Save the current structure files to the asset library')
            enabled: Globals.BackendWrapper.structureFilesFiles
                     ? Globals.BackendWrapper.structureFilesFiles.count > 0
                     : false
            onClicked: Globals.BackendWrapper.structureFilesSaveToLib()
        }

        EaElements.SideBarButton {
            fontIcon: 'folder-open'
            text: qsTr('Replace structure')
            width: buttonWidth
            ToolTip.text: qsTr('Pick a directory to replace the current structure with')
            onClicked: replaceStructureLoader.item.open()
        }
    }

    Loader {
        id: replaceStructureLoader
        source: '../Popups/ReplaceStructure.qml'
    }
}
