// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// The sample model's buffer, as Backend.buffer: a solvent name ('' for
// none) and what is dissolved in it.
QtObject {

    property string solvent: ''

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

    // Python loads the salt from the library and refuses a held name
    // through the error dialog; the mock skips it
    function appendComponent(name) {
        for (let i = 0; i < bufferComponentsModel.count; ++i)
            if (bufferComponentsModel.get(i).name === name) return
        bufferComponentsModel.append({ name: name, concentration: 0 })
    }

    // Python reads the salt an export folder holds; the mock adds a
    // stand-in named after the folder
    function importFrom(folder) {
        appendComponent(folder.split(/[\\/]/).pop())
    }

    function removeComponent(index) {
        if (index < 0 || index >= bufferComponentsModel.count) return
        bufferComponentsModel.remove(index)
    }
}
