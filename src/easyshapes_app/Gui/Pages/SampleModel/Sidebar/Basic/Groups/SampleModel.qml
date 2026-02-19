// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
//import QtQuick.Dialogs

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Elements as EaElements
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Logic as EaLogic

import Gui.Globals as Globals

EaElements.GroupColumn {

    EaComponents.TableView {
        defaultInfoText: qsTr("No models defined")
        header: EaComponents.TableViewHeader {}
    }

    Grid {

        columns: 2
        spacing: EaStyle.Sizes.fontPixelSize

        // button 1
        EaElements.SideBarButton {
            fontIcon: 'upload'
            text: qsTr('Load an existing model')

            onClicked: {
                console.debug(`Clicking '${text}' button ::: ${this}`)
                Globals.References.pages.samplemodel.sidebar.basic.popups.LoadExistingModel.open()
            }

            Loader {
                source: '../Popups/LoadExistingModel.qml'
            }
        }
        // button 1


        // button 2
        EaElements.SideBarButton {
            fontIcon: 'plus-circle'
            text: qsTr('Create a new model')

            onClicked: {
                console.debug(`Clicking '${text}' button ::: ${this}`)
                Globals.References.pages.samplemodel.sidebar.basic.popups.CreateNewModel.open()
            }

            Loader {
                source: '../Popups/CreateNewModel.qml'
            }
        }
        // button 2


    }

}
