// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

// A copy of EasyApp's PreferencesDialog, whose rows shapes-app can't
// change from outside. Back to EasyApp's once it offers QtGraphs and
// a language list

import QtQuick
import QtQuick.Controls
import QtCore

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Elements as EaElements


EaElements.Dialog {
    id: dialog

    contentWidth: bar.implicitWidth
    contentHeight: bar.implicitHeight +
                   implicitHeaderHeight +
                   topPadding +
                   bottomPadding +
                   EaStyle.Sizes.fontPixelSize * 9

    title: qsTr("Preferences")

    standardButtons: Dialog.Ok

    // TabBar

    EaElements.TabBar {
        id: bar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        background: Rectangle {
            z: 2
            anchors.fill: parent
            color: "transparent"
            border.color: EaStyle.Colors.appBarBorder
        }

        EaElements.AppBarTabButton {
            fontIcon: "users"
            text: qsTr("Prompts")
            ToolTip.text: qsTr("")
        }

        // No installer to update the app with
        EaElements.AppBarTabButton {
            enabled: false
            fontIcon: "cloud-download-alt"
            text: qsTr("Updates")
            ToolTip.text: qsTr("")
        }

        EaElements.AppBarTabButton {
            fontIcon: "paint-brush"
            text: qsTr("Appearance")
            ToolTip.text: qsTr("")
        }

        EaElements.AppBarTabButton {
            fontIcon: "flask"
            text: qsTr("Experimental")
            ToolTip.text: qsTr("")
        }

        EaElements.AppBarTabButton {
            fontIcon: "laptop-code"
            text: qsTr("Develop")
            ToolTip.text: qsTr("")
        }
    }

    // Main area

    SwipeView {
        id: view

        anchors.top: bar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        topPadding: EaStyle.Sizes.fontPixelSize * 0.75
        leftPadding: EaStyle.Sizes.fontPixelSize * 0.5
        bottomPadding: EaStyle.Sizes.fontPixelSize * 3

        currentIndex: bar.currentIndex

        clip: true

        // Prompts tab content

        Grid {
            columns: 2
            topPadding: EaStyle.Sizes.fontPixelSize * 0.5
            rowSpacing: EaStyle.Sizes.fontPixelSize * 1.5
            columnSpacing: EaStyle.Sizes.fontPixelSize
            verticalItemAlignment: Grid.AlignVCenter

            EaElements.Label {
               text: qsTr("Enable tool tips") + ":"
            }

            EaElements.CheckBox {
                id: toolTipsCheckBox
                checked: EaGlobals.Vars.showToolTips
                onCheckedChanged: EaGlobals.Vars.showToolTips = checked
            }

            EaElements.Label {
                enabled: false
                text: qsTr("Enable user guides") + ":"
            }

            EaElements.CheckBox {
                id: userGuidesCheckBox
                enabled: false
                checked: EaGlobals.Vars.showUserGuides
                onCheckedChanged: EaGlobals.Vars.showUserGuides = checked
            }

        }

        // Updates tab content: none, the tab is disabled. Kept so the
        // pages stay in step with the tabs

        Item {}

        // Appearance tab content

        Grid {
            columns: 3
            columnSpacing: EaStyle.Sizes.fontPixelSize
            rowSpacing: EaStyle.Sizes.fontPixelSize
            verticalItemAlignment: Grid.AlignVCenter

            EaElements.Label {
                text: qsTr("Theme") + ":"
            }

            EaElements.ComboBox {
                model: [qsTr("Light"), qsTr("Dark"), qsTr("System")]
                onActivated: {
                    if (currentIndex === 0)
                        EaStyle.Colors.theme = EaStyle.Colors.LightTheme
                    else if (currentIndex === 1)
                        EaStyle.Colors.theme = EaStyle.Colors.DarkTheme
                    else if (currentIndex === 2)
                        EaStyle.Colors.theme = EaStyle.Colors.SystemTheme
                }
                Component.onCompleted: {
                    if (EaStyle.Colors.theme === EaStyle.Colors.LightTheme)
                        currentIndex = 0
                    else if (EaStyle.Colors.theme === EaStyle.Colors.DarkTheme)
                        currentIndex = 1
                    else if (EaStyle.Colors.theme === EaStyle.Colors.SystemTheme)
                        currentIndex = 2
                }
            }

            EaElements.Label { text: ' ' }

            // The app plots with QtGraphs only
            EaElements.Label {
                enabled: false
                text: qsTr("1D plotting") + ":"
            }

            EaElements.ComboBox {
                enabled: false
                model: ['QtGraphs']
            }

            EaElements.Label { text: ' ' }

            EaElements.Label {
                topPadding: autoCollapseCheckBox.topPadding
                text: qsTr("Auto collapse") + ":"
            }

            EaElements.CheckBox {
                id: autoCollapseCheckBox
                topPadding: 0.5 * EaStyle.Sizes.fontPixelSize
                leftPadding: -3
                checked: EaGlobals.Vars.autoCollapseSideBarGroups
                onCheckedChanged: EaGlobals.Vars.autoCollapseSideBarGroups = checked
                ToolTip.text: qsTr("Auto collapse for side bar groups")
            }

            EaElements.Label { text: ' ' }

        }

        // Experimental tab content

        Grid {
            columns: 2
            columnSpacing: EaStyle.Sizes.fontPixelSize
            rowSpacing: EaStyle.Sizes.fontPixelSize
            verticalItemAlignment: Grid.AlignVCenter

            // Zoom
            EaElements.Label {
                text: qsTr("Zoom") + ":"
            }

            EaElements.ComboBox {
                model: ["100%", "110%", "120%", "130%", "140%", "150%"]
                onCurrentTextChanged: {
                    if (parseInt(currentText) === EaStyle.Sizes.defaultScale) {
                        return
                    }
                    EaStyle.Sizes.defaultScale = parseInt(currentText)
                }
            }
            // Zoom

            // Language: the app has no translations yet
            EaElements.Label {
                enabled: false
                text: qsTr("Language") + ":"
            }

            EaElements.ComboBox {
                enabled: false
                model: ['English']
            }
            // Language

        }

        // Develop tab content

        Grid {
            columns: 2
            columnSpacing: EaStyle.Sizes.fontPixelSize
            rowSpacing: EaStyle.Sizes.fontPixelSize
            verticalItemAlignment: Grid.AlignVCenter

            EaElements.Label {
                enabled: false
                text: qsTr("Logging to") + ":"
            }

            EaElements.ComboBox {
                enabled: false
                model: ["Disabled", "Terminal", "File"]
                currentIndex: 1
            }

            EaElements.Label {
                text: qsTr("Logging level") + ":"
            }

            // Vars.qml saves the level
            EaElements.ComboBox {
                model: ["Debug", "Info", "Error", "Disabled"]
                currentIndex: model.indexOf(EaGlobals.Vars.loggingLevel)
                onActivated: EaGlobals.Vars.loggingLevel = currentValue
            }
        }

    }

    // Persistent settings, under EasyApp's keys

    Settings {
        location: EaGlobals.Vars.settingsFile // Gives WASM error on run
        category: 'Preferences.Prompts'
        property alias enableToolTips: toolTipsCheckBox.checked
        property alias enableUserGuides: userGuidesCheckBox.checked
    }

    Settings {
        location: EaGlobals.Vars.settingsFile // Gives WASM error on run
        category: 'Preferences.Appearance'
        property alias autoCollapseSideBarGroups: autoCollapseCheckBox.checked
    }
}
