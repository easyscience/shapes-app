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
    readonly property var libraryAvailableAnalysisConfigurations: activeBackend.library.availableAnalysisConfigurations
    readonly property var libraryAvailableForceFields: activeBackend.library.availableForceFields

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
    // The model's own files: Assemble outputs and files added by hand
    readonly property var sampleModelFiles: activeBackend.sampleModel.files
    // An assembly runs; Cancel may stop it only a while after it starts
    readonly property bool sampleModelFilesLocked: activeBackend.sampleModel.filesLocked
    readonly property bool sampleModelCancelable: activeBackend.sampleModel.cancelable

    function sampleModelSetName(value) { activeBackend.sampleModel.name = value }
    function sampleModelSetShape(value) { activeBackend.sampleModel.shape = value }
    function sampleModelSetLattice(value) { activeBackend.sampleModel.lattice = value }
    function sampleModelCreate() { activeBackend.sampleModel.create() }
    // A failed check before the start and a failed run go to the error
    // dialog; a cancel shows nothing
    function sampleModelAssemble() { activeBackend.sampleModel.assemble() }
    function sampleModelCancel() { activeBackend.sampleModel.cancel() }
    // A model from the library by name, or from an export folder; it
    // replaces the current one, once an assembly is cancelled
    function sampleModelLoad(name) { activeBackend.sampleModel.load(name) }
    function sampleModelImportFrom(folder) { activeBackend.sampleModel.importFrom(folder) }
    function sampleModelAppendFile(path) { activeBackend.sampleModel.appendFile(path) }
    function sampleModelRemoveFile(index) { activeBackend.sampleModel.removeFile(index) }
    function sampleModelEditFile(index) { activeBackend.sampleModel.editFile(index) }
    // Save asks first when the library holds the name; OK saves with
    // overwrite
    function sampleModelNameTaken() { return activeBackend.sampleModel.nameTaken() }
    function sampleModelSave(overwrite) { activeBackend.sampleModel.save(overwrite) }
    // Export asks first when the folder is taken; OK exports with
    // overwrite
    function sampleModelExportTaken(folder) { return activeBackend.sampleModel.exportTaken(folder) }
    function sampleModelExportTo(folder, overwrite) { activeBackend.sampleModel.exportTo(folder, overwrite) }

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

    // type: the library class name, Lipid, Surfactant or Component
    function componentsAppend(type, name) { activeBackend.components.append(type, name) }
    function componentsImportFrom(folder) { activeBackend.components.importFrom(folder) }
    // With the name cell's checks; returns why a name was refused, ''
    // when renamed. The caller shows it: the components list keeps no
    // record of it
    function componentsRename(name, newName) { return activeBackend.components.rename(name, newName) }
    function componentsRemove(index) { activeBackend.components.remove(index) }

    // Atomistic structure of a loaded component, for the Components viewer:
    // parsed [{element, x, y, z}] (Å) fed to the Qt Quick 3D viewer. The mock
    // returns one shared template molecule for every component.
    function componentStructureAtoms(index) { return activeBackend.components.structureAtoms(index) }
    // Mint to Mext distance of a loaded component, in nm; 0 when unset
    function componentBoneLength(index) { return activeBackend.components.boneLength(index) }
    // Bonds of a loaded component from its topology file: pairs of atom
    // indices into componentStructureAtoms; empty without one
    function componentStructureBonds(index) { return activeBackend.components.structureBonds(index) }

    // Composition of the current ring, rod, bilayer or monolayer; null
    // in Python for a ball or a vesicle, whose layers and lamellae hold
    // theirs. ?? null here and below: Python's None reaches QML as
    // undefined, which a list's selection model refuses
    readonly property var compositionItems: activeBackend.composition ?? null

    // Layers of the current ball, one composition per row; null in
    // Python while the current shape is not a ball
    readonly property var layersItems: activeBackend.layers ?? null
    readonly property var layersCompositions: activeBackend.layers?.compositions ?? []

    function layersAdd() { if (activeBackend.layers) activeBackend.layers.add() }
    function layersRemove(index) { if (activeBackend.layers) activeBackend.layers.remove(index) }

    // Lamellae of the current vesicle, one composition per row and
    // leaflet; null in Python while the current shape is not a vesicle.
    // An outer composition is null while its lamella is symmetric
    readonly property var lamellaeItems: activeBackend.lamellae ?? null
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
    function bufferImportFrom(folder) { if (activeBackend.buffer) activeBackend.buffer.importFrom(folder) }

    // Components Files (Advanced sidebar): the files of one component of
    // the sample, picked by name ('' for none). create() adds an empty
    // component, named by its uid, and picks it; rename it through
    // componentsRename
    readonly property var componentsFilesFiles: activeBackend.componentsFiles.files
    readonly property string componentsFilesSelectedComponent: activeBackend.componentsFiles.selectedComponent

    function componentsFilesSelect(name) { activeBackend.componentsFiles.selectComponent(name) }
    function componentsFilesCreate() { activeBackend.componentsFiles.create() }
    function componentsFilesAppend(path) { activeBackend.componentsFiles.appendFile(path) }
    function componentsFilesRemove(index) { activeBackend.componentsFiles.removeFile(index) }
    function componentsFilesEditFile(index) { activeBackend.componentsFiles.editFile(index) }
    // Save asks first when the library holds the name; OK saves with
    // overwrite
    function componentsFilesNameTaken() { return activeBackend.componentsFiles.nameTaken() }
    function componentsFilesSave(overwrite) { activeBackend.componentsFiles.save(overwrite) }
    // Row -1 is the whole component. Export asks first when the folder
    // is taken; OK exports with overwrite
    function componentsFilesExportTaken(folder, row) { return activeBackend.componentsFiles.exportTaken(folder, row) }
    function componentsFilesExportTo(folder, row, overwrite) { activeBackend.componentsFiles.exportTo(folder, row, overwrite) }

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

    // SMILES generator (Advanced sidebar): a draft of the arguments of
    // shapespyer's Component.from_smiles. Generate adds the component
    // to the sample and picks it in Components Files. smilesString is
    // the SMILES string
    readonly property string smilesName: activeBackend.smilesGenerator.name
    readonly property string smilesFormula: activeBackend.smilesGenerator.formula
    readonly property string smilesString: activeBackend.smilesGenerator.smiles
    readonly property real smilesBoxX: activeBackend.smilesGenerator.boxX
    readonly property real smilesBoxY: activeBackend.smilesGenerator.boxY
    readonly property real smilesBoxZ: activeBackend.smilesGenerator.boxZ
    readonly property var smilesExtensions: activeBackend.smilesGenerator.extensions
    readonly property string smilesExtension: activeBackend.smilesGenerator.extension
    readonly property var smilesComponentTypes: activeBackend.smilesGenerator.componentTypes
    readonly property string smilesComponentType: activeBackend.smilesGenerator.componentType
    readonly property bool smilesCis: activeBackend.smilesGenerator.cis
    readonly property bool smilesAlignZ: activeBackend.smilesGenerator.alignZ
    readonly property bool smilesFlattenXz: activeBackend.smilesGenerator.flattenXz
    readonly property bool smilesReady: activeBackend.smilesGenerator.ready
    // The sample already holds a component of this name; Generate is
    // then refused in the error dialog
    readonly property bool smilesNameTaken: activeBackend.smilesGenerator.nameTaken
    // The last Generate added the component of this name: the name is
    // its own, not a clash
    readonly property bool smilesGenerated: activeBackend.smilesGenerator.generated

    function smilesSetName(value) { activeBackend.smilesGenerator.name = value }
    function smilesSetFormula(value) { activeBackend.smilesGenerator.formula = value }
    function smilesSetString(value) { activeBackend.smilesGenerator.smiles = value }
    function smilesSetBoxX(value) { activeBackend.smilesGenerator.boxX = value }
    function smilesSetBoxY(value) { activeBackend.smilesGenerator.boxY = value }
    function smilesSetBoxZ(value) { activeBackend.smilesGenerator.boxZ = value }
    function smilesSetExtension(value) { activeBackend.smilesGenerator.extension = value }
    function smilesSetComponentType(value) { activeBackend.smilesGenerator.componentType = value }
    function smilesSetCis(value) { activeBackend.smilesGenerator.cis = value }
    function smilesSetAlignZ(value) { activeBackend.smilesGenerator.alignZ = value }
    function smilesSetFlattenXz(value) { activeBackend.smilesGenerator.flattenXz = value }
    function smilesGenerate() { activeBackend.smilesGenerator.generate() }

    // Structure viewer (Sample model main area): the sample model's
    // atoms as an instance table, read while the tab is shown. The
    // instancing holds atomCount, radius (Å), the slab: slabAxis
    // (0, 1, 2 = X, Y, Z) and slabFraction (0..1), the atoms in it
    // (slabCount, all sent to the GPU: shownCount), the GPU rows they
    // and their bond halves take (slabRows, 80 bytes each), and the
    // slab's bond halves as a table of their own (bondInstancing).
    readonly property var structureViewInstancing: activeBackend.structureView.instancing
    readonly property bool structureViewHasStructure: activeBackend.structureView.hasStructure
    readonly property bool structureViewLoading: activeBackend.structureView.loading
    readonly property string structureViewError: activeBackend.structureView.error

    function structureViewSetActive(active) { activeBackend.structureView.setActive(active) }
    // Off: hiding the tab drops the atoms and resets the slab. Set by
    // Globals.Vars, which keeps it between launches
    function structureViewSetKeepLoaded(value) { activeBackend.structureView.keepLoaded = value }
    // Reads the file again with or without the components' bonds. Set
    // by Globals.Vars, which keeps it between launches
    function structureViewSetShowBonds(value) { activeBackend.structureView.showBonds = value }

    ////////////////
    // Analysis page
    ////////////////

    ////////////////
    // Equilibration
    ////////////////

    // The setup. Stage k runs the configuration's equil<k>.mdp. Threads
    // '' is Auto: mdrun picks
    readonly property int equilibrationFirstStage: activeBackend.equilibration.firstStage
    readonly property int equilibrationLastStage: activeBackend.equilibration.lastStage
    readonly property string equilibrationThreads: activeBackend.equilibration.threads
    readonly property bool equilibrationRestrainToBoxCenter: activeBackend.equilibration.restrainToBoxCenter
    // Stages the configuration holds; stages a run can start from: eq0,
    // and each after a finished one
    readonly property var equilibrationAvailableStages: activeBackend.equilibration.availableStages
    readonly property var equilibrationStartableStages: activeBackend.equilibration.startableStages
    // A run goes on; Cancel may stop it only a while after it starts.
    // stage is the one it is on, -1 without a run; log is its
    // equilibration.log
    readonly property bool equilibrationFilesLocked: activeBackend.equilibration.filesLocked
    readonly property bool equilibrationCancelable: activeBackend.equilibration.cancelable
    readonly property int equilibrationStage: activeBackend.equilibration.stage
    readonly property string equilibrationLog: activeBackend.equilibration.log
    // Whose files show: the equilibration, then each stage run so far
    // (roles: name, status), and the picked one's files (roles: path,
    // size, editable)
    readonly property var equilibrationEntries: activeBackend.equilibration.entries
    readonly property int equilibrationSelectedEntry: activeBackend.equilibration.selectedEntry
    readonly property var equilibrationFiles: activeBackend.equilibration.files

    function equilibrationSetFirstStage(value) { activeBackend.equilibration.firstStage = value }
    function equilibrationSetLastStage(value) { activeBackend.equilibration.lastStage = value }
    function equilibrationSetThreads(value) { activeBackend.equilibration.threads = value }
    function equilibrationSetRestrainToBoxCenter(value) { activeBackend.equilibration.restrainToBoxCenter = value }
    // A failed check before the start and a failed run go to the error
    // dialog; a cancel shows nothing
    function equilibrationRun() { activeBackend.equilibration.run() }
    function equilibrationCancel() { activeBackend.equilibration.cancel() }
    function equilibrationSelectEntry(index) { activeBackend.equilibration.selectEntry(index) }
    function equilibrationEditFile(index) { activeBackend.equilibration.editFile(index) }
    // Row -1 is the whole picked entry. Export asks first when the folder
    // is taken; OK exports with overwrite
    function equilibrationExportTaken(folder, row) { return activeBackend.equilibration.exportTaken(folder, row) }
    function equilibrationExportTo(folder, row, overwrite) { activeBackend.equilibration.exportTo(folder, row, overwrite) }
    function equilibrationOpenFolder() { activeBackend.equilibration.openFolder() }

    ////////////////
    // Configuration
    ////////////////

    // The equilibration's .mdp files
    readonly property string configurationName: activeBackend.configuration.name
    readonly property var configurationFiles: activeBackend.configuration.files

    function configurationSetName(value) { activeBackend.configuration.name = value }
    // Replaces the configuration with the library's of that name
    function configurationLoad(name) { activeBackend.configuration.load(name) }
    function configurationAppendFile(path) { activeBackend.configuration.appendFile(path) }
    function configurationRemoveFile(index) { activeBackend.configuration.removeFile(index) }
    function configurationEditFile(index) { activeBackend.configuration.editFile(index) }
    // Save asks first when the library holds the name; OK saves with
    // overwrite
    function configurationNameTaken() { return activeBackend.configuration.nameTaken() }
    function configurationSave(overwrite) { activeBackend.configuration.save(overwrite) }
    // Export asks first when the folder is taken; OK exports with
    // overwrite
    function configurationExportTaken(folder) { return activeBackend.configuration.exportTaken(folder) }
    function configurationExportTo(folder, overwrite) { activeBackend.configuration.exportTo(folder, overwrite) }

    /////////////
    // ForceField
    /////////////

    // The equilibration's force field (.itp)
    readonly property string forceFieldName: activeBackend.forceField.name
    readonly property var forceFieldFiles: activeBackend.forceField.files

    function forceFieldSetName(value) { activeBackend.forceField.name = value }
    // Replaces the force field with the library's of that name
    function forceFieldLoad(name) { activeBackend.forceField.load(name) }
    function forceFieldAppendFile(path) { activeBackend.forceField.appendFile(path) }
    function forceFieldRemoveFile(index) { activeBackend.forceField.removeFile(index) }
    function forceFieldEditFile(index) { activeBackend.forceField.editFile(index) }
    // Save asks first when the library holds the name; OK saves with
    // overwrite
    function forceFieldNameTaken() { return activeBackend.forceField.nameTaken() }
    function forceFieldSave(overwrite) { activeBackend.forceField.save(overwrite) }
    // Export asks first when the folder is taken; OK exports with
    // overwrite
    function forceFieldExportTaken(folder) { return activeBackend.forceField.exportTaken(folder) }
    function forceFieldExportTo(folder, overwrite) { activeBackend.forceField.exportTo(folder, overwrite) }

    ////////////
    // StageView
    ////////////

    // The Analysis page's structure viewer: the initial structure or a
    // finished stage's final .gro, read while its tab is shown. The
    // instancing is as the Structure viewer's. stages lists Initial (the
    // equilibration's copy of the model, status '') and the finished
    // stages (roles: name, status); selectedStage is the row shown, -1
    // with none
    readonly property var stageViewInstancing: activeBackend.stageView.instancing
    readonly property bool stageViewHasStructure: activeBackend.stageView.hasStructure
    readonly property bool stageViewLoading: activeBackend.stageView.loading
    readonly property string stageViewError: activeBackend.stageView.error
    readonly property var stageViewStages: activeBackend.stageView.stages
    readonly property int stageViewSelectedStage: activeBackend.stageView.selectedStage

    function stageViewSetActive(active) { activeBackend.stageView.setActive(active) }
    // A pick stays until its stage leaves the list; until then the
    // newest finished stage shows
    function stageViewSelectStage(index) { activeBackend.stageView.selectStage(index) }
    // Set by Globals.Vars, which keeps them between launches, as for the
    // Structure viewer
    function stageViewSetKeepLoaded(value) { activeBackend.stageView.keepLoaded = value }
    function stageViewSetShowBonds(value) { activeBackend.stageView.showBonds = value }

    ///////////////
    // Summary page
    ///////////////

    readonly property string reportAsHtml: activeBackend.report.asHtml

    property bool reportCreated: activeBackend.report.created
    onReportCreatedChanged: activeBackend.report.created = reportCreated
}
