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

    //////////
    // Project
    //////////

    readonly property bool projectCreated: activeBackend.project.created
    readonly property string projectName: activeBackend.project.name
    readonly property string projectDescription: activeBackend.project.description
    readonly property string projectPath: activeBackend.project.path
    readonly property string projectPathParentUrl: activeBackend.project.pathParentUrl
    readonly property string projectModified: activeBackend.project.modified

    function projectSetName(value) { activeBackend.project.name = value }
    function projectSetDescription(value) { activeBackend.project.description = value }
    function projectCreate(name, description, path) { activeBackend.project.create(name, description, path) }
    function projectSave() { activeBackend.project.save() }
    function projectLoad(path) { activeBackend.project.load(path) }
    function projectLocationTaken(path) { return activeBackend.project.locationTaken(path) }

    //////////
    // Library
    //////////

    readonly property var libraryAvailableProjects: activeBackend.library.availableProjects
    readonly property var libraryAvailableExamples: activeBackend.library.availableExamples
    readonly property var libraryAvailableIons: activeBackend.library.availableIons

    /////////
    // Config
    /////////

    readonly property string configGmxVersion: activeBackend.config.gmxVersion
    readonly property string configGmxProblem: activeBackend.config.gmxProblem

    ////////
    // Error
    ////////

    readonly property string errorMessage: activeBackend.error.message

    function errorSetMessage(value) { activeBackend.error.message = value }

    ////////////////////
    // Sample Model page
    ////////////////////

    //////////////
    // SampleModel
    //////////////

    readonly property string sampleModelName: activeBackend.sampleModel.name
    readonly property var sampleModelShapes: activeBackend.sampleModel.shapes
    readonly property string sampleModelShape: activeBackend.sampleModel.shape
    readonly property bool sampleModelLattice: activeBackend.sampleModel.lattice

    function sampleModelSetName(value) { activeBackend.sampleModel.name = value }
    function sampleModelSetShape(value) { activeBackend.sampleModel.shape = value }
    function sampleModelSetLattice(value) { activeBackend.sampleModel.lattice = value }
    function sampleModelCreate() { activeBackend.sampleModel.create() }

    // Load model catalog: mock only until the library catalogs (step 5)
    readonly property var sampleModelAvailable: activeBackend.sampleModel.availableModels

    function sampleModelSetLoaded(model) { activeBackend.sampleModel.setLoaded(model) }
    function sampleModelRemoveFromCatalog(index) { activeBackend.sampleModel.removeFromCatalog(index) }

    ////////////////
    // RingStructure
    ////////////////

    readonly property real ringStructureAlpha: activeBackend.ringStructure.alpha
    readonly property real ringStructureTheta: activeBackend.ringStructure.theta
    readonly property real ringStructureDmin: activeBackend.ringStructure.dmin
    readonly property real ringStructureRmin: activeBackend.ringStructure.rmin
    readonly property bool ringStructureFxz: activeBackend.ringStructure.fxz
    readonly property bool ringStructureRev: activeBackend.ringStructure.rev

    function ringStructureSetAlpha(value) { activeBackend.ringStructure.alpha = value }
    function ringStructureSetTheta(value) { activeBackend.ringStructure.theta = value }
    function ringStructureSetDmin(value) { activeBackend.ringStructure.dmin = value }
    function ringStructureSetRmin(value) { activeBackend.ringStructure.rmin = value }
    function ringStructureSetFxz(value) { activeBackend.ringStructure.fxz = value }
    function ringStructureSetRev(value) { activeBackend.ringStructure.rev = value }

    ////////////////
    // BallStructure
    ////////////////

    readonly property bool ballStructureFxz: activeBackend.ballStructure.fxz
    readonly property bool ballStructureRev: activeBackend.ballStructure.rev
    readonly property string ballStructureFill: activeBackend.ballStructure.fill

    function ballStructureSetFxz(value) { activeBackend.ballStructure.fxz = value }
    function ballStructureSetRev(value) { activeBackend.ballStructure.rev = value }
    function ballStructureSetFill(value) { activeBackend.ballStructure.fill = value }

    ///////////////////
    // VesicleStructure
    ///////////////////

    readonly property bool vesicleStructureFxz: activeBackend.vesicleStructure.fxz
    readonly property bool vesicleStructureRev: activeBackend.vesicleStructure.rev
    readonly property string vesicleStructureFill: activeBackend.vesicleStructure.fill

    function vesicleStructureSetFxz(value) { activeBackend.vesicleStructure.fxz = value }
    function vesicleStructureSetRev(value) { activeBackend.vesicleStructure.rev = value }
    function vesicleStructureSetFill(value) { activeBackend.vesicleStructure.fill = value }

    ///////////////
    // RodStructure
    ///////////////

    readonly property int rodStructureTurns: activeBackend.rodStructure.turns
    readonly property real rodStructureDmin: activeBackend.rodStructure.dmin
    readonly property real rodStructureRmin: activeBackend.rodStructure.rmin
    readonly property bool rodStructureFxz: activeBackend.rodStructure.fxz
    readonly property bool rodStructureRev: activeBackend.rodStructure.rev

    function rodStructureSetTurns(value) { activeBackend.rodStructure.turns = value }
    function rodStructureSetDmin(value) { activeBackend.rodStructure.dmin = value }
    function rodStructureSetRmin(value) { activeBackend.rodStructure.rmin = value }
    function rodStructureSetFxz(value) { activeBackend.rodStructure.fxz = value }
    function rodStructureSetRev(value) { activeBackend.rodStructure.rev = value }

    ///////////////////
    // BilayerStructure
    ///////////////////

    readonly property real bilayerStructureDmin: activeBackend.bilayerStructure.dmin
    readonly property real bilayerStructureZsep: activeBackend.bilayerStructure.zsep
    readonly property int bilayerStructureNside: activeBackend.bilayerStructure.nside

    function bilayerStructureSetDmin(value) { activeBackend.bilayerStructure.dmin = value }
    function bilayerStructureSetZsep(value) { activeBackend.bilayerStructure.zsep = value }
    function bilayerStructureSetNside(value) { activeBackend.bilayerStructure.nside = value }

    /////////////////////
    // MonolayerStructure
    /////////////////////

    readonly property real monolayerStructureDmin: activeBackend.monolayerStructure.dmin
    readonly property real monolayerStructureZsep: activeBackend.monolayerStructure.zsep
    readonly property int monolayerStructureNside: activeBackend.monolayerStructure.nside

    function monolayerStructureSetDmin(value) { activeBackend.monolayerStructure.dmin = value }
    function monolayerStructureSetZsep(value) { activeBackend.monolayerStructure.zsep = value }
    function monolayerStructureSetNside(value) { activeBackend.monolayerStructure.nside = value }

    ///////////////////
    // LatticeStructure
    ///////////////////

    readonly property real latticeStructureAlpha: activeBackend.latticeStructure.alpha
    readonly property real latticeStructureTheta: activeBackend.latticeStructure.theta
    readonly property int latticeStructureNlatx: activeBackend.latticeStructure.nlatx
    readonly property int latticeStructureNlaty: activeBackend.latticeStructure.nlaty
    readonly property int latticeStructureNlatz: activeBackend.latticeStructure.nlatz
    readonly property real latticeStructureSbuff: activeBackend.latticeStructure.sbuff
    readonly property string latticeStructureLatticeType: activeBackend.latticeStructure.latticeType

    function latticeStructureSetAlpha(value) { activeBackend.latticeStructure.alpha = value }
    function latticeStructureSetTheta(value) { activeBackend.latticeStructure.theta = value }
    function latticeStructureSetNlatx(value) { activeBackend.latticeStructure.nlatx = value }
    function latticeStructureSetNlaty(value) { activeBackend.latticeStructure.nlaty = value }
    function latticeStructureSetNlatz(value) { activeBackend.latticeStructure.nlatz = value }
    function latticeStructureSetSbuff(value) { activeBackend.latticeStructure.sbuff = value }
    function latticeStructureSetLatticeType(value) { activeBackend.latticeStructure.latticeType = value }

    // Components group (Sample Model sidebar)
    readonly property var componentsLoaded: activeBackend.components.loaded
    readonly property string componentsErrors: activeBackend.components.loaded.errors
    readonly property var componentsPendingFilePaths: activeBackend.components.pendingFilePaths

    function componentsAppend(item) { activeBackend.components.appendItem(item) }
    function componentsRemove(index) { activeBackend.components.remove(index) }
    function componentsAppendPendingFilePath(path) { activeBackend.components.appendPendingFilePath(path) }
    function componentsRemovePendingFilePath(index) { activeBackend.components.removePendingFilePath(index) }
    function componentsClearPendingFilePaths() { activeBackend.components.clearPendingFilePaths() }

    // Atomistic structure of a loaded component, for the Components viewer:
    // parsed [{element, x, y, z}] (Å) fed to the Qt Quick 3D viewer. The mock
    // returns one shared template molecule for every component.
    function componentStructureAtoms(index) { return activeBackend.components.structureAtoms(index) }

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

    // Buffer group (Sample Model sidebar). Solvent is a single selected value
    // ('(None)' / TIP3 / Ethanol); buffer components are a row list (salts,
    // buffering agents) backed by a shared catalog.
    readonly property var bufferSolventOptions: activeBackend.buffer.solventOptions
    property string bufferSolvent: activeBackend.buffer.solvent
    onBufferSolventChanged: activeBackend.buffer.solvent = bufferSolvent

    readonly property var bufferComponents: activeBackend.buffer.components
    readonly property var bufferComponentsAvailable: activeBackend.buffer.available

    function bufferComponentsAppend(item) { activeBackend.buffer.appendComponent(item) }
    function bufferComponentsRemove(index) { activeBackend.buffer.removeComponent(index) }

    readonly property var ionsLoaded: activeBackend.ions.loaded
    readonly property var ionsAvailable: activeBackend.ions.available

    function ionsAppend(item) { activeBackend.ions.appendItem(item) }
    function ionsRemove(index) { activeBackend.ions.removeItem(index) }
    function ionsClear() { activeBackend.ions.clear() }
    function ionsSaveToCatalog() { activeBackend.ions.saveToCatalog() }
    function ionsRemoveFromCatalog(index) { activeBackend.ions.removeFromCatalog(index) }

    // Components Files (Sample Model Advanced sidebar). Per-component file
    // list driven by `componentsFilesSelectedComponent`; switching the
    // selection repopulates `componentsFilesFiles`.
    readonly property var componentsFilesFiles: activeBackend.componentsFiles.files
    readonly property string componentsFilesSelectedComponent: activeBackend.componentsFiles.selectedComponent
    readonly property string componentsFilesEditName: activeBackend.componentsFiles.editName

    function componentsFilesSelect(name) { activeBackend.componentsFiles.selectComponent(name) }
    function componentsFilesCreateNew() { activeBackend.componentsFiles.createNew() }
    function componentsFilesSetEditName(name) { activeBackend.componentsFiles.editName = name }
    function componentsFilesAppend(path) { activeBackend.componentsFiles.appendFile(path) }
    function componentsFilesRemove(index) { activeBackend.componentsFiles.removeFile(index) }
    function componentsFilesEditFile(index) { activeBackend.componentsFiles.editFile(index) }
    function componentsFilesExportFile(index, destination) { activeBackend.componentsFiles.exportFile(index, destination) }
    function componentsFilesExportComponent(destination) { activeBackend.componentsFiles.exportComponent(destination) }

    // Save the current file list to the asset library and load the component
    // into the basic-tab components list (under whatever name is in the name
    // field) if it isn't already there.
    function componentsFilesSave() {
        const name = activeBackend.componentsFiles.save()
        if (!name)
            return
        const loaded = activeBackend.components.loaded
        for (let i = 0; i < loaded.count; ++i) {
            if (loaded.get(i).name === name)
                return
        }
        activeBackend.components.appendItem({
            name: name,
            component_type: 'Other',
            c_ion: '',
            mint: 0,
            mext: 0
        })
    }

    // Structure Files (Sample Model Advanced sidebar). List of structure-
    // related files plus actions for saving the set to the asset library
    // and re-seeding structure parameters from a serialized data file.
    readonly property var structureFilesFiles: activeBackend.structureFiles.files

    function structureFilesAppend(item) { activeBackend.structureFiles.appendItem(item) }
    function structureFilesAppendPath(path) { activeBackend.structureFiles.appendPath(path) }
    function structureFilesRemove(index) { activeBackend.structureFiles.removeItem(index) }
    function structureFilesClear() { activeBackend.structureFiles.clear() }
    function structureFilesSaveToLib() { activeBackend.structureFiles.saveToLib() }
    function structureFilesExport(destination) { activeBackend.structureFiles.exportFiles(destination) }

    // Library Assets editor (Advanced sidebar). A single draft asset the user
    // creates or loads from the library, edits, and saves back. `mode` is
    // 'empty' | 'create' | 'edit'; the type is editable only while creating.
    readonly property string libraryAssetsMode: activeBackend.libraryAssets.mode
    readonly property var libraryAssetsTypeOptions: activeBackend.libraryAssets.typeOptions
    readonly property string libraryAssetsType: activeBackend.libraryAssets.assetType
    readonly property string libraryAssetsName: activeBackend.libraryAssets.assetName
    readonly property string libraryAssetsCIon: activeBackend.libraryAssets.cIon
    readonly property int libraryAssetsMint: activeBackend.libraryAssets.mint
    readonly property int libraryAssetsMext: activeBackend.libraryAssets.mext
    readonly property var libraryAssetsPaths: activeBackend.libraryAssets.paths
    readonly property var libraryAssetsLibrary: activeBackend.libraryAssets.library
    // Salt composition (used when the type is 'Salt'). `saltReady` is true once
    // a name and both ions are set.
    readonly property var libraryAssetsSaltComposition: activeBackend.libraryAssets.saltComposition
    readonly property bool libraryAssetsSaltReady: activeBackend.libraryAssets.saltReady

    function libraryAssetsCreateNew() { activeBackend.libraryAssets.createNew() }
    function libraryAssetsSetSaltIon(index, value) { activeBackend.libraryAssets.setSaltIon(index, value) }
    function libraryAssetsSetSaltCount(index, value) { activeBackend.libraryAssets.setSaltCount(index, value) }
    function libraryAssetsLoad(item) { activeBackend.libraryAssets.loadAsset(item) }
    function libraryAssetsSetType(value) { activeBackend.libraryAssets.assetType = value }
    function libraryAssetsSetName(value) { activeBackend.libraryAssets.assetName = value }
    function libraryAssetsSetCIon(value) { activeBackend.libraryAssets.cIon = value }
    function libraryAssetsSetMint(value) { activeBackend.libraryAssets.mint = value }
    function libraryAssetsSetMext(value) { activeBackend.libraryAssets.mext = value }
    function libraryAssetsAppendPath(path) { activeBackend.libraryAssets.appendPath(path) }
    function libraryAssetsRemovePath(index) { activeBackend.libraryAssets.removePath(index) }
    function libraryAssetsEditPath(index) { activeBackend.libraryAssets.editPath(index) }
    function libraryAssetsExportPath(index, destination) { activeBackend.libraryAssets.exportPath(index, destination) }
    function libraryAssetsSave() { activeBackend.libraryAssets.save() }
    function libraryAssetsExport(destination) { activeBackend.libraryAssets.exportAsset(destination) }

    // SMILES generator (Advanced sidebar). Builds a 3D molecular configuration
    // from a SMILES string. `smilesReady` is true once a name and SMILES string
    // are provided.
    readonly property string smilesMoleculeName: activeBackend.smilesGenerator.moleculeName
    readonly property string smilesFormula: activeBackend.smilesGenerator.formula
    readonly property string smilesString: activeBackend.smilesGenerator.smiles
    readonly property real smilesBoxX: activeBackend.smilesGenerator.boxX
    readonly property real smilesBoxY: activeBackend.smilesGenerator.boxY
    readonly property real smilesBoxZ: activeBackend.smilesGenerator.boxZ
    readonly property var smilesFormatOptions: activeBackend.smilesGenerator.formatOptions
    readonly property string smilesFormat: activeBackend.smilesGenerator.format
    readonly property var smilesComponentTypeOptions: activeBackend.smilesGenerator.componentTypeOptions
    readonly property string smilesComponentType: activeBackend.smilesGenerator.componentType
    readonly property bool smilesCisDoubleBonds: activeBackend.smilesGenerator.cisDoubleBonds
    readonly property bool smilesAlignZ: activeBackend.smilesGenerator.alignZ
    readonly property bool smilesFlatXZ: activeBackend.smilesGenerator.flatXZ
    readonly property bool smilesReady: activeBackend.smilesGenerator.ready

    function smilesSetMoleculeName(value) { activeBackend.smilesGenerator.moleculeName = value }
    function smilesSetFormula(value) { activeBackend.smilesGenerator.formula = value }
    function smilesSetString(value) { activeBackend.smilesGenerator.smiles = value }
    function smilesSetBoxX(value) { activeBackend.smilesGenerator.boxX = value }
    function smilesSetBoxY(value) { activeBackend.smilesGenerator.boxY = value }
    function smilesSetBoxZ(value) { activeBackend.smilesGenerator.boxZ = value }
    function smilesSetFormat(value) { activeBackend.smilesGenerator.format = value }
    function smilesSetComponentType(value) { activeBackend.smilesGenerator.componentType = value }
    function smilesSetCisDoubleBonds(value) { activeBackend.smilesGenerator.cisDoubleBonds = value }
    function smilesSetAlignZ(value) { activeBackend.smilesGenerator.alignZ = value }
    function smilesSetFlatXZ(value) { activeBackend.smilesGenerator.flatXZ = value }
    function smilesGenerate() { activeBackend.smilesGenerator.generate() }

    ////////////////
    // Analysis page
    ////////////////

    // All the properties and methods related to the analysis page
    // are defined directly in the Backends/MockQml/Analysis.qml !!!

    // Analysis configuration group — equilibration .mdp files, the chosen
    // force field, and the inclusive [start, stop] step range.
    readonly property var analysisConfigFiles: activeBackend.analysisConfig.configFiles
    readonly property var analysisConfigForceFields: activeBackend.analysisConfig.forceFields
    readonly property string analysisConfigForceField: activeBackend.analysisConfig.forceField
    readonly property int analysisConfigStartStep: activeBackend.analysisConfig.startStep
    readonly property int analysisConfigStopStep: activeBackend.analysisConfig.stopStep

    function analysisConfigAppendPath(path) { activeBackend.analysisConfig.appendPath(path) }
    function analysisConfigRemoveFile(index) { activeBackend.analysisConfig.removeFile(index) }
    function analysisConfigEditFile(index) { activeBackend.analysisConfig.editFile(index) }
    function analysisConfigSetForceField(value) { activeBackend.analysisConfig.setForceField(value) }
    function analysisConfigSetStartStep(value) { activeBackend.analysisConfig.setStartStep(value) }
    function analysisConfigSetStopStep(value) { activeBackend.analysisConfig.setStopStep(value) }

    // Run the engine, then materialise one output directory per step in the
    // configured [startStep, stopStep] range for the Advanced sidebar.
    function analysisEquilibrate() {
        activeBackend.analysis.equilibrate()
        activeBackend.equilibrationOutputs.generate(
            activeBackend.analysisConfig.startStep,
            activeBackend.analysisConfig.stopStep)
    }

    // Equilibration outputs group (Analysis Advanced sidebar). `steps` lists
    // the per-step output directories; `files` holds the contents of the one
    // currently selected. Both are empty until equilibration has run.
    readonly property var equilOutputsSteps: activeBackend.equilibrationOutputs.steps
    readonly property var equilOutputsFiles: activeBackend.equilibrationOutputs.files
    readonly property int equilOutputsSelectedIndex: activeBackend.equilibrationOutputs.selectedIndex
    readonly property string equilOutputsSelectedDir: activeBackend.equilibrationOutputs.selectedDir

    function equilOutputsSelect(index) { activeBackend.equilibrationOutputs.selectStep(index) }
    function equilOutputsExportFile(index, destination) { activeBackend.equilibrationOutputs.exportFile(index, destination) }
    function equilOutputsExportStep(destination) { activeBackend.equilibrationOutputs.exportStep(destination) }
    function equilOutputsOpenDir() { activeBackend.equilibrationOutputs.openDir() }

    ///////////////
    // Summary page
    ///////////////

    readonly property string reportAsHtml: activeBackend.report.asHtml

    property bool reportCreated: activeBackend.report.created
    onReportCreatedChanged: activeBackend.report.created = reportCreated
}
