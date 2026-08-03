// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
//
// T54 - named presets, one at a time.
//
// WHAT IS KNOWN
//
// A clipped item that straddles the boundary of an enclosing clip loses its
// own clip: its hidden content is drawn outside both clips and stays drawn.
// Nothing leaks while the item sits wholly inside.
//
// Separately, a Rectangle declared inside a ListView and anchored to the view
// leaks on any rebuild - a hover is enough. Parenting it outside the list
// fixes that one.
//
// HOW TO USE THIS
//
// Pick one preset on the left. Press REVEAL once to see what is hidden, then
// REVEAL again to hide it. Scroll until the readout says the box is
// straddling the top edge. Report the preset id and what you saw.
//
// The presets are exclusive - exactly one is active - so there are no
// combinations to keep track of.

import QtQuick
import QtQuick.Window


Window {
    id: window

    width: 1120
    height: 860
    visible: true
    title: 'T54 - presets'

    color: '#e9e9e9'

    readonly property string testId: 'T54'

    property string preset: 'P4'
    property bool revealed: false

    // Colours chosen so nothing can be mistaken for anything else:
    //   window   light grey        - outside the scroll area
    //   backdrop pale blue         - inside the scroll area
    //   topbar   dark navy         - the strip that is allowed to be visible
    //   rows     dark red, yellow text - must never be visible
    //   border   bright magenta    - must never be visible
    // The cover in P6 uses the backdrop colour, since that is what it hides
    // against.
    readonly property color backdropColor: '#dce8f4'
    readonly property color topbarColor: '#1a3a5c'
    readonly property color rowColorA: '#8c1616'
    readonly property color rowColorB: '#a81c1c'
    readonly property color rowTextColor: '#ffe000'
    readonly property color borderColor: '#d000c0'

    readonly property var presetList: [
        { id: 'P1', text: 'filled rows only, clipped',
          note: 'do plain filled rectangles leak when straddling?' },
        { id: 'P2', text: 'antialiased border only, clipped',
          note: 'does an outline leak when straddling?' },
        { id: 'P3', text: 'rows + border, OUTER CLIP OFF',
          note: 'no enclosing clip to intersect with - should be clean' },
        { id: 'P4', text: 'rows + border, both clips on',
          note: 'the main case - expected to leak when straddling' },
        { id: 'P5', text: 'rows + border, box uses layer.enabled',
          note: 'the known workaround - expected clean' },
        { id: 'P6', text: 'rows + border, hidden by a cover, no clip',
          note: 'hiding without clipping - expected clean' },
        { id: 'P7', text: 'ListView, border inside the list',
          note: 'the real component shape - leaks on hover too' },
        { id: 'P8', text: 'ListView, border parented outside',
          note: 'the proposed fix - clean on hover, still leaks straddling' }
    ]

    // ---- what each preset means -------------------------------------------
    readonly property bool outerClips: preset !== 'P3'
    readonly property string hideMode:
        preset === 'P5' ? 'layer' :
        preset === 'P6' ? 'cover' : 'clip'
    readonly property bool showRows: preset !== 'P2'
    readonly property bool showBorder: preset !== 'P1'
    readonly property bool useListView: preset === 'P7' || preset === 'P8'
    readonly property bool borderOutside: preset === 'P8'

    function mark(what) {
        console.log('=== MARK: ' + what + ' ===')
    }

    function describe() {
        for (let i = 0; i < presetList.length; ++i)
            if (presetList[i].id === preset)
                return preset + ' - ' + presetList[i].text
        return preset
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
            text: window.testId + '   ' + window.describe()
        }
    }

    Row {
        anchors.top: banner.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // ------------------------------------------------ column 1: presets
        Rectangle {
            width: 460
            height: parent.height
            color: '#e9e9e9'

            Column {
                x: 12
                y: 10
                width: parent.width - 24
                spacing: 6

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                    color: '#222222'
                    text: 'Pick one preset. Press REVEAL to see what is hidden, ' +
                          'then again to hide it. Scroll until the readout says ' +
                          'the box straddles the top edge. Report the id.\n\n' +
                          'Navy TOPBAR = allowed to be visible.\n' +
                          'Dark red rows with yellow text, and the magenta ' +
                          'border = must never be visible.\n' +
                          'Pale blue = inside the scroll area. Grey = outside it.'
                }

                Repeater {
                    model: window.presetList

                    Rectangle {
                        required property var modelData

                        width: 436
                        height: 44
                        color: window.preset === modelData.id ? '#3060a0' : '#dcdcdc'
                        border.color: '#999999'

                        Column {
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                font.pixelSize: 13
                                font.bold: true
                                color: window.preset === parent.parent.modelData.id
                                           ? '#ffffff' : '#222222'
                                text: parent.parent.modelData.id + '   ' +
                                      parent.parent.modelData.text
                            }

                            Text {
                                font.pixelSize: 11
                                color: window.preset === parent.parent.modelData.id
                                           ? '#d0e0f0' : '#555555'
                                text: parent.parent.modelData.note
                            }
                        }

                        TapHandler {
                            onTapped: {
                                window.preset = parent.modelData.id
                                window.mark('preset ' + window.preset)
                            }
                        }
                    }
                }

                Item { width: 1; height: 6 }

                Rectangle {
                    width: 436
                    height: 38
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

                Row {
                    spacing: 6

                    NudgeButton { amount: 1;   label: '+1' }
                    NudgeButton { amount: 10;  label: '+10' }
                    NudgeButton { amount: 100; label: '+100' }
                    NudgeButton { amount: 0;   label: 'top' }
                }

                Rectangle {
                    id: rebuildButton

                    width: 436
                    height: 34
                    color: rebuildHover.hovered ? '#f7f7f7' : '#dcdcdc'
                    border.color: '#999999'

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        color: '#222222'
                        text: 'REBUILD (hover me) - tests the hover fault'
                    }

                    HoverHandler {
                        id: rebuildHover
                        onHoveredChanged: window.mark('rebuild ' + (hovered ? 'ON' : 'OFF'))
                    }

                    Loader {
                        active: rebuildHover.hovered
                        x: 0
                        y: 38

                        sourceComponent: Rectangle {
                            width: 436
                            height: 24
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

                // What the active preset is actually building. If this does
                // not match what is on screen, the preset did not take.
                Text {
                    width: parent.width
                    font.pixelSize: 12
                    color: '#222222'
                    text: 'ACTIVE: ' + window.preset +
                          '\n  rows      ' + (window.showRows && !window.useListView) +
                          '\n  border    ' + (window.showBorder || window.useListView) +
                          '\n  listview  ' + window.useListView +
                          '\n  hide by   ' + window.hideMode +
                          '\n  outer clip ' + window.outerClips
                }

                // Where each box sits relative to the two edges. Negative
                // means above the top edge, positive past the bottom one.
                Text {
                    width: parent.width
                    font.pixelSize: 12
                    font.bold: true
                    color: '#222222'
                    text: {
                        const topBoxTop = 60 - outer.contentY
                        const bottomBoxTop = 900 - outer.contentY
                        const h = outer.height
                        let s = 'contentY ' + Math.round(outer.contentY) + '\n'
                        s += 'TOP box    ' + Math.round(topBoxTop) +
                             (topBoxTop < 0 && topBoxTop > -36
                                  ? '   <-- STRADDLING TOP EDGE' : '') + '\n'
                        s += 'BOTTOM box ' + Math.round(bottomBoxTop) +
                             (bottomBoxTop < h && bottomBoxTop > h - 36
                                  ? '   <-- STRADDLING BOTTOM EDGE' : '')
                        return s
                    }
                }
            }
        }

        // --------------------------------------------------- column 2: test
        //
        // The Flickable is deliberately short, with plenty of grey either
        // side of it. Anything drawn on the grey has escaped the Flickable's
        // clip, and both edges are easy to watch.
        Item {
            width: 400
            height: parent.height

            // Edge markers, drawn outside the Flickable so they cannot be
            // confused with its contents.
            Rectangle {
                x: 0
                y: outer.y - 2
                width: 400
                height: 2
                color: '#000000'
            }

            Text {
                x: 366
                y: outer.y - 18
                font.pixelSize: 11
                color: '#000000'
                text: 'TOP'
            }

            Rectangle {
                x: 0
                y: outer.y + outer.height
                width: 400
                height: 2
                color: '#000000'
            }

            Text {
                x: 348
                y: outer.y + outer.height + 4
                font.pixelSize: 11
                color: '#000000'
                text: 'BOTTOM'
            }

            Flickable {
                id: outer

                x: 20
                y: 260
                width: 340
                height: 300

                contentWidth: width
                contentHeight: 1600

                clip: window.outerClips
                boundsBehavior: Flickable.StopAtBounds

                Rectangle {
                    width: 330
                    height: 1600
                    color: window.backdropColor
                    border.color: '#9bb4cc'
                }

                TestBox { y: 60;  tag: 'TOP' }
                TestBox { y: 900; tag: 'BOTTOM' }
            }
        }
    }

    component TestBox: Item {
        id: box

        property string tag: ''
            width: 300
            height: window.revealed ? 36 + contentHeight : 36

            readonly property int contentHeight: 200

            clip: window.hideMode === 'clip'
            layer.enabled: window.hideMode === 'layer'

            // --- filled rows ---
            Column {
                visible: window.showRows && !window.useListView
                y: 36
                width: 300

                Repeater {
                    model: window.showRows && !window.useListView ? 5 : 0

                    Rectangle {
                        required property int index

                        width: 300
                        height: 30
                        color: index % 2 ? window.rowColorA : window.rowColorB

                        Text {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 13
                            font.bold: true
                            color: window.rowTextColor
                            text: 'hidden row ' + (index + 1)
                        }
                    }
                }
            }

            // --- a ListView, for P7 and P8 ---
            ListView {
                id: innerList

                visible: window.useListView
                y: 36
                width: 300
                height: 150

                clip: true
                interactive: false
                boundsBehavior: Flickable.StopAtBounds

                model: window.useListView ? 5 : 0

                delegate: Rectangle {
                    required property int index

                    width: 300
                    height: 30
                    color: index % 2 ? window.rowColorA : window.rowColorB

                    Text {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 13
                        font.bold: true
                        color: window.rowTextColor
                        text: 'listview row ' + (index + 1)
                    }
                }

                // Border declared inside the list - the hover fault.
                Rectangle {
                    visible: window.useListView && !window.borderOutside
                    anchors.fill: innerList
                    color: 'transparent'
                    antialiasing: true
                    border.color: window.borderColor
                    border.width: 3
                }
            }

            // --- the standalone border, for P2, P3, P4, P5, P6 ---
            Rectangle {
                visible: window.showBorder && !window.useListView
                y: 36
                width: 300
                height: 150
                color: 'transparent'
                antialiasing: true
                border.color: window.borderColor
                border.width: 3
            }

            // --- the same border, parented outside the list, for P8 ---
            Rectangle {
                visible: window.useListView && window.borderOutside
                parent: box
                x: innerList.x
                y: innerList.y
                width: innerList.width
                height: innerList.height
                color: 'transparent'
                antialiasing: true
                border.color: window.borderColor
                border.width: 3
            }

            // --- the cover, for P6: hides by painting over ---
            Rectangle {
                visible: window.hideMode === 'cover' && !window.revealed
                z: 2
                y: 36
                width: 300
                height: box.contentHeight
                color: window.backdropColor
            }

            // --- the TOPBAR: the only part allowed to be visible ---
            Rectangle {
                z: 3
                width: 300
                height: 36
                color: window.topbarColor

                Text {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 13
                    font.bold: true
                    color: '#ffffff'
                    text: window.preset + ' ' + box.tag + ' TOPBAR'
                }
            }
    }

    component NudgeButton: Rectangle {
        property int amount: 1
        property string label: ''

        width: 104
        height: 34
        color: '#d8d0c0'
        border.color: '#999999'

        Text {
            anchors.centerIn: parent
            font.pixelSize: 13
            color: '#222222'
            text: parent.label
        }

        TapHandler {
            onTapped: {
                if (parent.amount === 0)
                    outer.contentY = 0
                else
                    outer.contentY += parent.amount
                window.mark('contentY = ' + Math.round(outer.contentY))
            }
        }
    }

    Component.onCompleted: window.mark(testId + ' started on ' + Qt.platform.os +
                                       '   preset ' + window.preset)
}
