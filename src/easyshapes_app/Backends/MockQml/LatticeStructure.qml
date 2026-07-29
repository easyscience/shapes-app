// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


QtObject {
    property double alpha: 0.0
    property double theta: 0.0
    property double sbuff: 1.0
    property string latticeType: 'LCUB'
    property int nlatx: 1
    property int nlaty: 1
    property int nlatz: 1

    readonly property var latticeTypes: ['LCUB', 'LBCC', 'LFCC', 'LHCP']
}
