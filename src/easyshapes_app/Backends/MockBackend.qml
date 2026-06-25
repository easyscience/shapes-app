// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

import Backends.MockQml as MockLogic


QtObject {

    property var project: MockLogic.Project
    property var sampleModel: MockLogic.SampleModel
    property var components: MockLogic.Components
    // Advanced sidebar (Sample Model page) domain singletons.
    property var componentsFiles: MockLogic.ComponentsFiles
    property var structureFiles: MockLogic.StructureFiles
    // Library Assets editor (Advanced sidebar) — draft asset create/load/save.
    property var libraryAssets: MockLogic.LibraryAssetsEditor
    // SMILES generator (Advanced sidebar) — molecule from a SMILES string.
    property var smilesGenerator: MockLogic.SmilesGenerator
    // Default fractions set tied to the shared component list.
    // Used as the fallback for the Fractions sidebar component when no
    // per-row override is set.
    property var fractions: MockLogic.Fractions { source: MockLogic.Components.loaded }
    // Layers owns one Fractions instance per layer (per-row state) and
    // shares the same component source so names stay in sync with the
    // global components list.
    property var layers: MockLogic.Layers
    // Lamellae owns distinct inner/outer Fractions instances per lamella.
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
    // Buffer group: solvent selection + buffer components (salts, buffering
    // agents). Ions singleton stays (used by the Components C-ion picker).
    property var buffer: MockLogic.Buffer
    property var ions: MockLogic.Ions
    property var analysis: MockLogic.Analysis
    // Analysis page — equilibration configuration (config files + force
    // field + step range), driving the Equilibrate action.
    property var analysisConfig: MockLogic.AnalysisConfig
    property var status: MockLogic.Status
    property var report: MockLogic.Report

    Component.onCompleted: {
        layers.fractionsSource = MockLogic.Components.loaded
        lamellae.fractionsSource = MockLogic.Components.loaded
    }

}
