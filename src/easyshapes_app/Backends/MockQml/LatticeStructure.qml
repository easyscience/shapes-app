// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


QtObject {
    property double alpha: 0.0
    property double theta: 0.0
    property double sbuff: 1.0
    property string latticeType: 'LAT1'
    property int nlatx: 1
    property int nlaty: 1
    property int nlatz: 1

    readonly property var latticeTypes: ['LAT1', 'LAT2', 'LAT3']

    readonly property var substructureTypes: [
        'Ring', 'Ball', 'Vesicle', 'Rod', 'Bilayer', 'Monolayer'
    ]

    // Loaded substructure — JS array of length 0 or 1, mirroring the
    // SampleModel `loaded` shape so EaComponents.ListView can consume it.
    // Element shape: { name, structure_type, description, file_path }.
    property var substructureLoaded: []

    readonly property var availableSubstructures: ListModel {
        ListElement { name: 'CubicSeed';   structure_type: 'Ball';     description: 'Spherical seed for cubic packing' }
        ListElement { name: 'HexRing';     structure_type: 'Ring';     description: 'Ring substructure for hexagonal lattice' }
        ListElement { name: 'BilayerTile'; structure_type: 'Bilayer';  description: 'Planar tile for stacked lattices' }
        ListElement { name: 'RodSeed';     structure_type: 'Rod';      description: 'Rod-shaped seed' }
        ListElement { name: 'VesicleSeed'; structure_type: 'Vesicle';  description: 'Vesicle seed for hollow lattices' }
    }

    function setSubstructureLoaded(item) {
        substructureLoaded = [{
            name: item.name,
            structure_type: item.structure_type,
            description: item.description,
            file_path: item.file_path !== undefined ? item.file_path : ''
        }]
    }

    function updateSubstructureField(field, value) {
        if (substructureLoaded.length === 0) return
        substructureLoaded[0][field] = value
    }

    function clearSubstructure() {
        substructureLoaded = []
    }

    function saveSubstructureToCatalog() {
        if (substructureLoaded.length === 0 || !substructureLoaded[0].name) return
        availableSubstructures.append({
            name: substructureLoaded[0].name,
            structure_type: substructureLoaded[0].structure_type,
            description: substructureLoaded[0].description
        })
    }

    function removeSubstructureFromCatalog(index) {
        if (index < 0 || index >= availableSubstructures.count) return
        availableSubstructures.remove(index)
    }
}
