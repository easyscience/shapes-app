// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals

EaElements.StatusBar {

    visible: EaGlobals.Vars.appBarCurrentIndex !== 0

    EaElements.StatusBarItem {
        keyIcon: "archive"
        keyText: qsTr("Project")
        valueText: Globals.BackendWrapper.projectName
        ToolTip.text: qsTr("Current project")
    }

    EaElements.StatusBarItem {
        keyIcon: "vial"
        keyText: qsTr("Shape")
        // Bare shape for a discrete model, or "Lattice (<shape>)" on a lattice.
        valueText: {
            const shape = Globals.BackendWrapper.sampleModelShape
            if (!shape)
                return ""
            return Globals.BackendWrapper.sampleModelLattice
                   ? qsTr("Lattice (%1)").arg(shape.toLowerCase())
                   : shape
        }
        ToolTip.text: qsTr("Current sample model shape and lattice arrangement")
    }

    EaElements.StatusBarItem {
        keyIcon: "puzzle-piece"
        keyText: qsTr("Components")
        valueText: "" + (Globals.BackendWrapper.componentsLoaded
                         ? Globals.BackendWrapper.componentsLoaded.count
                         : 0)
        ToolTip.text: qsTr("Number of components")
    }

    EaElements.StatusBarItem {
        keyIcon: "cogs"
        keyText: qsTr("Engine")
        valueText: Globals.BackendWrapper.configGmxVersion
                   ? `GROMACS ${Globals.BackendWrapper.configGmxVersion}`
                   : Globals.BackendWrapper.configGmxProblem
        ToolTip.text: qsTr("Simulation engine (GROMACS version, or why it can't run)")
    }

    EaElements.StatusBarItem {
        keyIcon: "bezier-curve"
        keyText: qsTr("Force field")
        valueText: Globals.BackendWrapper.analysisConfigForceField
        ToolTip.text: qsTr("Force field selected on the Analysis page")
    }
}
