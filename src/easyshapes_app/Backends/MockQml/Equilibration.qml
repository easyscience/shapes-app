// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Mirrors Backend.equilibration: the setup, the run and the files of the
// analysis's equilibration. Stage k runs the configuration's
// equil<k>.mdp: eq0 from the assembled model, a later stage from the
// stage before. The mock's run ends by itself after 10 s; Cancel stops it
// at once, as in Python.
QtObject {
    id: root

    // The setup. lastStage is Python's last_stage, None shown as the
    // configuration's last; threads '' is Auto (None)
    property int firstStage: 0
    property int lastStage: 6
    property string threads: ''
    property bool restrainToBoxCenter: false

    // Stages the configuration holds an equil<k>.mdp for, in order. The
    // loop reads files.count, so an added or removed file counts
    readonly property var availableStages: {
        const files = configuration ? configuration.files : null
        const stages = []
        for (let i = 0; files && i < files.count; ++i) {
            const match = /(?:^|[\\/])equil(\d+)\.mdp$/.exec(files.get(i).path)
            if (match)
                stages.push(parseInt(match[1]))
        }
        return stages.sort((a, b) => a - b)
    }
    // Stages a run can start from: eq0, and each stage after a finished
    // one, that the configuration holds
    property var startableStages: [0]
    onAvailableStagesChanged: _updateStartable()

    // The run
    readonly property bool filesLocked: _run.running
    // The stage the run is on; -1 without a run
    property int stage: -1
    // The log Engine output shows, picked by row of entries. Row 0 is the
    // run's, as Python shows equilibration.log: mdrun -v rewrites its
    // progress line with \r, and the line updates in place. A finished
    // stage shows its mdrun log, <model>-eq<k>.log; a stage running or
    // not run shows ''
    property int selectedLog: 0
    readonly property string log: {
        _statusRevision
        if (selectedLog === 0)
            return _logDone + _progress
        return _finished(entriesModel.get(selectedLog).status) ? _stageLog(selectedLog - 1) : ''
    }

    // A picker of whose files to show: the equilibration first, then
    // each stage run so far. Roles: name, status ('' for the
    // equilibration; 'done', 'running', 'not run', or 'outdated': done,
    // but its stage before finished after it, so it started from older
    // files)
    readonly property var entries: ListModel {
        id: entriesModel
        ListElement { name: 'Equilibration'; status: '' }
    }
    property int selectedEntry: 0
    // The picked entry's files. Roles: path, size, editable (a text file
    // the pencil opens; not the equilibration's copies of the model and
    // its topologies, which each run copies again)
    readonly property var files: ListModel { id: filesModel }

    // Mock only: set by MockBackend. The configuration gives the stages;
    // Equilibrate fails into the error dialog without the model's .gro
    // and .top, as Python's check does
    property var configuration: null
    property var sampleModel: null
    property var error: null

    // A replacement of the project, waiting for the run to stop
    property var _pending: null
    // The status the running stage had before, back after a cancel
    property string _statusBefore: ''
    // The equilibration holds its copies once a run has started
    property bool _staged: false
    // Counts status changes: a binding doesn't follow a row's
    // setProperty
    property int _statusRevision: 0
    readonly property string _model: sampleModel && sampleModel.name ? sampleModel.name : 'model'

    // Each stage of a run takes an equal share of the 10 s
    property Timer _run: Timer {
        repeat: true
        onTriggered: root._finishStage()
    }

    // The log's finished lines, and mdrun's progress line, which each
    // tick rewrites
    property string _logDone: ''
    property string _progress: ''
    property int _step: 0
    property Timer _tick: Timer {
        interval: 200
        repeat: true
        running: root.filesLocked
        onTriggered: {
            root._step += 500
            root._progress = `step ${root._step}, will finish Wed Nov  4 15:42:10 2026\n`
        }
    }

    // Fake files. A size is a fake label: the mock never touches the disk
    readonly property var _equilibrationFiles: [
        { path: 'toppar/forcefield.itp', size: '1.2 MB', editable: false },
        { path: 'toppar/SDS.itp', size: '8 kB', editable: false },
        { path: 'toppar/TIP3.itp', size: '1 kB', editable: false },
        { path: 'toppar/SOD.itp', size: '1 kB', editable: false },
        { path: '<model>.gro', size: '3.1 MB', editable: false },
        { path: '<model>.top', size: '1 kB', editable: false },
        { path: 'equilibration.log', size: '96 kB', editable: true }
    ]
    readonly property var _stageFiles: [
        { suffix: '.mdp', size: '2 kB', editable: true },
        { suffix: '-mdout.mdp', size: '9 kB', editable: true },
        { suffix: '.tpr', size: '1.4 MB', editable: false },
        { suffix: '.gro', size: '3.1 MB', editable: true },
        { suffix: '.edr', size: '640 kB', editable: false },
        { suffix: '.cpt', size: '2.2 MB', editable: false },
        { suffix: '.log', size: '96 kB', editable: true }
    ]

    // The last stage is never before the first
    onFirstStageChanged: if (lastStage < firstStage) lastStage = firstStage

    function run() {
        const problem = _problem()
        if (problem) {
            error.message = `ValueError: ${problem}`
            return
        }
        // A stage run for the first time joins the list
        for (let k = firstStage; k <= lastStage; ++k)
            if (k === entriesModel.count - 1)
                entriesModel.append({ name: `eq${k}`, status: 'not run' })
        _staged = true
        _logDone = ''
        _progress = ''
        // The run's log shows from its start
        selectedLog = 0
        _run.interval = 10000 / (lastStage - firstStage + 1)
        _startStage(firstStage)
        _run.start()
        if (selectedEntry === 0)
            _fillFiles()
    }

    // The running stage keeps its earlier files, as in Python
    function cancel() {
        _keepProgress()
        _setStatus(stage, _statusBefore)
        _end()
    }

    // Calls then once no run goes on: at once, or once the running one is
    // cancelled
    function afterEquilibration(then) {
        if (!filesLocked) {
            then()
            return
        }
        _pending = then
        cancel()
    }

    function selectEntry(index) {
        selectedEntry = index
        _fillFiles()
    }

    function selectLog(index) {
        selectedLog = index
    }

    function editFile(index) {
        if (index < 0 || index >= filesModel.count) return
        console.debug('Equilibration.editFile:', filesModel.get(index).path)
    }

    // The mock has no file system: a folder ending in 'taken' counts as
    // taken, as in Project.locationTaken
    function exportTaken(folder, row) {
        return folder.endsWith('taken')
    }

    // Row -1 exports the whole picked entry, a row that one file
    function exportTo(folder, row, overwrite) {
        console.debug('Equilibration.exportTo:', entriesModel.get(selectedEntry).name, 'row:', row,
                      '->', folder, 'overwrite:', overwrite)
    }

    function openFolder() {
        console.debug('Equilibration.openFolder:', entriesModel.get(selectedEntry).name)
    }

    // Python's refusals before a start, the ones the mock can meet
    function _problem() {
        let gro = false
        let top = false
        for (let i = 0; i < sampleModel.files.count; ++i) {
            const path = sampleModel.files.get(i).path
            gro = gro || path.endsWith('.gro')
            top = top || path.endsWith('.top')
        }
        if (!gro || !top)
            return `${_model} holds no assembled .gro and .top; assemble it with a buffer first`
        const missing = []
        for (let k = firstStage; k <= lastStage; ++k)
            if (!availableStages.includes(k))
                missing.push(`equil${k}.mdp`)
        if (missing.length > 0)
            return `The configuration holds no ${missing.join(', ')}`
        if (!startableStages.includes(firstStage))
            return `Stage ${firstStage - 1} hasn't finished, so stage ${firstStage} can't start`
        return ''
    }

    function _startStage(k) {
        stage = k
        _statusBefore = entriesModel.get(k + 1).status
        _setStatus(k, 'running')
        const deffnm = `eq${k}/${_model}-eq${k}`
        const start = k === 0 ? `${_model}.gro` : `eq${k - 1}/${_model}-eq${k - 1}.gro`
        _logDone += `$ gmx grompp -f ${deffnm}.mdp -c ${start} -r ${start} -p ${_model}.top`
                    + ` -o ${deffnm}.tpr -po ${deffnm}-mdout.mdp -maxwarn 4\n`
                    + 'Processing topology...\n'
                    + `$ gmx mdrun -v -deffnm ${_model}-eq${k}\n`
        _step = 0
        _progress = ''
    }

    // The progress line ends with the last step, as in a terminal
    function _keepProgress() {
        _logDone += _progress
        _progress = ''
    }

    function _finishStage() {
        _keepProgress()
        _logDone += 'Writing final coordinates.\n'
        // Later finished stages started from this stage's older files
        for (let i = stage + 2; i < entriesModel.count; ++i)
            if (entriesModel.get(i).status === 'done')
                entriesModel.setProperty(i, 'status', 'outdated')
        _setStatus(stage, 'done')
        if (stage < lastStage)
            _startStage(stage + 1)
        else
            _end()
    }

    function _end() {
        _run.stop()
        stage = -1
        const then = _pending
        _pending = null
        if (then) then()
    }

    function _setStatus(k, status) {
        entriesModel.setProperty(k + 1, 'status', status)
        _statusRevision++
        _updateStartable()
        if (selectedEntry === k + 1)
            _fillFiles()
    }

    function _updateStartable() {
        const stages = [0]
        // Row i holds stage i - 1: stage i may start once it has
        // finished, outdated too, as the library allows
        for (let i = 1; i < entriesModel.count; ++i)
            if (_finished(entriesModel.get(i).status))
                stages.push(i)
        startableStages = stages.filter(k => availableStages.includes(k))
    }

    function _finished(status) {
        return status === 'done' || status === 'outdated'
    }

    // A fake mdrun log of stage k: its head, one energy frame, its end
    function _stageLog(k) {
        return `Log file opened on Wed Nov  4 15:30:00 2026\n`
               + `GROMACS:      gmx mdrun, version 2025.3\n`
               + `Command line:\n  gmx mdrun -v -deffnm ${_model}-eq${k}\n\n`
               + `   integrator  = ${k === 0 ? 'steep' : 'md'}\n\n`
               + '           Step           Time\n'
               + '              0        0.00000\n\n'
               + '   Energies (kJ/mol)\n'
               + '      Potential    Kinetic En.   Total Energy    Temperature\n'
               + '   -1.20345e+06    2.12345e+05   -9.91105e+05    3.10000e+02\n\n'
               + 'Finished mdrun on rank 0 Wed Nov  4 15:42:10 2026\n'
    }

    function _fillFiles() {
        filesModel.clear()
        if (selectedEntry === 0) {
            if (!_staged) return
            for (const file of _equilibrationFiles)
                filesModel.append({
                    path: 'equilibration/' + file.path.replace('<model>', _model),
                    size: file.size,
                    editable: file.editable
                })
            return
        }
        // A stage holds files once it has finished
        if (!_finished(entriesModel.get(selectedEntry).status)) return
        const k = selectedEntry - 1
        for (const file of _stageFiles)
            filesModel.append({
                path: `equilibration/eq${k}/${_model}-eq${k}${file.suffix}`,
                size: file.size,
                editable: file.editable
            })
    }
}
