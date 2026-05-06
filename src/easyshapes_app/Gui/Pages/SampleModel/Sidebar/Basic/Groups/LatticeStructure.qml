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
    Row {
        property real itemWidth: EaStyle.Sizes.sideBarContentWidth * 0.3
        spacing: (EaStyle.Sizes.sideBarContentWidth - (itemWidth * 3)) / 2

        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr('Alpha')
            units: '⚬'
            validator: DoubleValidator { bottom: 0; top: 360 }
            text: Globals.BackendWrapper.latticeStructure.alpha
            onEditingFinished: Globals.BackendWrapper.latticeStructure.alpha = parseFloat(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr('Theta')
            units: '⚬'
            validator: DoubleValidator { bottom: 0; top: 180 }
            text: Globals.BackendWrapper.latticeStructure.theta
            onEditingFinished: Globals.BackendWrapper.latticeStructure.theta = parseFloat(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr('Sbuff')
            units: 'nm'
            validator: DoubleValidator { bottom: 0 }
            text: Globals.BackendWrapper.latticeStructure.sbuff
            onEditingFinished: Globals.BackendWrapper.latticeStructure.sbuff = parseFloat(text)
        }
    }

    Row {
        property real itemWidth: EaStyle.Sizes.sideBarContentWidth * 0.2
        spacing: (EaStyle.Sizes.sideBarContentWidth - (itemWidth * 4)) / 3


        Column {
            width: parent.itemWidth

            EaElements.Label {
                enabled: false
                text: qsTr('Type')
            }
            EaElements.ComboBox {
                width: parent.width
                model: Globals.BackendWrapper.latticeStructure.latticeTypes
                Component.onCompleted: {
                    currentIndex = model.indexOf(Globals.BackendWrapper.latticeStructure.latticeType)
                }
                onActivated: (i) => {
                    Globals.BackendWrapper.latticeStructure.latticeType = model[i]
                }
            }
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr('Nlatx')
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructure.nlatx
            onEditingFinished: Globals.BackendWrapper.latticeStructure.nlatx = parseInt(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr('Nlaty')
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructure.nlaty
            onEditingFinished: Globals.BackendWrapper.latticeStructure.nlaty = parseInt(text)
        }
        EaElements.Parameter {
            width: parent.itemWidth
            title: qsTr('Nlatz')
            validator: IntValidator { bottom: 1 }
            text: Globals.BackendWrapper.latticeStructure.nlatz
            onEditingFinished: Globals.BackendWrapper.latticeStructure.nlatz = parseInt(text)
        }

    }

    Column {
        width: parent.width

        EaElements.Label {
            enabled: false
            text: qsTr('Substructure')
        }

        EaComponents.ListView {
            id: loadedSubstructure
            defaultInfoText: qsTr('Load or create a substructure')
            multiSelection: false

            columnWidths: [
                EaStyle.Sizes.fontPixelSize * 12,
                EaStyle.Sizes.fontPixelSize * 6,
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

            model: Globals.BackendWrapper.latticeSubstructureLoaded

            delegate: EaComponents.ListViewDelegate {
                required property var modelData
                required property int index

                EaComponents.TableViewLabel {
                    text: modelData ? modelData.name : ''
                    enabled: false
                }
                EaComponents.TableViewLabel {
                    text: modelData ? modelData.structure_type : ''
                    enabled: false
                }
                EaComponents.TableViewLabel {
                    text: modelData ? modelData.description : ''
                    enabled: false
                }
            }
        }
    }

    Row {
        property double buttonWidth: (sideBarContentWidth - fontPixelSize) / 2
        spacing: EaStyle.Sizes.fontPixelSize

        EaElements.SideBarButton {
            fontIcon: 'upload'
            text: qsTr('Load structure')
            width: buttonWidth
            onClicked: loadExistingSubstructureLoader.item.open()
        }

        EaElements.SideBarButton {
            fontIcon: 'plus-circle'
            text: qsTr('Import structure')
            width: buttonWidth
            onClicked: createNewSubstructureLoader.item.open()
        }
    }

    Loader {
        id: loadExistingSubstructureLoader
        source: '../Popups/LoadExistingSubstructure.qml'
    }

    Loader {
        id: createNewSubstructureLoader
        source: '../Popups/CreateNewSubstructure.qml'
    }
}
