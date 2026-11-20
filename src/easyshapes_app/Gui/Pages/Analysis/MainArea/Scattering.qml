// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtQuick.VectorImage
import QtGraphs

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


// Main-area window: the SANS curves ticked Show in Scattering view, log I
// against log q, each in its row's colour. QtGraphs has no log axis, so
// the backend sends log10 of q and I, and the axes label each decade 10ⁿ.
// Staggered view lowers each further shown curve, here only; the legend
// gives each one's factor. While a calculation runs, the top left shows
// the spinning logo and the curve being made, and the curves already
// drawn stay in view under it. The tool buttons at the top right are
// EasyReflectometry's: legend, hover tooltip, pan, box zoom, reset.
// Scattering view's Export as PNG saves the chart and its legend.
Rectangle {
    id: root

    readonly property var curves: Globals.BackendWrapper.scatteringCurves
    readonly property var ranges: Globals.BackendWrapper.scatteringRanges
    readonly property bool running: Globals.BackendWrapper.scatteringRunningCurve !== ""
    // Decades each further shown curve goes down
    readonly property real stagger: Globals.Vars.scatteringStaggered ? Globals.Vars.scatteringStaggerDecades : 0
    // Rows ticked Show, in order: the k-th is drawn k × stagger lower
    property var shownRows: []
    // The parts below show by this and running, not by each other's
    // visible: a hidden parent hides its children's, which never came back
    readonly property bool hasPlot: shownRows.length > 0

    // Page state: the legend on at first, the hover tooltip off, a drag
    // zooms into a box (else it pans). hoverText is '' while the mouse is
    // off the lines; hoverPoint is the mouse on the chart
    property bool legendShown: true
    property bool hoverShown: false
    property bool boxZoom: true
    property string hoverText: ""
    property point hoverPoint: Qt.point(0, 0)

    readonly property string hint: {
        if (root.running || root.hasPlot)
            return ""
        return Globals.BackendWrapper.scatteringSelectedStructure < 0
               ? qsTr("Assemble the sample model to calculate its scattering")
               : qsTr("Calculate a curve, or tick Show in Scattering view (Advanced controls)")
    }

    color: EaStyle.Colors.mainContentBackground

    // A tick's label. QtGraphs puts its value in the text property: 10ⁿ
    // for a whole decade, the value itself between decades. QtGraphs gives
    // each y label a fixed 40 px slot; alignRight keeps it against the axis
    component TickLabel: Item {
        property string text
        property bool alignRight: false
        implicitWidth: tickText.implicitWidth
        implicitHeight: tickText.implicitHeight

        EaElements.Label {
            id: tickText
            x: parent.alignRight ? parent.width - width : (parent.width - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            color: EaStyle.Colors.chartLabels
            textFormat: Text.RichText
            text: {
                const value = parseFloat(parent.text)
                if (isNaN(value))
                    return parent.text
                return Number.isInteger(value) ? `10<sup>${value}</sup>` : `${Number(Math.pow(10, value).toPrecision(2))}`
            }
        }
    }

    // Fills each shown curve's line, lowered by its place among the shown
    // ones. Hidden curves keep their old points, out of sight
    function redraw() {
        const rows = []
        for (let row = 0; root.curves && row < root.curves.count; ++row) {
            const series = seriesMaker.objectAt(row)
            if (!series || !root.curves.get(row).shown)
                continue
            const shift = rows.length * root.stagger
            const points = Globals.BackendWrapper.scatteringCurvePoints(row)
            series.replace(shift ? points.map(p => Qt.point(p.x, p.y - shift)) : points)
            rows.push(row)
        }
        root.shownRows = rows
    }

    onStaggerChanged: redraw()

    // A removed row redraws from objectRemoved instead: by then the lines
    // below it have moved up to their new rows
    Connections {
        target: root.curves
        function onDataChanged() { root.redraw() }
        function onModelReset() { root.redraw() }
    }
    // Saved once the Analysis page has shown this tab, as a hidden chart
    // renders nothing; twice the screen's pixels, so it stays sharp on
    // slides
    Connections {
        target: Globals.Vars
        function onScatteringPngRequested(path) {
            Qt.callLater(() => plot.grabToImage(result => {
                if (!result.saveToFile(path))
                    Globals.BackendWrapper.errorSetMessage(qsTr("Could not save %1").arg(path))
            }, Qt.size(plot.width * 2, plot.height * 2)))
        }
    }

    // One line per curve, in its row's colour, named after its curve for
    // the hover tooltip. The roles come through model: a series has its
    // own name property
    Instantiator {
        id: seriesMaker
        model: root.curves
        delegate: LineSeries {
            required property int index
            required property var model
            name: model.name
            width: 2
            color: Globals.Vars.scatteringColors[index] ?? '#898781'
            visible: model.shown
            hoverable: root.hoverShown
        }
        onObjectAdded: (index, object) => {
            chart.addSeries(object)
            root.redraw()
        }
        onObjectRemoved: (index, object) => {
            chart.removeSeries(object)
            root.redraw()
        }
    }

    EaElements.Label {
        anchors.centerIn: parent
        visible: root.hint !== ""
        color: EaStyle.Colors.themeForegroundMinor
        text: root.hint
    }

    // The running calculation at the left, the tool buttons at the right
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: EaStyle.Sizes.fontPixelSize
        visible: root.running || root.hasPlot
        height: Math.max(root.running ? progress.height : 0, root.hasPlot ? tools.height : 0)

        Row {
            id: progress
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.running
            spacing: EaStyle.Sizes.fontPixelSize

            // The SVG spins by its own animation, as in Engine output
            VectorImage {
                id: spinner
                anchors.verticalCenter: parent.verticalCenter
                width: EaStyle.Sizes.fontPixelSize * 2.5
                height: width
                // Drawn at its own 660 px otherwise
                fillMode: VectorImage.PreserveAspectFit
                source: Qt.resolvedUrl("../../../Resources/Logos/EasyShapes.svg")
                preferredRendererType: VectorImage.CurveRenderer
                animations.loops: Animation.Infinite
            }

            // The name only, cut short before the tool buttons; the
            // settings are in the curve's hover text once it has data
            EaElements.Label {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth,
                                header.width - spinner.width - progress.spacing
                                - (root.hasPlot ? tools.width + EaStyle.Sizes.fontPixelSize : 0))
                elide: Text.ElideRight
                color: EaStyle.Colors.themeForegroundMinor
                text: qsTr("Calculating %1").arg(Globals.BackendWrapper.scatteringRunningCurve)
            }
        }

        // As EasyReflectometry's chart tool row: pan and box zoom are the
        // two modes of a drag, each button switches between them
        Row {
            id: tools
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasPlot
            spacing: EaStyle.Sizes.fontPixelSize * 0.25

            EaElements.TabButton {
                checked: root.legendShown
                autoExclusive: false
                height: EaStyle.Sizes.toolButtonHeight
                width: EaStyle.Sizes.toolButtonHeight
                borderColor: EaStyle.Colors.chartAxis
                fontIcon: "align-left"
                ToolTip.text: root.legendShown ? qsTr("Hide legend") : qsTr("Show legend")
                onClicked: root.legendShown = checked
            }

            EaElements.TabButton {
                checked: root.hoverShown
                autoExclusive: false
                height: EaStyle.Sizes.toolButtonHeight
                width: EaStyle.Sizes.toolButtonHeight
                borderColor: EaStyle.Colors.chartAxis
                fontIcon: "comment-alt"
                ToolTip.text: qsTr("Show coordinates tooltip on hover")
                onClicked: root.hoverShown = checked
            }

            Item { height: 1; width: EaStyle.Sizes.fontPixelSize * 0.5 }  // spacer

            EaElements.TabButton {
                checked: !root.boxZoom
                autoExclusive: false
                height: EaStyle.Sizes.toolButtonHeight
                width: EaStyle.Sizes.toolButtonHeight
                borderColor: EaStyle.Colors.chartAxis
                fontIcon: "arrows-alt"
                ToolTip.text: qsTr("Enable pan")
                onClicked: root.boxZoom = !root.boxZoom
            }

            EaElements.TabButton {
                checked: root.boxZoom
                autoExclusive: false
                height: EaStyle.Sizes.toolButtonHeight
                width: EaStyle.Sizes.toolButtonHeight
                borderColor: EaStyle.Colors.chartAxis
                fontIcon: "expand"
                ToolTip.text: qsTr("Enable box zoom")
                onClicked: root.boxZoom = !root.boxZoom
            }

            EaElements.TabButton {
                checkable: false
                height: EaStyle.Sizes.toolButtonHeight
                width: EaStyle.Sizes.toolButtonHeight
                borderColor: EaStyle.Colors.chartAxis
                fontIcon: "home"
                ToolTip.text: qsTr("Reset axes; a right-click on the chart does too")
                // Undoes a zoom or a pan: the axes show the ranges again
                onClicked: {
                    for (const axis of [chart.axisX, chart.axisY]) {
                        axis.zoom = 1
                        axis.pan = 0
                    }
                }
            }
        }
    }

    // The chart and its legend: what Export as PNG writes
    Item {
        id: plot
        anchors.top: header.visible ? header.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.hasPlot

        GraphsView {
            id: chart
            anchors.fill: parent

            marginTop: EaStyle.Sizes.fontPixelSize * 2
            marginBottom: EaStyle.Sizes.fontPixelSize * 2
            // Room for the y title, which is drawn here, left of the labels
            marginLeft: yTitle.height + EaStyle.Sizes.fontPixelSize * 0.5
            marginRight: EaStyle.Sizes.fontPixelSize * 2

            zoomAreaEnabled: root.boxZoom
            panStyle: root.boxZoom ? GraphsView.PanStyle.None : GraphsView.PanStyle.Drag

            // The values at the mouse as they are: back from log10, with the
            // curve's staggered shift added back
            onHover: (seriesName, position, value) => {
                const k = root.shownRows.findIndex(row => root.curves.get(row).name === seriesName)
                const shift = Math.max(k, 0) * root.stagger
                root.hoverPoint = position
                root.hoverText = qsTr("%1: q = %2 Å⁻¹, I = %3 cm⁻¹")
                                 .arg(seriesName)
                                 .arg(Math.pow(10, value.x).toPrecision(3))
                                 .arg(Math.pow(10, value.y + shift).toPrecision(3))
            }
            onHoverExit: root.hoverText = ""

            // As the reset button
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    for (const axis of [chart.axisX, chart.axisY]) {
                        axis.zoom = 1
                        axis.pan = 0
                    }
                }
            }

            // The values at the mouse, as EasyReflectometry's hover tooltip
            EaElements.ToolTip {
                x: root.hoverPoint.x + EaStyle.Sizes.fontPixelSize
                y: root.hoverPoint.y - height - EaStyle.Sizes.fontPixelSize * 0.5
                visible: root.hoverShown && root.hoverText !== ""
                text: root.hoverText
            }

            // As the Sample model page's chart
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

            // A tick at each decade once the range spans two; QtGraphs
            // picks the ticks below that
            axisX: ValueAxis {
                titleText: qsTr("q, Å⁻¹")
                min: root.ranges ? root.ranges.xmin : 0
                max: root.ranges ? root.ranges.xmax : 1
                tickInterval: max - min >= 2 ? 1 : 0
                labelDecimals: tickInterval === 1 ? 0 : -1
                labelDelegate: TickLabel {}
            }

            // The last staggered curve stays in view: the bottom goes down
            // by the shift of the last shown curve. QtGraphs draws its
            // title inside the labels' 40 px slot, over any label wider
            // than "-2": the title is yTitle instead
            axisY: ValueAxis {
                titleVisible: false
                min: root.ranges ? root.ranges.ymin - Math.max(0, root.shownRows.length - 1) * root.stagger : 0
                max: root.ranges ? root.ranges.ymax : 1
                tickInterval: max - min >= 2 ? 1 : 0
                labelDecimals: tickInterval === 1 ? 0 : -1
                labelDelegate: TickLabel { alignRight: true }
            }
        }

        // The y title, turned to read upwards, in the chart's left margin.
        // Short, so it stays in place: the legend gives the shifts
        EaElements.Label {
            id: yTitle
            // Turned about its centre: this puts that centre half its
            // height from the left edge
            x: EaStyle.Sizes.fontPixelSize * 0.25 + height / 2 - width / 2
            y: chart.plotArea.y + chart.plotArea.height / 2 - height / 2
            rotation: -90
            color: EaStyle.Colors.chartLabels
            text: qsTr("I(q), cm⁻¹")
        }

        // Each shown curve's colour and name, at the top right of the
        // plot, with its factor when staggered (as papers write "×10⁻¹").
        // The swatch carries the colour; the name stays in the text colour
        Rectangle {
            x: chart.plotArea.x + chart.plotArea.width - width - EaStyle.Sizes.fontPixelSize
            y: chart.plotArea.y + EaStyle.Sizes.fontPixelSize
            visible: root.legendShown
            width: legendColumn.width + EaStyle.Sizes.fontPixelSize * 1.5
            height: legendColumn.height + EaStyle.Sizes.fontPixelSize
            radius: EaStyle.Sizes.fontPixelSize * 0.25
            color: EaStyle.Colors.mainContentBackgroundHalfTransparent
            border.color: EaStyle.Colors.chartGridLine

            Column {
                id: legendColumn
                anchors.centerIn: parent

                Repeater {
                    model: root.shownRows

                    Row {
                        required property int index
                        required property int modelData
                        spacing: EaStyle.Sizes.fontPixelSize * 0.5

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: EaStyle.Sizes.fontPixelSize * 1.5
                            height: 3
                            radius: 1.5
                            color: Globals.Vars.scatteringColors[modelData] ?? '#898781'
                        }
                        EaElements.Label {
                            textFormat: Text.RichText
                            text: root.curves.get(modelData).name
                                  + (index > 0 && root.stagger ? ` ×10<sup>${-index * root.stagger}</sup>` : "")
                        }
                    }
                }
            }
        }
    }
}
