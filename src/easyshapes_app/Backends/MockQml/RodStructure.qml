// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


QtObject {
    property double dmin: 0.5
    property double rmin: 1.2
    property int turns: 1
    property bool fxz: false
    property bool rev: false
    // As the library's, with the mock's 2 nm bone, as Layers' thickness;
    // the length runs from cap tip to cap tip
    readonly property real outerRadius: rmin + 2.0
    readonly property real length: (Math.max(turns, 1) - 1) * dmin + 2 * outerRadius
}
