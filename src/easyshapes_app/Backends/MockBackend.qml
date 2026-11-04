// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

import Backends.MockQml as MockLogic


QtObject {

    property var project: MockLogic.Project
    property var library: MockLogic.Library
    property var config: MockLogic.Config
    property var error: MockLogic.Error
    property var sampleModel: MockLogic.SampleModel
    property var components: MockLogic.Components
    // Components Files (Advanced sidebar), as Backend.componentsFiles
    property var componentsFiles: MockLogic.ComponentsFiles
    // Library assets editor (Advanced sidebar), as Backend.libraryAssets
    property var libraryAssets: MockLogic.LibraryAssetsEditor
    // SMILES generator (Advanced sidebar) — molecule from a SMILES string.
    property var smilesGenerator: MockLogic.SmilesGenerator
    // The structure viewer's atoms, as Backend.structureView
    property var structureView: MockLogic.StructureView
    // Mock-only: keeps the composition rows in step with the components
    property var fractions: MockLogic.Fractions { source: MockLogic.Components.loaded }
    // The current structure's composition, as Backend.composition
    property var composition: fractions.model
    // The ball's layers, as Backend.layers; always there in the mock
    property var layers: MockLogic.Layers
    // The vesicle's lamellae, as Backend.lamellae; always there in the mock
    property var lamellae: MockLogic.Lamellae
    // Ring structure parameters (single record, edited inline).
    property var ringStructure: MockLogic.RingStructure
    // Ball structure parameters (single record, edited inline).
    property var ballStructure: MockLogic.BallStructure
    // Vesicle structure parameters (single record, edited inline).
    property var vesicleStructure: MockLogic.VesicleStructure
    // Rod structure parameters (single record, edited inline).
    property var rodStructure: MockLogic.RodStructure
    // Bilayer structure parameters (single record, edited inline).
    property var bilayerStructure: MockLogic.BilayerStructure
    // Monolayer structure parameters (single record, edited inline).
    property var monolayerStructure: MockLogic.MonolayerStructure
    // Lattice structure parameters (single record, edited inline).
    property var latticeStructure: MockLogic.LatticeStructure
    // The sample model's buffer, as Backend.buffer
    property var buffer: MockLogic.Buffer
    // The analysis's equilibration: setup, run and files, as
    // Backend.equilibration
    property var equilibration: MockLogic.Equilibration
    // The equilibration's configuration (.mdp files), as
    // Backend.configuration
    property var configuration: MockLogic.AssetFiles {
        type: 'AnalysisConfiguration'
        name: 'CHARMM36'
        filesByName: ({
            'CHARMM36': [0, 1, 2, 3, 4, 5, 6].map(k => ({ path: `configuration/equil${k}.mdp`, size: '2 kB' }))
        })
    }
    // The equilibration's force field (.itp), as Backend.forceField
    property var forceField: MockLogic.AssetFiles {
        type: 'ForceField'
        name: 'CHARMM36'
        filesByName: ({ 'CHARMM36': [{ path: 'forcefield/CHARMM36.itp', size: '1.2 MB' }] })
    }
    property var report: MockLogic.Report

    Component.onCompleted: {
        layers.fractionsSource = MockLogic.Components.loaded
        lamellae.fractionsSource = MockLogic.Components.loaded
        // An editor save writes the library index, as a library save does
        libraryAssets.library = library
        // As Backend wires them: a component Components Files creates
        // joins the components list, and its save writes the library
        // index
        componentsFiles.externalComponentCreated.connect(name => components.append('Component', name))
        componentsFiles.library = library
        components.renamed.connect((name, newName) => componentsFiles.followRename(name, newName))
        // A file added or removed in Components Files: the views read the
        // component's bonds again
        components.componentsFiles = componentsFiles
        componentsFiles.externalFilesChanged.connect(name => components.refreshFiles(name))
        // A sample model save writes the library index, as Backend wires
        // the catalogs
        sampleModel.library = library
        // Assemble without components goes to the error dialog. As
        // Backend wires them: project create and load wait for an
        // assembly, then an equilibration, to stop
        sampleModel.components = components
        sampleModel.error = error
        project.externalReplacing.connect(
            replace => sampleModel.afterAssembly(() => equilibration.afterEquilibration(replace)))
        // Configuration and force field saves write the library index.
        // The stages follow the configuration's .mdp files; Equilibrate
        // without the model's .gro and .top goes to the error dialog
        configuration.library = library
        forceField.library = library
        equilibration.configuration = configuration
        equilibration.sampleModel = sampleModel
        equilibration.error = error
        // As Backend wires them: a component the SMILES generator makes
        // joins the components list, Components Files shows it, and the
        // generator notes it. Python refuses a held name through the
        // error dialog; the mock skips it
        smilesGenerator.components = components
        components.loaded.countChanged.connect(smilesGenerator.refresh)
        components.loaded.dataChanged.connect(smilesGenerator.refresh)
        smilesGenerator.externalComponentCreated.connect((type, name) => {
            if (smilesGenerator.nameTaken) return
            components.append(type, name)
            componentsFiles.selectComponent(name)
            smilesGenerator.generated = true
        })
    }

}
