// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import Gui.Globals as Globals

import "../../../../SampleModel/Sidebar/Advanced/Groups" as SampleModelGroups


// The Analysis Structure tab's controls: the Sample model page's group,
// on this viewer's slab. Background, lighting and the checkboxes are
// shared with the Sample model's viewer
SampleModelGroups.StructureViewer {
    instancing: Globals.BackendWrapper.stageViewInstancing
}
