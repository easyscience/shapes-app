// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls
import QtCore

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents
import EasyApplication.Gui.Logic as EaLogic

import Gui.Globals as Globals


EaComponents.TableView {

    id: tableView

    showHeader: false
    tallRows: true
    maxRowCountShow: 6

    defaultInfoText: qsTr('No recent projects found')

    model: Globals.BackendWrapper.libraryAvailableProjects

    // header
    header: EaComponents.TableViewHeader {
        EaComponents.TableViewLabel {
            enabled: false
            width: EaStyle.Sizes.fontPixelSize * 2.5
        }

        EaComponents.TableViewLabel {
            flexibleWidth: true
            horizontalAlignment: Text.AlignLeft
            text: qsTr('name / last saved')
        }
    }
    // header

    // delegate
    delegate: EaComponents.TableViewDelegate {
        mouseArea.onPressed: Globals.BackendWrapper.projectLoad(tableView.model[index].path)

        EaComponents.TableViewLabel {
            text: index + 1
            color: EaStyle.Colors.themeForegroundMinor
        }

        EaComponents.TableViewTwoRowsAdvancedLabel {
            fontIcon: 'archive'
            text: tableView.model[index].name
            minorText: tableView.model[index].modified
            ToolTip.text: tableView.model[index].path
        }
    }
    // delegate

}
