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
    // Lattice structure parameters (single record, edited inline) plus a
    // single-record substructure with its own asset library.
    property var latticeStructure: MockLogic.LatticeStructure
    property var analysis: MockLogic.Analysis
    property var status: MockLogic.Status
    property var report: MockLogic.Report

    Component.onCompleted: {
        layers.fractionsSource = MockLogic.Components.loaded
        lamellae.fractionsSource = MockLogic.Components.loaded
    }

}
