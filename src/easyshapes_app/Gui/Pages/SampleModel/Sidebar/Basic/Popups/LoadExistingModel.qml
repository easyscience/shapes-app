// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import EasyApp.Gui.Globals as EaGlobals
import EasyApp.Gui.Components as EaComponents
import EasyApp.Gui.Elements as EaElements

import Gui.Globals as Globals



EaElements.Dialog{

    Column {
        EaElements.Label {
            enabled: false
            text: qsTr("Name")
        }

        EaElements.Label {
            text: qsTr("Name 2")
        }
    }

    Component.onCompleted: {
        Globals.References.pages.samplemodel.sidebar.basic.popups.LoadExistingModel = this
    }

}
