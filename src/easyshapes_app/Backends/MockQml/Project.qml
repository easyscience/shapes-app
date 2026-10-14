// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick
import QtCore

// Mirrors shapes.project.Project. `created` is GUI state.
QtObject {

    property bool created: false

    property string name: ''
    property string description: ''
    readonly property string path: _path
    // Python: project.path.parent.as_uri(). The mock opens the home folder.
    readonly property string pathParentUrl: _path ? StandardPaths.writableLocation(StandardPaths.HomeLocation).toString() : ''
    readonly property string modified: _modified

    property string _path: ''
    property string _modified: ''

    // A new project in `newPath`, or in the library default folder Projects/<name>-<uid>
    // when it is empty.
    function create(newName, newDescription, newPath) {
        name = newName
        description = newDescription
        _path = newPath ? newPath : `~/Projects/${newName}-0001`
        _modified = ''
        created = true
    }

    function save() {
        _modified = new Date().toLocaleString(Qt.locale(), 'dd MMM yyyy HH:mm')
    }

    function load(folder) {
        name = folder.split(/[\\/]/).pop()
        description = 'Loaded in the mock'
        _path = folder
        _modified = '01 Oct 2026 12:00'
        created = true
    }

}
