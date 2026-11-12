// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Globals as EaGlobals
import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui as Gui
import Gui.Globals as Globals

EaComponents.ApplicationWindow {

    title: Globals.ApplicationInfo.about.name

    ///////////////////
    // APPLICATION BAR
    ///////////////////

    // Left group of application bar tool buttons
    appBarLeftButtons: [

        EaElements.ToolButton {
            // The library refuses while a run writes the session's files
            enabled: Globals.BackendWrapper.projectCreated
                     && !Globals.BackendWrapper.runLocked
            highlighted: true
            fontIcon: 'save'
            ToolTip.text: qsTr('Save current state of the project')
            onClicked: Globals.BackendWrapper.projectSave()
        }

    ]

    // Right group of application bar tool buttons
    appBarRightButtons: [

        EaElements.ToolButton {
            fontIcon: 'cog'
            ToolTip.text: qsTr('Application preferences')
            onClicked: EaGlobals.Vars.showAppPreferencesDialog = true
        }

    ]

    // Central group of application bar page buttons (workflow tabs)
    // Page buttons for the pages described below
    appBarCentralTabs.contentData: [

        // Home page
        EaElements.AppBarTabButton {
            id: homeButton
            fontIcon: 'home'
            text: qsTr('Home')
            ToolTip.text: qsTr('Home')
            Component.onCompleted: {
                Globals.References.applicationWindow.appBarCentralTabs.homeButton = homeButton
            }
        },
        // Home page

        // Project page
        // Home's Start sets opened, which then stays. Off while a run goes
        // on: every Create, Open, Recent and Examples is on this page
        EaElements.AppBarTabButton {
            id: projectButton
            property bool opened: false
            enabled: opened && !Globals.BackendWrapper.runLocked
            fontIcon: 'archive'
            text: qsTr('Project')
            ToolTip.text: qsTr('Project description page')
            Component.onCompleted: {
                Globals.References.applicationWindow.appBarCentralTabs.projectButton = projectButton
            }
        },
        // Project page

        // Sample model page
        // Open at once for a loaded project; Continue sets enabled = true,
        // which then stays
        EaElements.AppBarTabButton {
            id: sampleModelButton
            enabled: Globals.BackendWrapper.projectLoaded
            fontIcon: 'vial' // 'layer-group'  'vials' 'vial'
            text: qsTr('Sample Model') // qsTr('Model')
            ToolTip.text: qsTr('Sample Model definition page')
            Component.onCompleted: {
                Globals.References.applicationWindow.appBarCentralTabs.sampleModelButton = sampleModelButton
            }
        },
        // Sample model page


        // Analysis page
        // As the Sample Model tab
        EaElements.AppBarTabButton {
            id: analysisButton
            enabled: Globals.BackendWrapper.projectLoaded
            fontIcon: 'microscope'
            text: qsTr('Analysis')
            ToolTip.text: qsTr('Calculation and fitting page')
            Component.onCompleted: {
                Globals.References.applicationWindow.appBarCentralTabs.analysisButton = analysisButton
            }
        },
        // Analysis page

        // Summary page
        EaElements.AppBarTabButton {
            id: summaryButton
            enabled: Globals.BackendWrapper.projectCreated
            fontIcon: 'clipboard-list'
            text: qsTr('Summary')
            ToolTip.text: qsTr('Summary of the work done')
            Component.onCompleted: {
                Globals.References.applicationWindow.appBarCentralTabs.summaryButton = summaryButton
            }
        }
        // Summary page

    ]

    //////////////////////////////////
    // APP PAGES (MAIN AREA + SIDEBAR)
    //////////////////////////////////

    // Pages for the tab buttons described above
    contentArea: [
        Loader { source: 'Pages/Home/Content.qml' },
        Loader { source: 'Pages/Project/Layout.qml' },
        Loader { source: 'Pages/SampleModel/Layout.qml' },
        Loader { source: 'Pages/Analysis/Layout.qml' },
        Loader { source: 'Pages/Report/Layout.qml' }
    ]

    /////////////
    // STATUS BAR
    /////////////

    statusBar: Gui.StatusBar {}

    ///////
    // MISC
    ///////

    // Ctrl+S (Cmd+S on macOS) does what the Save button does, on any page
    Shortcut {
        sequences: [StandardKey.Save]
        enabled: Globals.BackendWrapper.projectCreated
                 && !Globals.BackendWrapper.runLocked
        onActivated: {
            // A field still being edited sends its value when it loses focus
            contentItem.forceActiveFocus()
            Globals.BackendWrapper.projectSave()
        }
    }

    // A disabled tab gets no hover, and the tab bar makes each of its
    // children a tab: this area joins the Project tab's parent from out
    // here and says why the tab is off. No clicks
    MouseArea {
        parent: projectButton.parent
        x: projectButton.x
        y: projectButton.y
        width: projectButton.width
        height: projectButton.height
        visible: projectButton.opened && Globals.BackendWrapper.runLocked
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        EaElements.ToolTip {
            text: qsTr("Wait for the run to end, or cancel it")
            visible: parent.containsMouse && EaGlobals.Vars.showToolTips
        }
    }

    // Any uncaught exception from Python (Backends/real_py/error.py)
    EaElements.Dialog {
        id: errorDialog

        readonly property string message: Globals.BackendWrapper.errorMessage

        title: qsTr('Error')
        standardButtons: Dialog.Ok
        modal: true

        onMessageChanged: if (message) open()
        onClosed: Globals.BackendWrapper.errorSetMessage('')

        // In a Column: a bare item under a titled dialog loops its
        // implicitWidth whenever the message changes
        Column {
            // A Label can't be selected: a read-only TextEdit can, for
            // copying the message
            TextEdit {
                text: errorDialog.message
                readOnly: true
                selectByMouse: true
                font.family: EaStyle.Fonts.fontFamily
                font.pixelSize: EaStyle.Sizes.fontPixelSize
                color: EaStyle.Colors.themeForeground
                selectionColor: EaStyle.Colors.themeAccent
                selectedTextColor: EaStyle.Colors.themeBackground
            }
        }
    }

    onClosing: Qt.quit()

    Component.onCompleted: console.debug(`Application window loaded ::: ${this}`)
    Component.onDestruction: console.debug(`Application window destroyed ::: ${this}`)

}
