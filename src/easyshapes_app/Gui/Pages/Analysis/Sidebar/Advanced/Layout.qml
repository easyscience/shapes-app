// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents


EaComponents.SideBarColumn {

    EaElements.GroupBox {
        title: qsTr("Configuration Files")
        icon: "file-alt"
        collapsed: false

        Loader { source: "Groups/ConfigurationFiles.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Force Field Files")
        icon: "atom"
        collapsed: false

        Loader { source: "Groups/ForceFieldFiles.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Equilibration Files")
        icon: "folder-open"
        collapsed: false

        Loader { source: "Groups/EquilibrationFiles.qml" }
    }

}
