// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals


EaElements.GroupColumn {
    id: root
    property double buttonWidth: (EaStyle.Sizes.sideBarContentWidth - (EaStyle.Sizes.fontPixelSize * 2) ) / 3

    Column {
        width: EaStyle.Sizes.sideBarContentWidth * 0.5

        EaElements.Label {
            enabled: false
            text: qsTr('Solvent')
        }

        EaComponents.ListView {
            id: loadedSolvent
            defaultInfoText: qsTr('Load or import a solvent')
            multiSelection: false

            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 7,
                EaStyle.Sizes.fontPixelSize * 8,
                -1
            ]

            header: EaComponents.ListViewHeader {
                EaComponents.TableViewLabel {
                    text: qsTr('Name')
                    color: EaStyle.Colors.themeForegroundMinor
                }
                EaComponents.TableViewLabel {
                    text: qsTr('Type')
                    color: EaStyle.Colors.themeForegroundMinor
                }
                EaComponents.TableViewLabel {
                    text: qsTr('Description')
                    color: EaStyle.Colors.themeForegroundMinor
                }
            }

            model: Globals.BackendWrapper.solutionLoaded

            delegate: EaComponents.ListViewDelegate {
                required property var modelData
                required property int index

                EaComponents.ListViewTextInput {
                    text: modelData ? modelData.name : ''
                    onEditingFinished: Globals.BackendWrapper.solventUpdateField('name', text)
                }
                EaComponents.TableViewComboBox {
                    model: Globals.BackendWrapper.solventTypes
                    Component.onCompleted: {
                        currentIndex = model.indexOf(modelData.solvent_type)
                    }
                    onActivated: (i) => {
                        Globals.BackendWrapper.solventUpdateField('solvent_type', model[i])
                    }
                }
                EaComponents.ListViewTextInput {
                    text: modelData ? modelData.description : ''
                    onEditingFinished: Globals.BackendWrapper.solventUpdateField('description', text)
                }
            }
        }
    }

    Grid {
        columns: 3
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: 'upload'
            text: qsTr('Load solvent')
            width: buttonWidth
            onClicked: loadExistingSolvent.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: 'plus-circle'
            text: qsTr('Import solvent')
            width: buttonWidth
            onClicked: createNewSolvent.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: 'download'
            text: qsTr('Save solvent')
            width: buttonWidth
            enabled: Globals.BackendWrapper.solventLoaded.length > 0
                  && Globals.BackendWrapper.solventLoaded[0].name !== ""
            onClicked: Globals.BackendWrapper.solventSaveToCatalog()
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            width: EaStyle.Sizes.sideBarContentWidth / 3
            spacing: EaStyle.Sizes.fontPixelSize

            EaElements.Label {
                enabled: false
                text: qsTr('Ions')
            }

            Row {
                id: ionChipRow
                spacing: EaStyle.Sizes.fontPixelSize * 0.5
                height: EaStyle.Sizes.fontPixelSize * 2
                width: buttonWidth

                EaElements.Label {
                    visible: ionChipRow.ionCount === 0
                    enabled: false
                    text: qsTr('No ions loaded')
                    anchors.verticalCenter: parent.verticalCenter
                }

                readonly property int ionCount:
                    Globals.BackendWrapper.ionsLoaded
                        ? Globals.BackendWrapper.ionsLoaded.count
                        : 0

                Repeater {
                    model: Globals.BackendWrapper.ionsLoaded

                    delegate: Rectangle {
                        required property int index
                        required property string name

                        height: ionChipRow.height
                        width: EaStyle.Sizes.fontPixelSize
                             + chipLabel.implicitWidth
                             + EaStyle.Sizes.fontPixelSize
                             + chipRemove.width
                             + EaStyle.Sizes.fontPixelSize * 0.6
                        radius: height / 2
                        color: EaStyle.Colors.appBarBackground
                        border.color: EaStyle.Colors.appBarComboBoxBorder
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: EaStyle.Sizes.fontPixelSize
                            anchors.rightMargin: chipRemove.width + EaStyle.Sizes.fontPixelSize * 0.25
                            spacing: EaStyle.Sizes.fontPixelSize * 0.25

                            EaElements.Label {
                                id: chipLabel
                                text: name
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        EaElements.Label {
                            id: chipRemove
                            text: '×'
                            font.pixelSize: EaStyle.Sizes.fontPixelSize * 1.4
                            color: chipRemoveArea.containsMouse
                                   ? EaStyle.Colors.themeForegroundHovered
                                   : EaStyle.Colors.themeForegroundMinor
                            anchors.right: parent.right
                            anchors.rightMargin: EaStyle.Sizes.fontPixelSize * 0.6
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                id: chipRemoveArea
                                anchors.fill: parent
                                anchors.margins: -EaStyle.Sizes.fontPixelSize * 0.3
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Globals.BackendWrapper.ionsRemove(index)
                            }

                            EaElements.ToolTip {
                                text: qsTr('Remove this ion')
                                visible: chipRemoveArea.containsMouse
                                      && EaGlobals.Vars.showToolTips
                            }
                        }
                    }
                }
            }

            EaElements.SideBarButton {
                fontIcon: 'upload'
                text: qsTr('Load ion')
                width: buttonWidth
                enabled: ionChipRow.ionCount < 2
                onClicked: loadExistingIonLoader.item.open()
            }
        }

        Column {
            width: EaStyle.Sizes.sideBarContentWidth / 3
            spacing: EaStyle.Sizes.fontPixelSize

            Column {
                width: parent.width

                EaElements.Label {
                    enabled: false
                    text: qsTr('Amount')
                }
                EaElements.TextField {
                    id: ionAmountField
                    width: parent.width
                    enabled: !matchStructureCheck.checked
                    placeholderText: qsTr('Set the amount of selected ions')
                    validator: IntValidator { bottom: 0 }
                }
            }
            EaElements.CheckBox {
                id: matchStructureCheck
                text: qsTr('Match components')
                checked: false
                onCheckedChanged: {
                    if (checked) {
                        ionAmountField.text = ''
                        ionAmountField.placeholderText = 'Will match the structure components'
                    }
                    else ionAmountField.placeholderText = 'Set the amount of ions'
                }
            }
        }
    }

    Loader {
        id: loadExistingSolvent
        source: '../Popups/LoadExistingSolvent.qml'
    }
    Loader {
        id: createNewSolvent
        source: '../Popups/CreateNewSolvent.qml'
    }
    Loader {
        id: loadExistingIonLoader
        source: '../Popups/LoadExistingIon.qml'
    }
}
