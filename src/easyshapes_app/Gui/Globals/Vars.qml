// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick
import QtCore

import EasyApplication.Gui.Globals as EaGlobals


// GUI state shared by files that can't reach each other (a sidebar
// group and a main-area tab), and kept while a page is built anew;
// some of it also between launches.
QtObject {
    id: vars

    // Structure viewer: the 3D view's background, by the picker's
    // index (Theme, Black, White, Grey 50%)
    property int structureBackground: 0
    // Structure viewer: the slab follows the slider while it is
    // dragged, not on release only
    property bool structureContinuousUpdate: false
    // Structure viewer: the atoms stay loaded while the tab is hidden;
    // passed on to the backend
    property bool structureKeepLoaded: false
    // Structure viewer: bonds drawn between the atoms; passed on to the
    // backend
    property bool structureShowBonds: false

    onStructureKeepLoadedChanged: BackendWrapper.structureViewSetKeepLoaded(structureKeepLoaded)
    onStructureShowBondsChanged: BackendWrapper.structureViewSetShowBonds(structureShowBonds)

    // The checkboxes are kept between launches, in the app's settings
    // file, as the Shape view's are
    property Settings _settings: Settings {
        location: EaGlobals.Vars.settingsFile
        category: 'SampleModel.StructureViewer'
        property alias continuousUpdate: vars.structureContinuousUpdate
        property alias keepLoaded: vars.structureKeepLoaded
        property alias showBonds: vars.structureShowBonds
    }
}
