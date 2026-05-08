// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


QtObject {

    readonly property var solutionTypes: ['other', 'water_3site', 'water_4site', 'water_5site', 'protic_polar', 'halogenated', 'denaturant']

    property var loaded: [{
        name: 'TIP3P',
        solvent_type: 'water_3site',
        description: '3-site model standard with AMBER and CHARMM. Uses spc216.gro coordinates.',
        file_path: ''
    }]

    readonly property var available: ListModel {
        id: solventModel

        ListElement {
            name: "SPC"
            solvent_type: "water_3site"
            description: "Simple Point Charge water. Use spc216.gro with -ci. Standard for GROMOS force fields."
        }
        ListElement {
            name: "SPC/E"
            solvent_type: "water_3site"
            description: "Extended SPC with self-polarization correction. Uses spc216.gro coordinates."
        }
        ListElement {
            name: "TIP3P"
            solvent_type: "water_3site"
            description: "3-site model standard with AMBER and CHARMM. Uses spc216.gro coordinates."
        }
        ListElement {
            name: "TIP4P"
            solvent_type: "water_4site"
            description: "4-site water with virtual site. Use tip4p.gro."
        }
        ListElement {
            name: "TIP4P-Ew"
            solvent_type: "water_4site"
            description: "TIP4P optimized for Ewald summation. Available in AMBER ports."
        }
        ListElement {
            name: "TIP4P/2005"
            solvent_type: "water_4site"
            description: "Reparameterized TIP4P with excellent bulk properties. Shipped with recent GROMACS."
        }
        ListElement {
            name: "TIP5P"
            solvent_type: "water_5site"
            description: "5-site model with lone-pair virtual sites. Use tip5p.gro."
        }
        ListElement {
            name: "TIP5PE"
            solvent_type: "water_5site"
            description: "TIP5P variant for Ewald electrostatics."
        }

        ListElement {
            name: "Methanol"
            solvent_type: "protic_polar"
            description: "CH3OH. Equilibrated box methanol.gro shipped with GROMACS (OPLS-AA)."
        }
        ListElement {
            name: "1,2-Dichloroethane"
            solvent_type: "halogenated"
            description: "ClCH2CH2Ch. Equilibrated box ClCH2CH2Ch.gro included for OPLS-AA."
        }

        ListElement {
            name: "Urea"
            solvent_type: "denaturant"
            description: "Equilibrated urea box urea.gro shipped with GROMACS for cosolvent simulations."
        }
    }

    function setLoaded(item) {
        loaded = [{
            name: item.name,
            solvent_type: item.solvent_type,
            description: item.description,
            file_path: item.file_path !== undefined ? item.file_path : ''
        }]
    }

    // Mutate loaded[0] in place — same trick as SampleModel.updateField — so
    // the ListView delegate and any focused TextInput survive the edit.
    function updateField(field, value) {
        if (loaded.length === 0) return
        loaded[0][field] = value
    }

    function clear() {
        loaded = []
    }

    function saveToCatalog() {
        if (loaded.length === 0 || !loaded[0].name) return
        available.append({
            name: loaded[0].name,
            solvent_type: loaded[0].solvent_type,
            description: loaded[0].description
        })
    }

    function removeFromCatalog(index) {
        if (index < 0 || index >= available.count) return
        available.remove(index)
    }
}
