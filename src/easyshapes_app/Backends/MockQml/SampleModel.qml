// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

QtObject {

    // The Model Definition row: name, shape, and whether a lattice
    // repeats the structure. Same names as the Python part.
    property string name: ''
    readonly property var shapes: ['Ring', 'Ball', 'Vesicle', 'Rod', 'Bilayer', 'Monolayer']
    property string shape: 'Ring'
    property bool lattice: false

    // The mock always holds a model, so there is nothing to create
    function create() {}

    // Catalog of saved models for the Load model popup. Stays mock until
    // the library catalogs move to Python (step 5).
    readonly property var availableModels: ListModel {
        ListElement { name: 'Samle1_aluv'; structure_type: 'Vesicle'; type: 'Discrete'; description: 'In order to avoid a prolonged pro-inflammatory neutrophil response, signaling downstream of an agonist-activated G protein-coupled receptor (GPCR) has to be rapidly terminated. Among the family of GPCR kinases (GRKs) that regulate receptor phosphorylation and signaling termination, GRK2, which is highly expressed by immune cells, plays an important role.' }
        ListElement { name: 'Sample2_nanodisc'; structure_type: 'Ring'; type: 'Discrete'; description: 'The medium chain fatty acid receptor GPR84 as well as formyl peptide receptor 2 (FPR2)' }
        ListElement { name: 'Sample3_cubosome'; structure_type: 'Ball'; type: 'Lattice'; description: 'receptors expressed in neutrophils, play a key role in regulating inflammation. In this study, we investigated the effects of GRK2 inhibitors on neutrophil functions induced by GPR84 and FPR2 agonists.' }
        ListElement { name: 'Sample4'; structure_type: 'Ring'; type: 'Discrete'; description: 'GRK2 was shown to be expressed in human neutrophils and analysis of subcellular fractions' }
        ListElement { name: 'Sample5'; structure_type: 'Ball'; type: 'Discrete'; description: 'revealed a cytosolic localization. The GRK2 inhibitors enhanced and prolonged neutrophil production ' }
        ListElement { name: 'Sample6'; structure_type: 'Vesicle'; type: 'Discrete'; description: 'production of reactive oxygen species (ROS) induced by GPR84- but not FPR2-agonists' }
        ListElement { name: 'Sample7'; structure_type: 'Rod'; type: 'Discrete'; description: 'suggesting a receptor selective function of GRK2. This suggestion was supported by β-arrestin recruitment data. The ROS production induced by a non β-arrestin recruiting GPR84' }
        ListElement { name: 'Sample8'; structure_type: 'Bilayer'; type: 'Discrete'; description: 'This suggestion was supported by β-arrestin recruitment data. The ROS production induced by a non β-arrestin recruiting GPR84 agonist was not affected by the GRK2 inhibitor.' }
        ListElement { name: 'Sample9'; structure_type: 'Monolayer'; type: 'Discrete'; description: 'Termination of this β-arrestin independent response relied, similar to the response induced by FPR2 agonists, primarily on the actin cytoskeleton.' }
        ListElement { name: 'Samplewithareallylongname'; structure_type: 'Rod'; type: 'Lattice'; description: 'In summary, we show that GPR84 utilizes GRK2 in concert with β-arrestin and actin cytoskeleton dependent processes to fine-tune the activity of the ROS generating NADPH-oxidase in neutrophils.' }
    }

    function setLoaded(model) {
        console.debug(`Loading sample model '${model.name}'`)
        name = model.name
        shape = model.structure_type
        lattice = model.type === 'Lattice'
    }

    function removeFromCatalog(index) {
        if (index < 0 || index >= availableModels.count) return
        availableModels.remove(index)
    }

}
