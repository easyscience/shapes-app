// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents


EaComponents.SideBarColumn {

    EaElements.GroupBox {
        title: qsTr('Components Files')
        icon: 'file-alt'
        collapsed: false

        Loader { source: 'Groups/ComponentsFiles.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Position Restraints')
        icon: 'thumbtack'

        Loader { source: 'Groups/PositionRestraints.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Structure Files')
        icon: 'folder-open'

        Loader { source: 'Groups/StructureFiles.qml' }
    }

}
