// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

QtObject {

    property bool created: false

    // Loaded sample model — JS array of length 0 or 1.
    // Capacity is one by convention (single record), but the value is
    // exposed as an array so QML ListView can consume it directly
    // (Qt 6 ListView only supports int / ListModel / QAbstractItemModel / JS array).
    // Element shape: { name, structure_type, description }
    property var loaded: []

    readonly property var structureTypes: [
        'Ring', 'Ball', 'Vesicle', 'Rod', 'Bilayer', 'Monolayer', 'Lattice'
    ]

    // Externally-observed structure type. Decoupled from `loaded` because
    // updateField mutates `loaded[0]` in place (preserving the row delegate
    // and any focused TextInput) and that mutation does NOT fire loadedChanged.
    // The wrapper writes this property whenever structure_type is updated;
    // setLoaded/clear keep it in sync with the active record.
    property string currentStructureType: ''

    // Catalog of saveable/loadable models (asset library).
    // ListModel mirrors the Python QAbstractListModel with roles
    // (name, structure_type, description) so delegate code is identical
    // for both real and mock backends, and ItemSelectionModel works.
    readonly property var availableModels: ListModel {
        ListElement { name: 'Samle1_aluv'; structure_type: 'Vesicle'; description: 'In order to avoid a prolonged pro-inflammatory neutrophil response, signaling downstream of an agonist-activated G protein-coupled receptor (GPCR) has to be rapidly terminated. Among the family of GPCR kinases (GRKs) that regulate receptor phosphorylation and signaling termination, GRK2, which is highly expressed by immune cells, plays an important role.' }
        ListElement { name: 'Sample2_nanodisc'; structure_type: 'Ring'; description: 'The medium chain fatty acid receptor GPR84 as well as formyl peptide receptor 2 (FPR2)' }
        ListElement { name: 'Sample3_cubosome'; structure_type: 'Lattice'; description: 'receptors expressed in neutrophils, play a key role in regulating inflammation. In this study, we investigated the effects of GRK2 inhibitors on neutrophil functions induced by GPR84 and FPR2 agonists.' }
        ListElement { name: 'Sample4'; structure_type: 'Ring'; description: 'GRK2 was shown to be expressed in human neutrophils and analysis of subcellular fractions' }
        ListElement { name: 'Sample5'; structure_type: 'Ball'; description: 'revealed a cytosolic localization. The GRK2 inhibitors enhanced and prolonged neutrophil production ' }
        ListElement { name: 'Sample6'; structure_type: 'Vesicle'; description: 'production of reactive oxygen species (ROS) induced by GPR84- but not FPR2-agonists' }
        ListElement { name: 'Sample7'; structure_type: 'Rod'; description: 'suggesting a receptor selective function of GRK2. This suggestion was supported by β-arrestin recruitment data. The ROS production induced by a non β-arrestin recruiting GPR84' }
        ListElement { name: 'Sample8'; structure_type: 'Bilayer'; description: 'This suggestion was supported by β-arrestin recruitment data. The ROS production induced by a non β-arrestin recruiting GPR84 agonist was not affected by the GRK2 inhibitor.' }
        ListElement { name: 'Sample9'; structure_type: 'Monolayer'; description: 'Termination of this β-arrestin independent response relied, similar to the response induced by FPR2 agonists, primarily on the actin cytoskeleton.' }
        ListElement { name: 'Samplewithareallylongname'; structure_type: 'Lattice'; description: 'In summary, we show that GPR84 utilizes GRK2 in concert with β-arrestin and actin cytoskeleton dependent processes to fine-tune the activity of the ROS generating NADPH-oxidase in neutrophils.' }
    }

    function setLoaded(model) {
        console.debug(`Loading sample model '${model.name}'`)
        loaded = [{
            name: model.name,
            structure_type: model.structure_type,
            description: model.description
        }]
        currentStructureType = model.structure_type
        created = true
    }

    function updateField(field, value) {
        if (loaded.length === 0) return
        loaded[0][field] = value
    }

    function clear() {
        loaded = []
        currentStructureType = ''
        created = false
    }

    function saveToCatalog() {
        if (loaded.length === 0 || !loaded[0].name) return
        availableModels.append({
            name: loaded[0].name,
            structure_type: loaded[0].structure_type,
            description: loaded[0].description
        })
        console.debug(`Saved sample model '${loaded[0].name}' to catalog`)
    }

    function removeFromCatalog(index) {
        if (index < 0 || index >= availableModels.count) return
        availableModels.remove(index)
    }

}
