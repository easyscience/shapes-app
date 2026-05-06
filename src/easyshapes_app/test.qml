// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Elements as EaElements
import Qt.labs.qmlmodels

import Gui.Globals as Globals

ApplicationWindow{

    width: 650
    height: 680
    color: EaStyle.Colors.contentBackground
    visible: true

    Grid {
        spacing: EaStyle.Sizes.fontPixelSize * 4
        leftPadding: 12

        Column {
            width: 600
            spacing: EaStyle.Sizes.fontPixelSize

            EaElements.ComboBox {
                model: [qsTr("Light"), qsTr("Dark"), qsTr("System")]
                onActivated: {
                    if (currentIndex === 0)
                        EaStyle.Colors.theme = EaStyle.Colors.LightTheme
                    else if (currentIndex === 1)
                        EaStyle.Colors.theme = EaStyle.Colors.DarkTheme
                    else if (currentIndex === 2)
                        EaStyle.Colors.theme = EaStyle.Colors.SystemTheme
                }
                Component.onCompleted: {
                    if (EaStyle.Colors.theme === EaStyle.Colors.LightTheme)
                        currentIndex = 0
                    else if (EaStyle.Colors.theme === EaStyle.Colors.DarkTheme)
                        currentIndex = 1
                    else if (EaStyle.Colors.theme === EaStyle.Colors.SystemTheme)
                        currentIndex = 2
                }
            }

            // groubox to test the element
            EaElements.GroupBox {
                title: qsTr('Test a group widget')
                icon: 'wrench'
                collapsed: false

                Loader { source: 'Gui/Pages/SampleModel/Sidebar/Basic/Groups/BilayerStructure.qml'}
            }

            EaElements.GroupBox {
                title: qsTr('Test a group widget')
                icon: 'wrench'
                collapsed: false

                Loader { source: 'Gui/Pages/SampleModel/Sidebar/Basic/Groups/RingStructure.qml'}
            }
        }
    }



    //Component.onCompleted: Globals.References.pages.samplemodel.sidebar.basic.popups.LoadExistingModel.open()

}
