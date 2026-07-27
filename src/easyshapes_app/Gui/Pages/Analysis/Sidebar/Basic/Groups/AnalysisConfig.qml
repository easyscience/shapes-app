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
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2
    // Two quarters plus one fontPixelSize gap add up to exactly halfWidth, so
    // the step pair fills the right half of the ForceField row.
    property double quarterWidth: (EaStyle.Sizes.sideBarContentWidth - 3 * EaStyle.Sizes.fontPixelSize) / 4

    EaComponents.ListView {
        id: configFilesList
        defaultInfoText: qsTr("No configuration files added")
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
            EaComponents.TableViewLabel {}
            EaComponents.TableViewLabel {}
        }

        model: Globals.BackendWrapper.analysisConfigFiles

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
                onClicked: Globals.BackendWrapper.analysisConfigEditFile(index)
            }
            EaComponents.TableViewButton {
                fontIcon: "minus-circle"
                ToolTip.text: qsTr("Remove this file")
                onClicked: Globals.BackendWrapper.analysisConfigRemoveFile(index)
            }
        }
    }

    Grid {
        columns: 1

        EaElements.SideBarButton {
            fontIcon: "plus-circle"
            text: qsTr("Add file(s)")
            width: root.halfWidth
            ToolTip.text: qsTr("Pick one or more .mdp files from disk")
            onClicked: addFilesLoader.item.open()
        }
    }

    // ForceField selector on the left, step-range pair on the right.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.ComboBox {
            width: root.halfWidth
            topInset: forceFieldLabel.height
            topPadding: topInset + padding
            model: Globals.BackendWrapper.analysisConfigForceFields
            currentIndex: Math.max(
                0,
                Globals.BackendWrapper.analysisConfigForceFields.indexOf(
                    Globals.BackendWrapper.analysisConfigForceField))
            onActivated: (i) => Globals.BackendWrapper.analysisConfigSetForceField(
                Globals.BackendWrapper.analysisConfigForceFields[i])

            EaElements.Label {
                id: forceFieldLabel
                text: qsTr("ForceField")
            }
        }

        Row {
            spacing: EaStyle.Sizes.fontPixelSize

            EaElements.Parameter {
                width: root.quarterWidth
                title: qsTr("Start step")
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0 }
                text: Globals.BackendWrapper.analysisConfigStartStep
                onEditingFinished: Globals.BackendWrapper.analysisConfigSetStartStep(text)
            }

            EaElements.Parameter {
                width: root.quarterWidth
                title: qsTr("Stop step")
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0 }
                text: Globals.BackendWrapper.analysisConfigStopStep
                onEditingFinished: Globals.BackendWrapper.analysisConfigSetStopStep(text)
            }
        }
    }

    Loader {
        id: addFilesLoader
        source: "../Popups/AddAnalysisConfigFiles.qml"
    }
}
