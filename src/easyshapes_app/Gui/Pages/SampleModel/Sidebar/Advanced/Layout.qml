// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents


EaComponents.SideBarColumn {

    EaElements.GroupBox {
        title: qsTr("Library assets")
        icon: "book"
        collapsed: false

        Loader { source: "Groups/LibraryAssetsFiles.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Components Files")
        icon: "file-alt"

        Loader { source: "Groups/ComponentsFiles.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("Sample Model Files")
        icon: "folder-open"

        Loader { source: "Groups/StructureFiles.qml" }
    }

    EaElements.GroupBox {
        title: qsTr("SMILES generator")
        icon: "atom"

        Loader { source: "Groups/SmilesGenerator.qml" }
    }

}
