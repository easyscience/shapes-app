// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Analysis page — equilibration step outputs (Advanced sidebar).
//
// Equilibration writes one output directory per step in the configured
// [startStep, stopStep] range of AnalysisConfig, so a 0..6 range yields
// step0/ .. step6/. The GUI picks one directory from `steps` and lists its
// contents from `files`.
//
// Holds:
//   * steps         — Pattern D ListModel of output directories
//                     (roles: name, dir, step).
//   * files         — Pattern D ListModel of the selected directory's contents
//                     (roles: name, path, size).
//   * selectedIndex — row of `steps` whose contents `files` mirrors, -1 when
//                     nothing is generated or selected.
//
// Both models start empty: no directory exists until Equilibrate runs.
QtObject {

    readonly property var steps: ListModel { id: stepsModel }

    readonly property var files: ListModel { id: filesModel }

    property int selectedIndex: -1

    readonly property string selectedDir:
        selectedIndex >= 0 && selectedIndex < stepsModel.count
            ? stepsModel.get(selectedIndex).dir
            : ''

    // Files the engine writes into every step directory. Sizes are fake labels
    // — the real backend will stat the files on disk.
    readonly property var fileTemplate: [
        { suffix: 'tpr', size: '1.4 MB' },
        { suffix: 'gro', size: '3.1 MB' },
        { suffix: 'xtc', size: '18.7 MB' },
        { suffix: 'edr', size: '640 kB' },
        { suffix: 'cpt', size: '2.2 MB' },
        { suffix: 'log', size: '96 kB' }
    ]

    // Rebuild the directory set from an inclusive step range. Called after
    // equilibration; wipes any previous run and selects the first step.
    function generate(start, stop) {
        stepsModel.clear()
        filesModel.clear()
        selectedIndex = -1

        const from = Math.min(start, stop)
        const to = Math.max(start, stop)
        for (let s = from; s <= to; ++s) {
            stepsModel.append({
                name: qsTr('Step %1').arg(s),
                dir: 'analysis/step' + s,
                step: s
            })
        }
        if (stepsModel.count > 0)
            selectStep(0)
    }

    // Repopulate `files` from the step directory at `index`.
    function selectStep(index) {
        if (index < 0 || index >= stepsModel.count) {
            selectedIndex = -1
            filesModel.clear()
            return
        }
        selectedIndex = index
        const entry = stepsModel.get(index)
        filesModel.clear()
        for (let i = 0; i < fileTemplate.length; ++i) {
            const name = 'equil' + entry.step + '.' + fileTemplate[i].suffix
            filesModel.append({
                name: name,
                path: entry.dir + '/' + name,
                size: fileTemplate[i].size
            })
        }
    }

    // Mock placeholder — real backend will copy the file to a chosen location.
    function exportFile(index) {
        if (index < 0 || index >= filesModel.count) return
        console.debug('EquilibrationOutputs.exportFile:', filesModel.get(index).path)
    }

    // Mock placeholder — real backend will archive the selected step directory.
    function exportStep() {
        console.debug('EquilibrationOutputs.exportStep:', selectedDir,
                      'files=' + filesModel.count)
    }

    // Mock placeholder — real backend will reveal the directory in the file
    // manager.
    function openDir() {
        console.debug('EquilibrationOutputs.openDir:', selectedDir)
    }
}
