// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// The equilibration's setup: its configuration and force field from the
// library, the stages to run, mdrun's threads and the restraints. Stage
// k runs the configuration's equil<k>.mdp. Off while a run goes on: the
// run uses what was set at its start.
EaElements.GroupColumn {
    id: root
    property double halfWidth: (EaStyle.Sizes.sideBarContentWidth - EaStyle.Sizes.fontPixelSize) / 2
    property double thirdWidth: (EaStyle.Sizes.sideBarContentWidth - 2 * EaStyle.Sizes.fontPixelSize) / 3

    readonly property var startable: Globals.BackendWrapper.equilibrationStartableStages
    // The last stage is never before the first
    readonly property var lastOptions: Globals.BackendWrapper.equilibrationAvailableStages
                                       .filter(k => k >= Globals.BackendWrapper.equilibrationFirstStage)

    enabled: !Globals.BackendWrapper.equilibrationFilesLocked

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Configuration")
            }
            // Shows the name also after a rename in Configuration Files
            // takes it out of the catalog
            EaElements.ComboBox {
                width: root.halfWidth
                model: Globals.BackendWrapper.libraryAvailableAnalysisConfigurations
                currentIndex: model.indexOf(Globals.BackendWrapper.configurationName)
                displayText: Globals.BackendWrapper.configurationName
                onActivated: (index) => Globals.BackendWrapper.configurationLoad(model[index])
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Force field")
            }
            EaElements.ComboBox {
                width: root.halfWidth
                model: Globals.BackendWrapper.libraryAvailableForceFields
                currentIndex: model.indexOf(Globals.BackendWrapper.forceFieldName)
                displayText: Globals.BackendWrapper.forceFieldName
                onActivated: (index) => Globals.BackendWrapper.forceFieldLoad(model[index])
            }
        }
    }

    Row {
        spacing: EaStyle.Sizes.fontPixelSize

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("First stage")
            }
            // eq0, and each stage after a finished one
            EaElements.ComboBox {
                width: root.thirdWidth
                model: root.startable.map(k => `eq${k}`)
                currentIndex: root.startable.indexOf(Globals.BackendWrapper.equilibrationFirstStage)
                displayText: `eq${Globals.BackendWrapper.equilibrationFirstStage}`
                onActivated: (index) => Globals.BackendWrapper.equilibrationSetFirstStage(root.startable[index])
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Last stage")
            }
            EaElements.ComboBox {
                width: root.thirdWidth
                model: root.lastOptions.map(k => `eq${k}`)
                currentIndex: root.lastOptions.indexOf(Globals.BackendWrapper.equilibrationLastStage)
                displayText: `eq${Globals.BackendWrapper.equilibrationLastStage}`
                onActivated: (index) => Globals.BackendWrapper.equilibrationSetLastStage(root.lastOptions[index])
            }
        }

        Column {
            EaElements.Label {
                enabled: false
                text: qsTr("Threads")
            }
            // Empty is Auto: mdrun picks. More than the cores is
            // allowed: mdrun warns and runs. IntValidator would count
            // empty as unfinished and never send it
            EaElements.TextField {
                width: root.thirdWidth
                horizontalAlignment: TextInput.AlignLeft
                placeholderText: qsTr("Auto")
                validator: RegularExpressionValidator { regularExpression: /^([1-9][0-9]*)?$/ }
                ToolTip.text: qsTr("Threads mdrun runs on; empty lets it pick")
                text: Globals.BackendWrapper.equilibrationThreads
                onEditingFinished: Globals.BackendWrapper.equilibrationSetThreads(text)
            }
        }
    }

    EaElements.CheckBox {
        height: EaStyle.Sizes.fontPixelSize * 2.5
        text: qsTr("Restrain to box centre")
        ToolTip.text: qsTr("Anchor the position restraints of the structure's components at the box centre, not at their atoms' starting positions")
        checked: Globals.BackendWrapper.equilibrationRestrainToBoxCenter
        onToggled: Globals.BackendWrapper.equilibrationSetRestrainToBoxCenter(checked)
    }
}
