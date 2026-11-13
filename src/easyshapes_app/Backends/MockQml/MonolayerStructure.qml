// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


QtObject {
    property double zsep: 0.0
    property int nside: 1
    property double dmin: 0.5
    // As the library's, with the mock's 2 nm bone, as Layers' thickness
    readonly property real width: nside * dmin
    readonly property real thickness: 2.0
}
