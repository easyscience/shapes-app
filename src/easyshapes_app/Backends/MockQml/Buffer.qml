// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


QtObject {

    // Solvent — a single selected value. '(None)' means no solvent.
    readonly property var solventOptions: ['(None)', 'TIP3', 'Ethanol']
    property string solvent: '(None)'

    // Loaded buffer components. ListModel so the ListView's ItemSelectionModel
    // can drive multi-selection and role-based delegate bindings.
    // Roles: name, concentration (in mM). dynamicRoles so an edited
    // concentration keeps fractional values — a statically-typed role would
    // inherit int from the first (whole-number) catalog value and truncate
    // floats.
    readonly property var components: ListModel {
        id: bufferComponentsModel
        dynamicRoles: true
    }

    // Catalog of loadable buffer components (salts, buffering agents). Identity
    // only — concentration is the user's per-experiment choice, set after load.
    // Roles: name, description.
    readonly property var available: ListModel {
        ListElement { name: 'NaCl';      description: 'Sodium chloride — physiological background salt' }
        ListElement { name: 'KCl';       description: 'Potassium chloride' }
        ListElement { name: 'Tris';      description: 'Tris(hydroxymethyl)aminomethane buffer' }
        ListElement { name: 'HEPES';     description: 'Zwitterionic biological buffer (pH 6.8–8.2)' }
        ListElement { name: 'MgCl₂';     description: 'Magnesium chloride' }
        ListElement { name: 'CaCl₂';     description: 'Calcium chloride' }
        ListElement { name: 'Phosphate'; description: 'Sodium phosphate buffer (PBS)' }
        ListElement { name: 'EDTA';      description: 'Chelating agent' }
    }

    function appendComponent(item) {
        bufferComponentsModel.append({
            name: item.name,
            concentration: 0
        })
    }

    function removeComponent(index) {
        if (index < 0 || index >= bufferComponentsModel.count) return
        bufferComponentsModel.remove(index)
    }
}
