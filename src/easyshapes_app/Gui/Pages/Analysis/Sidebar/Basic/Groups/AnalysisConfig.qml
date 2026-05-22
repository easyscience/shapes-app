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

    EaComponents.ListView {
        id: configFilesList
        defaultInfoText: qsTr('No configuration files added')
        multiSelection: false

        columnWidths: [
            EaStyle.Sizes.fontPixelSize * 2.5,
            -1,
            EaStyle.Sizes.tableRowHeight,
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
            EaComponents.TableViewLabel {
                color: EaStyle.Colors.themeForegroundMinor
            }
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
                fontIcon: 'edit'
                ToolTip.text: qsTr('Edit this file')
                onClicked: Globals.BackendWrapper.analysisConfigEditFile(index)
            }
            EaComponents.TableViewButton {
                fontIcon: 'minus-circle'
                ToolTip.text: qsTr('Remove this file')
                onClicked: Globals.BackendWrapper.analysisConfigRemoveFile(index)
            }
        }
    }

    EaElements.SideBarButton {
        fontIcon: 'plus-circle'
        text: qsTr('Add file(s)')
        width: EaStyle.Sizes.sideBarContentWidth * 0.48
        ToolTip.text: qsTr('Pick one or more .mdp files from disk')
        onClicked: addFilesLoader.item.open()
    }

    // ForceField selector on the left, step-range pair on the right.
    Row {
        spacing: EaStyle.Sizes.fontPixelSize
        property real halfWidth: (EaStyle.Sizes.sideBarContentWidth - spacing) / 2
        property real fieldWidth: (halfWidth - EaStyle.Sizes.fontPixelSize * 0.5) / 2

        EaElements.ComboBox {
            id: forceFieldSelector
            width: parent.halfWidth
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
                text: qsTr('ForceField')
            }
        }

        Row {
            spacing: EaStyle.Sizes.fontPixelSize * 0.5

            EaElements.TextField {
                id: startStepField
                width: parent.parent.fieldWidth
                topInset: startStepLabel.height
                topPadding: topInset + padding
                horizontalAlignment: TextInput.AlignLeft
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0 }
                text: Globals.BackendWrapper.analysisConfigStartStep
                onEditingFinished: Globals.BackendWrapper.analysisConfigSetStartStep(text)

                EaElements.Label {
                    id: startStepLabel
                    text: qsTr('Start step')
                }
            }

            EaElements.TextField {
                id: stopStepField
                width: parent.parent.fieldWidth
                topInset: stopStepLabel.height
                topPadding: topInset + padding
                horizontalAlignment: TextInput.AlignLeft
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0 }
                text: Globals.BackendWrapper.analysisConfigStopStep
                onEditingFinished: Globals.BackendWrapper.analysisConfigSetStopStep(text)

                EaElements.Label {
                    id: stopStepLabel
                    text: qsTr('Stop step')
                }
            }
        }
    }

    Loader {
        id: addFilesLoader
        source: '../Popups/AddAnalysisConfigFiles.qml'
    }
}
