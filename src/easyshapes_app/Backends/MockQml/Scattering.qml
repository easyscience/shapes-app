// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Mirrors Backend.scattering: the setup, the run and the SANS curves of
// the analysis. The mock's run ends by itself after 2 s; Cancel may stop
// it at once. Rules that bring out every state in Qt Creator: every 3rd
// run that reaches its end fails into the error dialog, each curve of eq4
// to eq6 is outdated.
QtObject {
    id: root

    // The setup, with the page's defaults. SLD in 10⁻⁶ Å⁻², q in Å⁻¹;
    // kernel 'auto' (Exact) or 'average' (Fast)
    property real solventSld: -0.56
    property var deuterated: []
    property real qMin: 0.002
    property real qMax: 0.2
    property int qPoints: 256
    property real sizeSpread: 0.25
    property string kernel: 'auto'

    // What can be calculated: the sample model, named after it (status
    // ''), once its files hold a .gro; then the Equilibration mock's
    // finished stages ('done' or 'outdated'). Roles: name, status
    readonly property var structures: ListModel { id: structuresModel }
    // Row of structures shown; -1 with none
    property int selectedStructure: -1
    // The sample model's components: the ones that can be deuterated
    property var components: []

    // The curves with data. Roles: name, settings (the hover text),
    // status ('done' or 'outdated'), rg (Å), shown. Mock only, to match
    // settings and to draw: structure, stage ('' for the model), sld,
    // deuteratedKey, qMin, qMax, qPoints, sizeSpread, kernel
    readonly property var curves: ListModel { id: curvesModel }

    // The run, and its curve's name; '' without one
    readonly property bool filesLocked: _run.running
    property string runningCurve: ''

    // Over the shown curves: log10 of q and I
    readonly property var ranges: {
        _revision
        let xmin = Infinity, xmax = -Infinity, ymin = Infinity, ymax = -Infinity
        for (let row = 0; row < curvesModel.count; ++row) {
            if (!curvesModel.get(row).shown) continue
            for (const point of curvePoints(row)) {
                xmin = Math.min(xmin, point.x)
                xmax = Math.max(xmax, point.x)
                ymin = Math.min(ymin, point.y)
                ymax = Math.max(ymax, point.y)
            }
        }
        return xmin === Infinity ? { xmin: 0, xmax: 1, ymin: 0, ymax: 1 } : { xmin, xmax, ymin, ymax }
    }

    // Mock only: set by MockBackend. The structures follow the model's
    // files and the equilibration's stages; a failed run writes the error
    property var sampleModel: null
    property var equilibration: null
    property var loadedComponents: null
    property var error: null

    // The structure picked by hand, by name; '' until one is
    property string _picked: ''
    // The settings the running calculation took; null without a run
    property var _running: null
    property int _finishedRuns: 0
    // Counts curve changes: a binding doesn't follow a row's setProperty
    property int _revision: 0

    // The run's end. A curve run again keeps its row, found by its name,
    // and its Show: calculate is off during the run, so no curve can take
    // a new curve's name meanwhile
    property Timer _run: Timer {
        interval: 2000
        onTriggered: {
            root._finishedRuns++
            const running = root._running
            if (root._finishedRuns % 3 === 0) {
                root.error.message = `ValueError: Residue ${root.components[0] ?? 'SDS'} has 42 atoms in `
                                     + `${running.structure}, but its masses list 41`
            } else {
                const stage = running.stage ? parseInt(running.stage.slice(2)) : -1
                const curve = Object.assign({}, running, {
                    name: root.runningCurve,
                    settings: `q ${running.qMin} to ${running.qMax} Å⁻¹, ${running.qPoints} points, `
                              + `polydispersity ${running.sizeSpread}, ${running.kernel === 'auto' ? 'exact' : 'fast'}`,
                    status: [4, 5, 6].includes(stage) ? 'outdated' : 'done',
                    rg: Math.round((24.1 + 0.5 * (stage + 1)) * 10) / 10
                })
                let row = -1
                for (let i = 0; i < curvesModel.count; ++i)
                    if (curvesModel.get(i).name === root.runningCurve)
                        row = i
                if (row >= 0)
                    curvesModel.set(row, curve)
                else
                    curvesModel.append(Object.assign(curve, { shown: true }))
                root._revision++
            }
            root._running = null
            root.runningCurve = ''
        }
    }

    // A stage finishes or joins; the model's files change; a component
    // comes, goes or is renamed
    property var _stagesSync: Connections {
        target: root.equilibration ? root.equilibration.entries : null
        function onDataChanged() { root._rebuild() }
        function onRowsInserted() { root._rebuild() }
    }
    property var _filesSync: Connections {
        target: root.sampleModel ? root.sampleModel.files : null
        function onCountChanged() { root._rebuild() }
    }
    // The model's row is named after it
    property var _nameSync: Connections {
        target: root.sampleModel
        function onNameChanged() { root._rebuild() }
    }
    property var _componentsSync: Connections {
        target: root.loadedComponents
        function onCountChanged() { root._refreshComponents() }
        function onDataChanged() { root._refreshComponents() }
    }

    onSampleModelChanged: _rebuild()
    onEquilibrationChanged: _rebuild()
    onLoadedComponentsChanged: _refreshComponents()

    function selectStructure(index) {
        if (index < 0 || index >= structuresModel.count) return
        _picked = structuresModel.get(index).name
        selectedStructure = index
    }

    // Kept in the components' order, as the curve's name lists them
    function setDeuterated(name, on) {
        deuterated = components.filter(n => n === name ? on : deuterated.includes(n))
    }

    // A curve with these settings runs again under its name; with none, a
    // new one joins the list once its run succeeds
    function calculate() {
        if (selectedStructure < 0) return
        const picked = structuresModel.get(selectedStructure)
        const settings = {
            structure: picked.name,
            // The model's row is the one without a status
            stage: picked.status ? picked.name : '',
            sld: solventSld,
            deuteratedKey: deuterated.join(','),
            qMin, qMax, qPoints, sizeSpread, kernel
        }
        let name = ''
        const taken = []
        for (let row = 0; row < curvesModel.count; ++row) {
            const curve = curvesModel.get(row)
            if (Object.keys(settings).every(key => curve[key] === settings[key]))
                name = curve.name
            taken.push(curve.name)
        }
        // As P3 makes it: the model's name, then the stage (none for the
        // model itself), -sld and the SLD, -d and each deuterated
        // component, -pd and the polydispersity; -2, -3 when a curve with
        // other settings holds the name
        if (!name) {
            const base = (sampleModel?.name || 'model') + (settings.stage ? `-${settings.stage}` : '')
                         + `-sld${Number(solventSld.toPrecision(6))}`
                         + deuterated.map(n => `-d${n}`).join('')
                         + `-pd${Number(sizeSpread.toPrecision(6))}`
            name = base
            for (let k = 2; taken.includes(name); ++k)
                name = `${base}-${k}`
        }
        _running = settings
        runningCurve = name
        _run.start()
    }

    // A new curve is not added; a curve run again keeps its data
    function cancel() {
        _run.stop()
        _running = null
        runningCurve = ''
    }

    function setCurveShown(row, on) {
        curvesModel.setProperty(row, 'shown', on)
        _revision++
    }

    function removeCurve(row) {
        curvesModel.remove(row)
        _revision++
    }

    // The curve as points, log10 of q and I, for LineSeries.replace. A
    // sphere of the curve's Rg over 7 sizes of its size spread, at the
    // contrast of the aggregate (higher with each deuterated component)
    // against the solvent; the floor keeps log10 finite at the zeros
    function curvePoints(row) {
        const curve = curvesModel.get(row)
        const radius = curve.rg * Math.sqrt(5 / 3)
        const deuteratedCount = curve.deuteratedKey ? curve.deuteratedKey.split(',').length : 0
        const contrast = 0.3 + 2 * deuteratedCount - curve.sld
        const points = []
        for (let i = 0; i < curve.qPoints; ++i) {
            const q = curve.qMin * Math.pow(curve.qMax / curve.qMin, i / (curve.qPoints - 1))
            let sum = 0
            let volume = 0
            for (let t = -3; t <= 3; ++t) {
                const r = radius * (1 + curve.sizeSpread * t / 2)
                if (r <= 0) continue
                const weight = Math.exp(-t * t / 8)
                const x = q * r
                const amplitude = 3 * (Math.sin(x) - x * Math.cos(x)) / (x * x * x)
                sum += weight * Math.pow(r, 6) * amplitude * amplitude
                volume += weight * Math.pow(r, 3)
            }
            points.push(Qt.point(Math.log10(q), Math.log10(1e-4 * contrast * contrast * sum / volume + 1e-4)))
        }
        return points
    }

    // The mock has no file system: a folder ending in 'taken' counts as
    // taken, as in Project.locationTaken
    function exportTaken(folder) {
        return folder.endsWith('taken')
    }

    // The .dat of every curve ticked Show
    function exportTo(folder, overwrite) {
        const names = []
        for (let row = 0; row < curvesModel.count; ++row)
            if (curvesModel.get(row).shown)
                names.push(curvesModel.get(row).name)
        console.debug('Scattering.exportTo:', names.join(', '), '->', folder, 'overwrite:', overwrite)
    }

    function _rebuild() {
        const listed = []
        for (let i = 0; i < structuresModel.count; ++i)
            listed.push(structuresModel.get(i).name)
        structuresModel.clear()
        // The model's row once its files hold a .gro, named as the
        // Equilibration mock names an unnamed model
        const files = sampleModel ? sampleModel.files : null
        for (let i = 0; files && i < files.count; ++i) {
            if (files.get(i).path.endsWith('.gro')) {
                structuresModel.append({ name: sampleModel.name || 'model', status: '' })
                break
            }
        }
        const entries = equilibration ? equilibration.entries : null
        // Row 0 is the equilibration itself
        for (let i = 1; entries && i < entries.count; ++i) {
            const entry = entries.get(i)
            if (entry.status !== 'done' && entry.status !== 'outdated') continue
            structuresModel.append({ name: entry.name, status: entry.status })
            // A stage that just finished becomes the pick
            if (!listed.includes(entry.name)) _picked = entry.name
        }
        let row = structuresModel.count - 1
        for (let i = 0; i < structuresModel.count; ++i)
            if (structuresModel.get(i).name === _picked)
                row = i
        selectedStructure = row
    }

    function _refreshComponents() {
        const names = []
        for (let i = 0; loadedComponents && i < loadedComponents.count; ++i)
            names.push(loadedComponents.get(i).name)
        components = names
        // A ticked component that leaves the model is unticked
        deuterated = deuterated.filter(name => names.includes(name))
    }
}
