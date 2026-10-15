// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Elements as EaElements

import Gui.Globals as Globals


Rectangle {
    id: page

    readonly property int commonSpacing: EaStyle.Sizes.fontPixelSize * 1.5

    color: EaStyle.Colors.mainContentBackground

    Column {
        id: container

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        anchors.topMargin: page.commonSpacing
        anchors.leftMargin: page.commonSpacing * 1.5
        anchors.rightMargin: page.commonSpacing * 1.5

        spacing: page.commonSpacing

        // Project title
        EaElements.TextInput {
            width: Math.max(implicitWidth, 1)
            font.family: EaStyle.Fonts.secondFontFamily
            font.pixelSize: EaStyle.Sizes.fontPixelSize * 3
            font.weight: Font.ExtraLight
            validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z][a-zA-Z0-9_\-\.]{1,30}$/ }
            placeholderText: qsTr("Enter project name here")
            text: Globals.BackendWrapper.projectName
            onEditingFinished: Globals.BackendWrapper.projectSetName(text)
        }
        // Project title

        // Project info
        Grid {
            columns: 2
            rowSpacing: 0
            columnSpacing: page.commonSpacing

            EaElements.Label {
                font.bold: true
                text: qsTr('Description:')
            }
            EaElements.TextInput {
                width: Math.max(implicitWidth, 1)
                placeholderText: qsTr("Enter project description here")
                text: Globals.BackendWrapper.projectDescription
                onEditingFinished: Globals.BackendWrapper.projectSetDescription(text)
            }

            EaElements.Label {
                font.bold: true
                text: qsTr('Location:')
            }
            EaElements.Label {
                id: locationLabel
                // Long paths lose their start, so the project folder stays visible
                width: Math.min(implicitWidth, container.width - x)
                elide: Text.ElideLeft
                text: Globals.BackendWrapper.projectPath

                HoverHandler { id: locationHover }
                EaElements.ToolTip {
                    text: locationLabel.text
                    visible: locationLabel.truncated && locationHover.hovered && EaGlobals.Vars.showToolTips
                }
            }

            EaElements.Label {
                font.bold: true
                text: qsTr('Last saved:')
            }
            EaElements.Label {
                width: Math.max(implicitWidth, 1)
                text: Globals.BackendWrapper.projectModified
            }
        }
        // Project info

        // Project image
        Image {
            width: EaStyle.Sizes.fontPixelSize * 25
            fillMode: Image.PreserveAspectFit
        }
        // Project image

    }

}
