// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApp.Gui.Elements as EaElements
import EasyApp.Gui.Components as EaComponents

import Gui.Globals as Globals


EaComponents.SideBarColumn {

    EaElements.GroupBox {
        title: qsTr('Group 1')
        icon: 'rocket'

        Loader { source: 'Groups/Group1.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Group 2')
        icon: 'rocket'

        Loader { source: 'Groups/Group2.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Group 3')
        icon: 'rocket'

        Loader { source: 'Groups/Group3.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Group 4')
        icon: 'rocket'

        Loader { source: 'Groups/Group4.qml' }
    }

}
