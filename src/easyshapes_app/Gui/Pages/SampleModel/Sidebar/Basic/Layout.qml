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
        title: qsTr('Model Definition')
        icon: 'tag'
        collapsed: false

        Loader { id: sampleModelLoader; source: 'Groups/SampleModel.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Components')
        icon: 'puzzle-piece'

        Loader { source: 'Groups/Components.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Layers')
        icon: 'layer-group' // 'grip-lines'
        visible: sampleModelLoader.item ? sampleModelLoader.item.currentStructureType === 'Ball' : false

        Loader { source: 'Groups/Layers.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Lamellae')
        icon: 'layer-group'
        visible: sampleModelLoader.item ? sampleModelLoader.item.currentStructureType === 'Vesicle' : false

        Loader { source: 'Groups/Lamellae.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Solvent')
        icon: 'grip-horizontal'

        Loader { source: 'Groups/Group3.qml' }
    }

    EaElements.GroupBox {
        title: qsTr('Group 1')
        icon: 'rocket'

        Loader { source: 'Groups/Group2.qml' }
    }

}
