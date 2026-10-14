// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

// Mirrors the Python error part. The mock never raises: type a message
// here to see the dialog in Qt Creator.
QtObject {

    property string message: ''

}
