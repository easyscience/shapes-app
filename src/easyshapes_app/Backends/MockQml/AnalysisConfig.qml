// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Analysis page — equilibration configuration.
//
// Holds:
//   * configFiles  — Pattern D ListModel of .mdp paths (delete + edit per row).
//   * forceFields  — JS array of selectable force-field labels (no edits).
//   * forceField   — currently chosen entry from forceFields.
//   * startStep / stopStep — inclusive integer bounds driving which mdp
//     files participate in equilibration (defaults 0..6, matching the
//     seeded equil0.mdp..equil6.mdp set).
QtObject {

    readonly property var configFiles: ListModel {
        id: configFilesModel
        ListElement { path: 'analysis/equil0.mdp' }
        ListElement { path: 'analysis/equil1.mdp' }
        ListElement { path: 'analysis/equil2.mdp' }
        ListElement { path: 'analysis/equil3.mdp' }
        ListElement { path: 'analysis/equil4.mdp' }
        ListElement { path: 'analysis/equil5.mdp' }
        ListElement { path: 'analysis/equil6.mdp' }
    }

    readonly property var forceFields: [
        'CHARMM36',
        'CHARMM27',
        'AMBER99SB-ILDN',
        'AMBER14SB',
        'OPLS-AA/L',
        'GROMOS54a7',
        'MARTINI 3',
        'MARTINI 2.2',
        'GAFF'
    ]

    property string forceField: 'CHARMM36'

    property int startStep: 0
    property int stopStep: 6

    function appendFile(item) {
        configFilesModel.append({ path: item.path || '' })
    }

    function appendPath(path) {
        configFilesModel.append({ path: path })
    }

    function removeFile(index) {
        if (index < 0 || index >= configFilesModel.count) return
        configFilesModel.remove(index)
    }

    function clearFiles() { configFilesModel.clear() }

    // Mock placeholder for opening the file in an editor.
    function editFile(index) {
        if (index < 0 || index >= configFilesModel.count) return
        console.debug('AnalysisConfig.editFile:', configFilesModel.get(index).path)
    }

    function setForceField(value) {
        if (forceField === value) return
        forceField = value
    }

    function setStartStep(value) {
        const v = Math.max(0, parseInt(value))
        if (isNaN(v) || startStep === v) return
        startStep = v
        if (stopStep < startStep) stopStep = startStep
    }

    function setStopStep(value) {
        const v = Math.max(0, parseInt(value))
        if (isNaN(v) || stopStep === v) return
        stopStep = v
        if (startStep > stopStep) startStep = stopStep
    }
}
