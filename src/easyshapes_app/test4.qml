// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
//
// T56 - faulty and fixed, side by side, with the real components.
//
//   column 1  description and controls
//   column 2  TableView, box hides by CLIP        - faulty
//   column 3  TableView, box hides by COVER       - fixed
//   column 4  ListView,  box hides by CLIP        - faulty
//   column 5  ListView,  box hides by COVER       - fixed
//
// WHY 'COVER' RATHER THAN layer.enabled
//
// The previous build used layer.enabled, which works but is a blunt tool: it
// renders the whole subtree to a texture, and the texture is rebuilt on every
// frame of a height animation, which makes text jiggle while a group
// collapses.
//
// T54 found a second remedy that needs no texture. Preset P6 - hiding content
// with an opaque cover instead of clipping it - was clean on both faults:
//
//   scroll fault  a clipped item straddling the edge of an enclosing clip
//                 loses its clip. A box that never clips cannot lose one.
//   hover fault   a Rectangle declared inside a ListView and anchored to the
//                 view escapes the box's clip on a rebuild. With no clip and
//                 an opaque cover drawn above it, there is nothing to escape.
//
// The cost is that the cover must match the background behind it, and hidden
// content stays hit-testable unless it is also disabled.
//
// WHAT TO DO
//   REVEAL          opens every box, so you can see what is meant to be hidden
//   scroll a column until a box crosses the black TOP or BOTTOM line
//   REBUILD (hover) provokes the other fault with no scrolling at all
//
// Only the navy TOPBAR should ever be visible. Anything else on the grey has
// escaped.

import QtQuick
import QtQuick.Window
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents


Window {
    id: window

    width: 1500
    height: 900
    visible: true
    title: 'T56 - faulty and fixed side by side'

    color: EaStyle.Colors.themeBackground

    readonly property string testId: 'T57'

    property bool revealed: false

    // EaComponents.TableView and EaComponents.ListView both set clip: true on
    // themselves. So a 'fixed' box that hides by cover still contains a
    // clipped item, and that item loses the outer clip when it straddles an
    // edge - which is why the cover columns leaked.
    //
    // This switch turns the LIST's own clip off, leaving no clipped item
    // anywhere in the box. If the cover columns then stay clean, the remedy
    // is 'no clip anywhere', not merely 'no clip on the box'.
    property bool innerClip: true

    // The most promising remedy for the straddle fault: put the layer on the
    // SCROLL AREA rather than on each group.
    //
    // A layer crops by texture bounds and never intersects clip rectangles,
    // so nothing inside can straddle anything. Unlike layering a group box,
    // the scroll area's height does not animate, so there is no per-frame
    // re-rasterisation and none of the jiggle.
    //
    // One texture per sidebar instead of one per group.
    property bool layerScrollArea: false

    readonly property int listWidth: 230
    readonly property int boxWidth: 250

    function mark(what) {
        console.log('=== MARK: ' + what + ' ===')
    }

    function tableModel(word) {
        const rows = []
        for (let i = 0; i < 7; ++i)
            rows.push({ name: word + ' ' + (i + 1),
                        description: word + ' description ' + (i + 1) })
        return rows
    }

    function scrollAll(amount) {
        const areas = [tableFaulty, tableFixed, listFaulty, listFixed]
        for (const a of areas) {
            if (amount === 0)
                a.flick.contentY = 0
            else
                a.flick.contentY += amount
        }
        window.mark('scroll ' + Math.round(tableFaulty.flick.contentY))
    }

    Rectangle {
        id: banner

        width: window.width
        height: 26
        color: '#204060'

        Text {
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 14
            font.bold: true
            color: '#ffffff'
            text: window.testId +
                  '   layer on scroll area: ' + (window.layerScrollArea ? 'ON' : 'off') +
                  '   |   list clip: ' + (window.innerClip ? 'on' : 'OFF') +
                  '   |   faulty = box clips, fixed = box covers'
        }
    }

    Row {
        anchors.top: banner.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // ------------------------------------------------ column 1: controls
        Item {
            width: 400
            height: parent.height

            Column {
                x: 14
                y: 14
                width: parent.width - 28
                spacing: 10

                EaElements.Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: 'Four scrollable columns. Each holds two collapsed ' +
                          'boxes with a real EasyApp list inside. Only the navy ' +
                          'TOPBAR should ever be visible.\n\n' +
                          'FAULTY boxes hide their content with clip.\n' +
                          'FIXED boxes hide it with an opaque cover and no clip ' +
                          'at all - the P6 remedy from T54.\n\n' +
                          'Scroll until a box crosses the black TOP or BOTTOM ' +
                          'line, and watch the grey outside the scroll area.\n\n' +
                          'Hover REBUILD for the other fault, which needs no ' +
                          'scrolling.'
                }

                Rectangle {
                    width: 340
                    height: 40
                    color: window.revealed ? '#c04040' : '#dcdcdc'
                    border.color: '#999999'

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        font.bold: true
                        color: window.revealed ? '#ffffff' : '#222222'
                        text: window.revealed ? 'REVEAL is ON - press to hide again'
                                              : 'REVEAL what is hidden'
                    }

                    TapHandler {
                        onTapped: {
                            window.revealed = !window.revealed
                            window.mark('revealed = ' + window.revealed)
                        }
                    }
                }

                Rectangle {
                    width: 340
                    height: 44
                    color: window.layerScrollArea ? '#1a6a2a' : '#8c1616'
                    border.color: '#555555'

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        font.bold: true
                        color: '#ffffff'
                        text: window.layerScrollArea
                                  ? 'LAYER on the scroll area: ON'
                                  : 'LAYER on the scroll area: OFF'
                    }

                    TapHandler {
                        onTapped: {
                            window.layerScrollArea = !window.layerScrollArea
                            window.mark('layerScrollArea = ' + window.layerScrollArea)
                        }
                    }
                }

                Rectangle {
                    width: 340
                    height: 40
                    color: window.innerClip ? '#8c1616' : '#1a6a2a'
                    border.color: '#555555'

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        font.bold: true
                        color: '#ffffff'
                        text: window.innerClip
                                  ? "LIST's own clip: ON  (components' default)"
                                  : "LIST's own clip: OFF"
                    }

                    TapHandler {
                        onTapped: {
                            window.innerClip = !window.innerClip
                            window.mark('innerClip = ' + window.innerClip)
                        }
                    }
                }

                Row {
                    spacing: 6

                    NudgeButton { amount: 1;   label: '+1' }
                    NudgeButton { amount: 10;  label: '+10' }
                    NudgeButton { amount: 60;  label: '+60' }
                    NudgeButton { amount: 0;   label: 'top' }
                }

                Rectangle {
                    id: rebuildButton

                    width: 340
                    height: 38
                    color: rebuildHover.hovered ? '#f7f7f7' : '#dcdcdc'
                    border.color: '#999999'

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        color: '#222222'
                        text: 'REBUILD (hover me)'
                    }

                    HoverHandler {
                        id: rebuildHover
                        onHoveredChanged: window.mark('rebuild ' + (hovered ? 'ON' : 'OFF'))
                    }

                    Loader {
                        active: rebuildHover.hovered
                        x: 0
                        y: 42

                        sourceComponent: Rectangle {
                            width: 340
                            height: 26
                            color: '#ffffe0'
                            border.color: '#999999'

                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: 12
                                color: '#222222'
                                text: 'node added and removed'
                            }
                        }
                    }
                }

                EaElements.Label {
                    width: parent.width
                    text: 'scroll ' + Math.round(tableFaulty.flick.contentY) +
                          '\nplatform ' + Qt.platform.os
                }
            }
        }

        // ------------------------------------------- column 2: table, faulty
        ScrollArea {
            id: tableFaulty

            width: 275
            height: parent.height
            heading: 'TABLE  faulty (clip)'

            HidingBox { tag: 'TF top';    mode: 'clip'; ExampleTable { word: 'tf' } }
            Spacer {}
            HidingBox { tag: 'TF bottom'; mode: 'clip'; ExampleTable { word: 'tf2' } }
        }

        // -------------------------------------------- column 3: table, fixed
        ScrollArea {
            id: tableFixed

            width: 275
            height: parent.height
            heading: 'TABLE  fixed (cover)'

            HidingBox { tag: 'TX top';    mode: 'cover'; ExampleTable { word: 'tx' } }
            Spacer {}
            HidingBox { tag: 'TX bottom'; mode: 'cover'; ExampleTable { word: 'tx2' } }
        }

        // -------------------------------------------- column 4: list, faulty
        ScrollArea {
            id: listFaulty

            width: 275
            height: parent.height
            heading: 'LIST  faulty (clip)'

            HidingBox { tag: 'LF top';    mode: 'clip'; ExampleList {} }
            Spacer {}
            HidingBox { tag: 'LF bottom'; mode: 'clip'; ExampleList {} }
        }

        // --------------------------------------------- column 5: list, fixed
        ScrollArea {
            id: listFixed

            width: 275
            height: parent.height
            heading: 'LIST  fixed (cover)'

            HidingBox { tag: 'LX top';    mode: 'cover'; ExampleList {} }
            Spacer {}
            HidingBox { tag: 'LX bottom'; mode: 'cover'; ExampleList {} }
        }
    }

    // ------------------------------------------------------------ components

    // The real TableView, configured as the Project page's Examples group
    // configures it.
    component ExampleTable: EaComponents.TableView {
        id: tableView

        property string word: 'row'

        width: window.listWidth

        // The component sets clip: true on itself. Overriding it here is the
        // only way to have a box with no clipped item inside it at all.
        clip: window.innerClip

        showHeader: false
        tallRows: true
        maxRowCountShow: 6

        defaultInfoText: qsTr('nothing here')

        header: EaComponents.TableViewHeader {
            EaComponents.TableViewLabel {
                flexibleWidth: true
                horizontalAlignment: Text.AlignLeft
                text: qsTr('name')
            }
        }

        model: window.tableModel(tableView.word)

        delegate: EaComponents.TableViewDelegate {
            EaComponents.TableViewTwoRowsAdvancedLabel {
                fontIcon: 'archive'
                text: tableView.model[index].name
                minorText: tableView.model[index].description
            }
        }
    }

    // The real ListView, configured as the Analysis page's
    // EquilibrationOutputs group configures it.
    component ExampleList: EaComponents.ListView {
        width: window.listWidth

        clip: window.innerClip

        defaultInfoText: qsTr('empty')
        multiSelection: false

        columnWidths: [-1]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr('name')
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: ListModel {
            ListElement { name: 'listview 1' }
            ListElement { name: 'listview 2' }
            ListElement { name: 'listview 3' }
            ListElement { name: 'listview 4' }
            ListElement { name: 'listview 5' }
            ListElement { name: 'listview 6' }
            ListElement { name: 'listview 7' }
        }

        delegate: EaComponents.ListViewDelegate {
            required property string name

            EaComponents.TableViewLabel {
                text: name
            }
        }
    }

    // A short scrollable area with grey space above and below, both edges
    // marked. Uses the real SideBarColumn, which is a Flickable.
    component ScrollArea: Item {
        id: area

        default property alias content: column.content
        property string heading: ''
        readonly property Flickable flick: column

        // Heading, plus what is actually applied to this column right now, so
        // a switch that did not take can be told from a remedy that did not
        // work.
        EaElements.Label {
            x: 12
            y: 8
            width: area.width - 20
            wrapMode: Text.WordWrap
            font.bold: true
            text: area.heading + '\nlayer ' + (column.layer.enabled ? 'ON' : 'off') +
                  '   listclip ' + (window.innerClip ? 'on' : 'OFF')
        }

        Rectangle {
            x: 0
            y: column.y - 2
            width: area.width
            height: 2
            color: '#000000'
        }

        Text {
            x: area.width - 34
            y: column.y - 17
            font.pixelSize: 11
            color: '#000000'
            text: 'TOP'
        }

        Rectangle {
            x: 0
            y: column.y + column.height
            width: area.width
            height: 2
            color: '#000000'
        }

        Text {
            x: area.width - 54
            y: column.y + column.height + 3
            font.pixelSize: 11
            color: '#000000'
            text: 'BOTTOM'
        }

        EaComponents.SideBarColumn {
            id: column

            x: 12
            y: 300
            width: area.width - 24
            height: 300

            layer.enabled: window.layerScrollArea
        }
    }

    // SideBarColumn lays its children out in a Column, so the gap between the
    // two boxes is made with a spacer rather than by setting y.
    component Spacer: Item {
        width: window.boxWidth
        height: 380
    }

    // A collapsed box. Only its navy topbar should be visible.
    //
    //   mode 'clip'   hides its content by cropping - the faulty way
    //   mode 'cover'  hides it under an opaque rectangle, no clip at all
    component HidingBox: Item {
        id: box

        default property alias content: holder.data
        property string tag: ''
        property string mode: 'clip'

        readonly property int titleHeight: 34

        width: window.boxWidth
        height: window.revealed ? titleHeight + holder.childrenRect.height
                                : titleHeight

        clip: mode === 'clip'

        Item {
            id: holder

            y: box.titleHeight
            width: window.boxWidth
        }

        // The cover. Opaque, in the background colour, over everything below
        // the topbar. Drawn above the content but below the topbar.
        Rectangle {
            visible: box.mode === 'cover' && !window.revealed
            z: 2
            y: box.titleHeight
            width: window.boxWidth
            height: Math.max(holder.childrenRect.height, 400)
            color: EaStyle.Colors.themeBackground
        }

        Rectangle {
            z: 3
            width: window.boxWidth
            height: box.titleHeight
            color: '#1a3a5c'

            Text {
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 12
                font.bold: true
                color: '#ffffff'
                text: box.tag + ' TOPBAR'
            }
        }
    }

    component NudgeButton: Rectangle {
        property int amount: 1
        property string label: ''

        width: 80
        height: 34
        color: '#d8d0c0'
        border.color: '#999999'

        Text {
            anchors.centerIn: parent
            font.pixelSize: 13
            color: '#222222'
            text: parent.label
        }

        TapHandler { onTapped: window.scrollAll(parent.amount) }
    }

    Component.onCompleted: window.mark(testId + ' started on ' + Qt.platform.os)
}
