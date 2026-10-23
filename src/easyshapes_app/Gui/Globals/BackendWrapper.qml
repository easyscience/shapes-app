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
    readonly property var libraryAvailableAssets: activeBackend.library.availableAssets
    readonly property var libraryAvailableIons: activeBackend.library.availableIons
    readonly property var libraryAvailableSolvents: activeBackend.library.availableSolvents
    readonly property var libraryAvailableSalts: activeBackend.library.availableSalts

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

    // Null while the current shape is not a ring
    readonly property real ringStructureAlpha: activeBackend.ringStructure?.alpha ?? 0
    readonly property real ringStructureTheta: activeBackend.ringStructure?.theta ?? 0
    readonly property real ringStructureDmin: activeBackend.ringStructure?.dmin ?? 0
    readonly property real ringStructureRmin: activeBackend.ringStructure?.rmin ?? 0
    readonly property bool ringStructureFxz: activeBackend.ringStructure?.fxz ?? false
    readonly property bool ringStructureRev: activeBackend.ringStructure?.rev ?? false

    function ringStructureSetAlpha(value) { if (activeBackend.ringStructure) activeBackend.ringStructure.alpha = value }
    function ringStructureSetTheta(value) { if (activeBackend.ringStructure) activeBackend.ringStructure.theta = value }
    function ringStructureSetDmin(value) { if (activeBackend.ringStructure) activeBackend.ringStructure.dmin = value }
    function ringStructureSetRmin(value) { if (activeBackend.ringStructure) activeBackend.ringStructure.rmin = value }
    function ringStructureSetFxz(value) { if (activeBackend.ringStructure) activeBackend.ringStructure.fxz = value }
    function ringStructureSetRev(value) { if (activeBackend.ringStructure) activeBackend.ringStructure.rev = value }

    ////////////////
    // BallStructure
    ////////////////

    // Null while the current shape is not a ball
    readonly property bool ballStructureFxz: activeBackend.ballStructure?.fxz ?? false
    readonly property bool ballStructureRev: activeBackend.ballStructure?.rev ?? false
    readonly property string ballStructureFill: activeBackend.ballStructure?.fill ?? ''

    function ballStructureSetFxz(value) { if (activeBackend.ballStructure) activeBackend.ballStructure.fxz = value }
    function ballStructureSetRev(value) { if (activeBackend.ballStructure) activeBackend.ballStructure.rev = value }
    function ballStructureSetFill(value) { if (activeBackend.ballStructure) activeBackend.ballStructure.fill = value }

    ///////////////////
    // VesicleStructure
    ///////////////////

    // Null while the current shape is not a vesicle
    readonly property bool vesicleStructureFxz: activeBackend.vesicleStructure?.fxz ?? false
    readonly property bool vesicleStructureRev: activeBackend.vesicleStructure?.rev ?? false
    readonly property string vesicleStructureFill: activeBackend.vesicleStructure?.fill ?? ''

    function vesicleStructureSetFxz(value) { if (activeBackend.vesicleStructure) activeBackend.vesicleStructure.fxz = value }
    function vesicleStructureSetRev(value) { if (activeBackend.vesicleStructure) activeBackend.vesicleStructure.rev = value }
    function vesicleStructureSetFill(value) { if (activeBackend.vesicleStructure) activeBackend.vesicleStructure.fill = value }

    ///////////////
    // RodStructure
    ///////////////

    // Null while the current shape is not a rod
    readonly property int rodStructureTurns: activeBackend.rodStructure?.turns ?? 0
    readonly property real rodStructureDmin: activeBackend.rodStructure?.dmin ?? 0
    readonly property real rodStructureRmin: activeBackend.rodStructure?.rmin ?? 0
    readonly property bool rodStructureFxz: activeBackend.rodStructure?.fxz ?? false
    readonly property bool rodStructureRev: activeBackend.rodStructure?.rev ?? false

    function rodStructureSetTurns(value) { if (activeBackend.rodStructure) activeBackend.rodStructure.turns = value }
    function rodStructureSetDmin(value) { if (activeBackend.rodStructure) activeBackend.rodStructure.dmin = value }
    function rodStructureSetRmin(value) { if (activeBackend.rodStructure) activeBackend.rodStructure.rmin = value }
    function rodStructureSetFxz(value) { if (activeBackend.rodStructure) activeBackend.rodStructure.fxz = value }
    function rodStructureSetRev(value) { if (activeBackend.rodStructure) activeBackend.rodStructure.rev = value }

    ///////////////////
    // BilayerStructure
    ///////////////////

    // Null while the current shape is not a bilayer
    readonly property real bilayerStructureDmin: activeBackend.bilayerStructure?.dmin ?? 0
    readonly property real bilayerStructureZsep: activeBackend.bilayerStructure?.zsep ?? 0
    readonly property int bilayerStructureNside: activeBackend.bilayerStructure?.nside ?? 0

    function bilayerStructureSetDmin(value) { if (activeBackend.bilayerStructure) activeBackend.bilayerStructure.dmin = value }
    function bilayerStructureSetZsep(value) { if (activeBackend.bilayerStructure) activeBackend.bilayerStructure.zsep = value }
    function bilayerStructureSetNside(value) { if (activeBackend.bilayerStructure) activeBackend.bilayerStructure.nside = value }

    /////////////////////
    // MonolayerStructure
    /////////////////////

    // Null while the current shape is not a monolayer
    readonly property real monolayerStructureDmin: activeBackend.monolayerStructure?.dmin ?? 0
    readonly property real monolayerStructureZsep: activeBackend.monolayerStructure?.zsep ?? 0
    readonly property int monolayerStructureNside: activeBackend.monolayerStructure?.nside ?? 0

    function monolayerStructureSetDmin(value) { if (activeBackend.monolayerStructure) activeBackend.monolayerStructure.dmin = value }
    function monolayerStructureSetZsep(value) { if (activeBackend.monolayerStructure) activeBackend.monolayerStructure.zsep = value }
    function monolayerStructureSetNside(value) { if (activeBackend.monolayerStructure) activeBackend.monolayerStructure.nside = value }

    ///////////////////
    // LatticeStructure
    ///////////////////

    // Null while no lattice repeats the structure
    readonly property real latticeStructureAlpha: activeBackend.latticeStructure?.alpha ?? 0
    readonly property real latticeStructureTheta: activeBackend.latticeStructure?.theta ?? 0
    readonly property int latticeStructureNlatx: activeBackend.latticeStructure?.nlatx ?? 0
    readonly property int latticeStructureNlaty: activeBackend.latticeStructure?.nlaty ?? 0
    readonly property int latticeStructureNlatz: activeBackend.latticeStructure?.nlatz ?? 0
    readonly property real latticeStructureSbuff: activeBackend.latticeStructure?.sbuff ?? 0
    readonly property string latticeStructureLatticeType: activeBackend.latticeStructure?.latticeType ?? ''

    function latticeStructureSetAlpha(value) { if (activeBackend.latticeStructure) activeBackend.latticeStructure.alpha = value }
    function latticeStructureSetTheta(value) { if (activeBackend.latticeStructure) activeBackend.latticeStructure.theta = value }
    function latticeStructureSetNlatx(value) { if (activeBackend.latticeStructure) activeBackend.latticeStructure.nlatx = value }
    function latticeStructureSetNlaty(value) { if (activeBackend.latticeStructure) activeBackend.latticeStructure.nlaty = value }
    function latticeStructureSetNlatz(value) { if (activeBackend.latticeStructure) activeBackend.latticeStructure.nlatz = value }
    function latticeStructureSetSbuff(value) { if (activeBackend.latticeStructure) activeBackend.latticeStructure.sbuff = value }
    function latticeStructureSetLatticeType(value) { if (activeBackend.latticeStructure) activeBackend.latticeStructure.latticeType = value }

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

    // Composition of the current ring, rod, bilayer or monolayer; null
    // in Python for a ball or a vesicle, whose layers and lamellae hold
    // theirs
    readonly property var compositionItems: activeBackend.composition

    // Layers of the current ball, one composition per row; null in
    // Python while the current shape is not a ball
    readonly property var layersItems: activeBackend.layers
    readonly property var layersCompositions: activeBackend.layers?.compositions ?? []

    function layersAdd() { if (activeBackend.layers) activeBackend.layers.add() }
    function layersRemove(index) { if (activeBackend.layers) activeBackend.layers.remove(index) }

    // Lamellae of the current vesicle, one composition per row and
    // leaflet; null in Python while the current shape is not a vesicle.
    // An outer composition is null while its lamella is symmetric
    readonly property var lamellaeItems: activeBackend.lamellae
    readonly property var lamellaeInnerLeafletCompositions: activeBackend.lamellae?.innerLeafletCompositions ?? []
    readonly property var lamellaeOuterLeafletCompositions: activeBackend.lamellae?.outerLeafletCompositions ?? []

    function lamellaeAdd() { if (activeBackend.lamellae) activeBackend.lamellae.add() }
    function lamellaeRemove(index) { if (activeBackend.lamellae) activeBackend.lamellae.remove(index) }

    // Buffer of the current sample model; null in Python while there is
    // none. Solvent '' is no solvent; concentrations are in mM
    readonly property string bufferSolvent: activeBackend.buffer?.solvent ?? ''
    readonly property var bufferComponents: activeBackend.buffer?.components ?? null

    function bufferSetSolvent(value) { if (activeBackend.buffer) activeBackend.buffer.solvent = value }
    function bufferComponentsAppend(name) { if (activeBackend.buffer) activeBackend.buffer.appendComponent(name) }
    function bufferComponentsRemove(index) { if (activeBackend.buffer) activeBackend.buffer.removeComponent(index) }

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

    // Library assets editor (Advanced sidebar): one draft asset the user
    // creates or loads from the library, edits and saves back. The type is
    // editable only in 'create' mode. The page writes the salt's two rows
    // (cation, anion) directly
    readonly property string libraryAssetsMode: activeBackend.libraryAssets.mode
    readonly property var libraryAssetsTypeOptions: activeBackend.libraryAssets.typeOptions
    readonly property string libraryAssetsType: activeBackend.libraryAssets.assetType
    readonly property string libraryAssetsName: activeBackend.libraryAssets.assetName
    readonly property string libraryAssetsCounterIon: activeBackend.libraryAssets.counterIon
    readonly property int libraryAssetsMint: activeBackend.libraryAssets.mint
    readonly property int libraryAssetsMext: activeBackend.libraryAssets.mext
    readonly property var libraryAssetsPaths: activeBackend.libraryAssets.paths
    readonly property var libraryAssetsSaltComposition: activeBackend.libraryAssets.saltComposition
    readonly property bool libraryAssetsSaltReady: activeBackend.libraryAssets.saltReady

    function libraryAssetsCreateNew() { activeBackend.libraryAssets.createNew() }
    function libraryAssetsLoad(type, name) { activeBackend.libraryAssets.load(type, name) }
    function libraryAssetsSetType(value) { activeBackend.libraryAssets.assetType = value }
    function libraryAssetsSetName(value) { activeBackend.libraryAssets.assetName = value }
    function libraryAssetsSetCounterIon(value) { activeBackend.libraryAssets.counterIon = value }
    function libraryAssetsSetMint(value) { activeBackend.libraryAssets.mint = value }
    function libraryAssetsSetMext(value) { activeBackend.libraryAssets.mext = value }
    function libraryAssetsAppendPath(path) { activeBackend.libraryAssets.appendPath(path) }
    function libraryAssetsRemovePath(index) { activeBackend.libraryAssets.removePath(index) }
    function libraryAssetsEditPath(index) { activeBackend.libraryAssets.editPath(index) }
    // Save asks first when the name is taken; OK saves with overwrite
    function libraryAssetsNameTaken() { return activeBackend.libraryAssets.nameTaken() }
    function libraryAssetsSave(overwrite) { activeBackend.libraryAssets.save(overwrite) }
    // Row -1 is the whole asset. Export asks first when the folder is
    // taken; OK exports with overwrite
    function libraryAssetsExportTaken(folder, row) { return activeBackend.libraryAssets.exportTaken(folder, row) }
    function libraryAssetsExportTo(folder, row, overwrite) { activeBackend.libraryAssets.exportTo(folder, row, overwrite) }

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
