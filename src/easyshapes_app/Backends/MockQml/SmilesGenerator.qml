// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Mirrors Backend.smilesGenerator: a draft of the arguments of
// shapespyer's Component.from_smiles, and generate(), whose component
// MockBackend adds to the components list and picks in Components
// Files, as Backend does with Python's.
QtObject {
    id: root

    // MockBackend adds the component and picks it, as Backend adds
    // Python's
    signal externalComponentCreated(string type, string name)

    // Mock only: the components list, set by MockBackend; nameTaken
    // reads its names
    property var components: null

    property string name: ''
    // Chemical formula for the file's title line; '' takes the name
    property string formula: ''
    property string smiles: ''

    // Box lengths in nm
    property real boxX: 1.0
    property real boxY: 1.0
    property real boxZ: 1.0

    readonly property var extensions: ['.gro', '.pdb']
    property string extension: '.gro'

    // The library class names a component is built as
    readonly property var componentTypes: ['Lipid', 'Surfactant', 'Component']
    property string componentType: 'Component'

    property bool cis: false
    property bool alignZ: false
    property bool flattenXz: false

    readonly property bool ready: name !== '' && smiles !== ''

    // Whether the sample already holds a component of the draft's
    // name. MockBackend calls refresh() on a change of the components
    // list, as Backend does
    property bool nameTaken: false
    onNameChanged: refresh()

    // Whether MockBackend added the component of the last Generate, as
    // Backend marks Python's; a change to the draft or Generate again
    // drops it
    property bool generated: false
    Component.onCompleted: {
        for (const changed of [root.nameChanged, root.formulaChanged, root.smilesChanged,
                               root.boxXChanged, root.boxYChanged, root.boxZChanged,
                               root.extensionChanged, root.componentTypeChanged,
                               root.cisChanged, root.alignZChanged, root.flattenXzChanged])
            changed.connect(() => root.generated = false)
    }

    function refresh() {
        const loaded = components.loaded
        let taken = false
        for (let i = 0; i < loaded.count; ++i)
            if (loaded.get(i).name === name) taken = true
        nameTaken = taken
    }

    // Python builds the component's structure file from the SMILES
    // string and refuses one it can't build through the error dialog;
    // the mock builds nothing
    function generate() {
        generated = false
        console.debug('SmilesGenerator.generate:', componentType, name, smiles,
                      'box:', [boxX, boxY, boxZ], extension,
                      'cis:', cis, 'alignZ:', alignZ, 'flattenXz:', flattenXz)
        externalComponentCreated(componentType, name)
    }
}
