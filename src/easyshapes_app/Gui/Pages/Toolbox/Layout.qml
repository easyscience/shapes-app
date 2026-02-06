// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Elements as EaElements
import EasyApp.Gui.Components as EaComponents

import Gui.Globals as Globals


EaComponents.ContentPage {

    mainView: EaComponents.MainContent {
        tabs: [
            EaElements.TabButton { text: qsTr('Image') },
            EaElements.TabButton { text: qsTr('EaElements.GraphsView') },
            EaElements.TabButton { text: qsTr('EaElements.TextArea (Plain)') },
            EaElements.TabButton { text: qsTr('EaElements.TextArea (Rich)') }
        ]

        items: [
            Loader { source: 'MainArea/Image.qml' },
            Loader { source: 'MainArea/GraphsView.qml' },
            Loader { source: 'MainArea/TextAreaPlain.qml' },
            Loader { source: 'MainArea/TextAreaRich.qml' }
        ]
    }

    sideBar: EaComponents.SideBar {
        tabs: [
            EaElements.TabButton { text: qsTr('Basic controls') }
        ]

        items: [
            Loader { source: 'Sidebar/Basic/Layout.qml' }
        ]

        continueButton.visible: false

    }

    Component.onCompleted: console.debug(`Toolbox page loaded ::: ${this}`)
    Component.onDestruction: console.debug(`Toolbox page destroyed ::: ${this}`)

}
