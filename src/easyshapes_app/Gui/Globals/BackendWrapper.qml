// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

// This module is registered in the main.py file and allows access to the properties
// and backend  methods of the singleton object of the ‘PyBackend’ class.
// If ‘PyBackend’ is not defined, then 'MockBackend' from directory 'Backends' is used.
// It is needed to run the GUI frontend via the qml runtime tool without any Python backend.
import Backends as Backends


QtObject {

    ////////////////
    // Backend proxy
    ////////////////

    readonly property var activeBackend: {
        if (typeof Backends.PyBackend !== 'undefined') {
            console.debug('REAL python backend is in use')
            return Backends.PyBackend
        } else {
            console.debug('MOCK QML backend is in use')
            return Backends.MockBackend
        }
    }

    /////////////
    // Status bar
    /////////////

    readonly property string statusProject: activeBackend.status.project
    readonly property string statusPhasesCount: activeBackend.status.phasesCount
    readonly property string statusExperimentsCount: activeBackend.status.experimentsCount
    readonly property string statusCalculator: activeBackend.status.calculator
    readonly property string statusMinimizer: activeBackend.status.minimizer
    readonly property string statusVariables: activeBackend.status.variables

    ///////////////
    // Project page
    ///////////////

    readonly property var projectInfo: activeBackend.project.info
    readonly property var projectExamples: activeBackend.project.examples

    property bool projectCreated: activeBackend.project.created
    onProjectCreatedChanged: activeBackend.project.created = projectCreated
    property string projectName: activeBackend.project.name
    onProjectNameChanged: activeBackend.project.name = projectName

    function projectCreate() { activeBackend.project.create() }
    function projectSave() { activeBackend.project.save() }
    function projectEditInfo(path, new_value) { activeBackend.project.editInfo(path, new_value) }

    ////////////////////
    // Sample Model page
    ////////////////////

    readonly property var sampleModelLoaded: activeBackend.sampleModel.loaded
    readonly property var sampleModelAvailable: activeBackend.sampleModel.availableModels
    readonly property var sampleModelStructureTypes: activeBackend.sampleModel.structureTypes
    readonly property string sampleModelCurrentStructureType: activeBackend.sampleModel.currentStructureType

    property bool sampleModelCreated: activeBackend.sampleModel.created
    onSampleModelCreatedChanged: activeBackend.sampleModel.created = sampleModelCreated

    function sampleModelSetLoaded(model) { activeBackend.sampleModel.setLoaded(model) }
    function sampleModelUpdateField(field, value) {
        activeBackend.sampleModel.updateField(field, value)
        // updateField mutates `loaded[0]` in place to avoid recreating the
        // ListView delegate (which would steal focus from any field being
        // edited). The trade-off is that `loadedChanged` doesn't fire, so
        // bindings derived from `loaded` won't re-evaluate. Mirror the
        // structure_type into its own property here so visibility bindings
        // (Layers/Lamellae GroupBoxes) update.
        if (field === 'structure_type') activeBackend.sampleModel.currentStructureType = value
    }
    function sampleModelClear() { activeBackend.sampleModel.clear() }
    function sampleModelSaveToCatalog() { activeBackend.sampleModel.saveToCatalog() }
    function sampleModelRemoveFromCatalog(index) { activeBackend.sampleModel.removeFromCatalog(index) }

    // Components group (Sample Model sidebar)
    readonly property var componentsLoaded: activeBackend.components.loaded
    readonly property var componentsPendingFilePaths: activeBackend.components.pendingFilePaths

    function componentsAppend(item) { activeBackend.components.appendItem(item) }
    function componentsRemove(index) { activeBackend.components.removeItem(index) }
    function componentsClear() { activeBackend.components.clear() }
    function componentsAppendPendingFilePath(path) { activeBackend.components.appendPendingFilePath(path) }
    function componentsRemovePendingFilePath(index) { activeBackend.components.removePendingFilePath(index) }
    function componentsClearPendingFilePaths() { activeBackend.components.clearPendingFilePaths() }

    // Global default Fractions set (fallback for the Fractions sidebar
    // component). Layers/Lamellae do NOT use this — see the per-row
    // fraction accessors below.
    readonly property var fractionsModel: activeBackend.fractions.model

    function fractionsSetFracs(index, value) { activeBackend.fractions.setFracs(index, value) }
    function fractionsSetPresent(index, value) { activeBackend.fractions.setPresent(index, value) }

    // Layers (Sample Model sidebar). One Fractions instance per layer is
    // owned by the backend; the GUI binds the fractions list of the
    // currently-selected layer via layersFractionsModelAt(row).
    readonly property var layersItems: activeBackend.layers.items
    readonly property int layersFractionsRevision: activeBackend.layers.fractionsRevision

    function layersAppend(item) { activeBackend.layers.appendItem(item) }
    function layersRemove(index) { activeBackend.layers.removeItem(index) }
    function layersSetDmin(index, value) { activeBackend.layers.setDmin(index, value) }
    function layersSetRmin(index, value) { activeBackend.layers.setRmin(index, value) }
    // Callers binding through this must also reference layersFractionsRevision
    // in their binding body to re-evaluate when rows are inserted/removed.
    function layersFractionsModelAt(index) { return activeBackend.layers.fractionsModelAt(index) }

    // Lamellae (Sample Model sidebar). One inner and one outer Fractions
    // instance are owned per lamella; asymmetric lamellae bind both models.
    readonly property var lamellaeItems: activeBackend.lamellae.items
    readonly property int lamellaeItemsRevision: activeBackend.lamellae.itemsRevision
    readonly property int lamellaeFractionsRevision: activeBackend.lamellae.fractionsRevision

    function lamellaeAppend(item) { activeBackend.lamellae.appendItem(item) }
    function lamellaeRemove(index) { activeBackend.lamellae.removeItem(index) }
    function lamellaeSetRmin(index, value) { activeBackend.lamellae.setRmin(index, value) }
    function lamellaeSetInnerDmin(index, value) { activeBackend.lamellae.setInnerDmin(index, value) }
    function lamellaeSetOuterDmin(index, value) { activeBackend.lamellae.setOuterDmin(index, value) }
    function lamellaeSetShell(index, value) { activeBackend.lamellae.setShell(index, value) }
    function lamellaeSetSymmetric(index, value) { activeBackend.lamellae.setSymmetric(index, value) }
    // Callers binding through these must also reference lamellaeFractionsRevision
    // in their binding body to re-evaluate when rows are inserted/removed.
    function lamellaeInnerFractionsModelAt(index) { return activeBackend.lamellae.innerFractionsModelAt(index) }
    function lamellaeOuterFractionsModelAt(index) { return activeBackend.lamellae.outerFractionsModelAt(index) }

    // Ring structure (Sample Model sidebar). Single-record fielded form
    // shown only when sampleModelCurrentStructureType === 'Ring'.
    readonly property var ringStructure: activeBackend.ringStructure

    // Ball structure (Sample Model sidebar). Single-record fielded form
    // shown only when sampleModelCurrentStructureType === 'Ball'.
    readonly property var ballStructure: activeBackend.ballStructure

    // Vesicle structure (Sample Model sidebar). Single-record fielded form
    // shown only when sampleModelCurrentStructureType === 'Vesicle'.
    readonly property var vesicleStructure: activeBackend.vesicleStructure

    // Rod structure (Sample Model sidebar). Single-record fielded form
    // shown only when sampleModelCurrentStructureType === 'Rod'.
    readonly property var rodStructure: activeBackend.rodStructure

    // Bilayer structure (Sample Model sidebar). Single-record fielded form
    // shown only when sampleModelCurrentStructureType === 'Bilayer'.
    readonly property var bilayerStructure: activeBackend.bilayerStructure

    // Monolayer structure (Sample Model sidebar). Single-record fielded form
    // shown only when sampleModelCurrentStructureType === 'Monolayer'.
    readonly property var monolayerStructure: activeBackend.monolayerStructure

    // Lattice structure (Sample Model sidebar). Single-record fielded form
    // shown only when sampleModelCurrentStructureType === 'Lattice'. The
    // substructure slot mirrors the SampleModel loaded/available shape, so
    // the embedded list/popups follow the same recipe.
    readonly property var latticeStructure: activeBackend.latticeStructure
    readonly property var latticeSubstructureLoaded: activeBackend.latticeStructure.substructureLoaded
    readonly property var latticeSubstructureAvailable: activeBackend.latticeStructure.availableSubstructures
    readonly property var latticeSubstructureTypes: activeBackend.latticeStructure.substructureTypes

    function latticeSubstructureSetLoaded(item) { activeBackend.latticeStructure.setSubstructureLoaded(item) }
    function latticeSubstructureClear() { activeBackend.latticeStructure.clearSubstructure() }
    function latticeSubstructureSaveToCatalog() { activeBackend.latticeStructure.saveSubstructureToCatalog() }
    function latticeSubstructureRemoveFromCatalog(index) { activeBackend.latticeStructure.removeSubstructureFromCatalog(index) }

    // Solution group (Sample Model sidebar). Two backend-owned slots:
    //   * solution — single-record JS array (capacity 0 or 1), TIP3 by default.
    //   * ions     — ListModel with at most 2 rows, name only.

    readonly property var solutionLoaded: activeBackend.solution.loaded
    readonly property var solutionAvailable: activeBackend.solution.available
    readonly property var solutionTypes: activeBackend.solution.solutionTypes

    function solutionSetLoaded(item) { activeBackend.solution.setLoaded(item) }
    function solutionUpdateField(field, value) { activeBackend.solution.updateField(field, value) }
    function solutionClear() { activeBackend.solution.clear() }
    function solutionSaveToCatalog() { activeBackend.solution.saveToCatalog() }
    function solutionRemoveFromCatalog(index) { activeBackend.solution.removeFromCatalog(index) }

    // Solvent aliases — same backend object, used by the solvent table popup files.
    readonly property var solventLoaded: activeBackend.solution.loaded
    readonly property var solventAvailable: activeBackend.solution.available
    readonly property var solventTypes: activeBackend.solution.solutionTypes

    function solventSetLoaded(item) { activeBackend.solution.setLoaded(item) }
    function solventUpdateField(field, value) { activeBackend.solution.updateField(field, value) }
    function solventClear() { activeBackend.solution.clear() }
    function solventSaveToCatalog() { activeBackend.solution.saveToCatalog() }
    function solventRemoveFromCatalog(index) { activeBackend.solution.removeFromCatalog(index) }

    readonly property var ionsLoaded: activeBackend.ions.loaded
    readonly property var ionsAvailable: activeBackend.ions.available

    function ionsAppend(item) { activeBackend.ions.appendItem(item) }
    function ionsRemove(index) { activeBackend.ions.removeItem(index) }
    function ionsClear() { activeBackend.ions.clear() }
    function ionsSaveToCatalog() { activeBackend.ions.saveToCatalog() }
    function ionsRemoveFromCatalog(index) { activeBackend.ions.removeFromCatalog(index) }

    ////////////////
    // Analysis page
    ////////////////

    // All the properties and methods related to the analysis page
    // are defined directly in the Backends/MockQml/Analysis.qml !!!

    ///////////////
    // Summary page
    ///////////////

    readonly property string reportAsHtml: activeBackend.report.asHtml

    property bool reportCreated: activeBackend.report.created
    onReportCreatedChanged: activeBackend.report.created = reportCreated
}
