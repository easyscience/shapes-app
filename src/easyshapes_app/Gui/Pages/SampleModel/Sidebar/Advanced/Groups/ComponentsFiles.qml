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
    property double buttonWidth: EaStyle.Sizes.sideBarContentWidth * 0.3164

    // ComboBox + empty-state placeholder share a single slot so the layout
    // doesn't reflow between the two states. The ComboBox is hidden (not
    // just disabled) when there are no components because its popup keeps
    // an ElevationEffect that leaks a soft shadow when the model is empty.
    readonly property int componentsCount:
        Globals.BackendWrapper.componentsLoaded
            ? Globals.BackendWrapper.componentsLoaded.count
            : 0

    EaElements.ComboBox {
        id: componentSelector
        visible: componentsCount > 0
        width: EaStyle.Sizes.sideBarContentWidth
        topInset: componentLabel.height
        topPadding: topInset + padding
        textRole: 'name'
        model: Globals.BackendWrapper.componentsLoaded

        EaElements.Label {
            id: componentLabel
            text: qsTr('Component')
        }

        onActivated: (i) => {
            const row = Globals.BackendWrapper.componentsLoaded.get(i)
            if (row) Globals.BackendWrapper.componentsFilesSelect(row.name)
        }

        // Seed the selection from the currently-selected component, or the
        // first component once the model populates.
        function syncFromBackend() {
            const total = componentsCount
            if (total === 0) {
                currentIndex = -1
                return
            }
            const sel = Globals.BackendWrapper.componentsFilesSelectedComponent
            if (sel !== '') {
                for (let i = 0; i < total; ++i) {
                    if (Globals.BackendWrapper.componentsLoaded.get(i).name === sel) {
                        currentIndex = i
                        return
                    }
                }
            }
            currentIndex = 0
            const row = Globals.BackendWrapper.componentsLoaded.get(0)
            if (row) Globals.BackendWrapper.componentsFilesSelect(row.name)
        }

        Component.onCompleted: syncFromBackend()
        // Re-seed when the user adds the first component on the Basic tab.
        Connections {
            target: Globals.BackendWrapper.componentsLoaded
            function onCountChanged() { componentSelector.syncFromBackend() }
        }
    }

    EaElements.Label {
        visible: componentsCount === 0
        enabled: false
        width: EaStyle.Sizes.sideBarContentWidth
        text: qsTr('Load a component on the Basic controls tab to manage its files here.')
        wrapMode: Text.WordWrap
    }

    EaComponents.ListView {
        id: componentFilesList
        defaultInfoText: qsTr('No files associated with this component')
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
                text: qsTr('Path')
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
                fontIcon: 'minus-circle'
                ToolTip.text: qsTr('Remove this file')
                onClicked: Globals.BackendWrapper.componentsFilesRemove(index)
            }
        }
    }

    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: 'plus-circle'
            text: qsTr('Add new file(s)')
            width: buttonWidth
            ToolTip.text: qsTr('Pick one or more files from disk and add them to this component')
            enabled: Globals.BackendWrapper.componentsFilesSelectedComponent !== ''
            onClicked: addFilesLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: 'file-export'
            text: qsTr('Export component')
            width: buttonWidth
            ToolTip.text: qsTr('Export the selected component to disk')
            enabled: Globals.BackendWrapper.componentsFilesSelectedComponent !== ''
            onClicked: Globals.BackendWrapper.componentsFilesExportComponent()
        }

        EaElements.SideBarButton {
            fontIcon: 'save'
            text: qsTr('Save')
            width: buttonWidth
            ToolTip.text: qsTr('Save the file list for this component')
            enabled: Globals.BackendWrapper.componentsFilesSelectedComponent !== ''
            onClicked: Globals.BackendWrapper.componentsFilesSave()
        }
    }

    Loader {
        id: addFilesLoader
        source: '../Popups/AddComponentFiles.qml'
    }
}
