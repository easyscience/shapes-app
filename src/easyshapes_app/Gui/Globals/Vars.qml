// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick
import QtCore

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle


// GUI state shared by files that can't reach each other (a sidebar
// group and a main-area tab), and kept while a page is built anew;
// some of it also between launches.
QtObject {
    id: vars

    // Structure viewer: the 3D view's background, by the picker's
    // index (Theme, Black, White, Grey 50%)
    property int structureBackground: 0
    // Structure viewer: the light on the atoms, by the picker's index
    // (Default, Volumetric, Vol-tint, Hygge, Outline)
    property int structureLighting: 0
    // Structure viewer: the slab follows the slider while it is
    // dragged, not on release only
    property bool structureContinuousUpdate: false
    // Structure viewer: the atoms stay loaded while the tab is hidden;
    // passed on to the backend
    property bool structureKeepLoaded: false
    // Structure viewer: bonds drawn between the atoms; passed on to the
    // backend
    property bool structureShowBonds: false

    // Scattering: each curve's colour, by its row in Scattering view, for
    // the list's swatches and the chart's lines. A categorical palette
    // checked for colour-blind separation, with its own steps for the dark
    // theme. Rows past the 8th draw in grey: a 9th hue would not stay
    // apart from the others
    readonly property var scatteringColors: EaStyle.Colors.isDarkPalette
        ? ['#3987e5', '#d95926', '#199e70', '#c98500', '#d55181', '#008300', '#9085e9', '#e66767']
        : ['#2a78d6', '#eb6834', '#1baf7a', '#eda100', '#e87ba4', '#008300', '#6250d6', '#e34948']
    function scatteringColor(row) {
        return row < scatteringColors.length ? scatteringColors[row] : '#898781'
    }
    // Scattering view: each further shown curve is drawn this many decades
    // lower, on the chart only. Off at first, not kept between launches
    property bool scatteringStaggered: false
    property real scatteringStaggerDecades: 1.0
    // Scattering view's Export as PNG: the Scattering tab saves its chart
    // and legend to path, once the page has switched to it
    signal scatteringPngRequested(string path)

    // Both viewers, the Sample model's and the Analysis page's, take them
    onStructureKeepLoadedChanged: {
        BackendWrapper.structureViewSetKeepLoaded(structureKeepLoaded)
        BackendWrapper.stageViewSetKeepLoaded(structureKeepLoaded)
    }
    onStructureShowBondsChanged: {
        BackendWrapper.structureViewSetShowBonds(structureShowBonds)
        BackendWrapper.stageViewSetShowBonds(structureShowBonds)
    }

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
