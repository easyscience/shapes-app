// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtGraphs

import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Elements as EaElements

import Gui.Globals as Globals


GraphsView {
    anchors.fill: parent

    marginTop: EaStyle.Sizes.fontPixelSize * 2
    marginBottom: EaStyle.Sizes.fontPixelSize * 2
    marginLeft: EaStyle.Sizes.fontPixelSize
    marginRight: EaStyle.Sizes.fontPixelSize * 2

    zoomAreaEnabled: true

    // theme
    theme: GraphsTheme {
        backgroundColor: EaStyle.Colors.chartBackground
        plotAreaBackgroundColor: EaStyle.Colors.chartBackground

        axisX.mainColor: EaStyle.Colors.chartGridLine
        axisX.mainWidth: 0

        axisY.mainColor: EaStyle.Colors.chartGridLine
        axisY.mainWidth: 0

        gridVisible: true
        grid.mainWidth: 1
        grid.subWidth: 0
        grid.mainColor: EaStyle.Colors.chartGridLine
        grid.subColor: EaStyle.Colors.chartMinorGridLine

        labelFont.family: EaStyle.Fonts.fontFamily
        labelFont.pixelSize: EaStyle.Sizes.fontPixelSize
        labelTextColor: EaStyle.Colors.chartLabels
    }
    // theme

    // axisX
    axisX: ValueAxis {
        labelDelegate: TextEdit {
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            bottomPadding: EaStyle.Sizes.fontPixelSize
            color: EaStyle.Colors.chartLabels
        }

        titleText: 'x'
        min: 0
        max: 100
    }
    // axisX

    // axisY
    axisY: ValueAxis {
        labelDelegate: TextEdit {
            horizontalAlignment: TextInput.AlignRight
            verticalAlignment: Text.AlignVCenter
            rightPadding: -EaStyle.Sizes.fontPixelSize
            color: EaStyle.Colors.chartLabels
        }

        titleText: 'y'
        min: -2
        max: 2
    }
    // axisY

    // lineSeries
    LineSeries {
        color: 'red'

        XYPoint { x: 0; y: -1 }
        XYPoint { x: 50; y: 1.5 }
        XYPoint { x: 100; y: -0.5 }
    }
    // lineSeries

}
