// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtQuick.Controls

import EasyApplication.Gui.Style as EaStyle
import EasyApplication.Gui.Elements as EaElements
import EasyApplication.Gui.Components as EaComponents

import Gui.Globals as Globals


EaElements.GroupColumn {

    EaComponents.ListView {
        id: positionRestraintsList
        defaultInfoText: qsTr('No position restraints defined')
        multiSelection: false

        columnWidths: [
            -1,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.fontPixelSize * 4,
            EaStyle.Sizes.fontPixelSize * 5,
            EaStyle.Sizes.fontPixelSize * 8
        ]

        header: EaComponents.ListViewHeader {
            EaComponents.TableViewLabel {
                text: qsTr('Component')
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr('Atom')
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr('P. form')
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr('Geom.')
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr('Radius')
                color: EaStyle.Colors.themeForegroundMinor
            }
            EaComponents.TableViewLabel {
                text: qsTr('F. constant')
                color: EaStyle.Colors.themeForegroundMinor
            }
        }

        model: Globals.BackendWrapper.positionRestraintsItems

        delegateModelAccess: DelegateModel.ReadWrite

        delegate: EaComponents.ListViewDelegate {
            required property int index
            required property string component_name
            required property int atom
            required property int p_form
            required property int geom
            required property double radius
            required property string f_constant

            EaComponents.TableViewLabel {
                text: component_name
            }
            EaComponents.ListViewTextInput {
                text: atom
                validator: IntValidator { bottom: 0 }
                onEditingFinished: Globals.BackendWrapper.positionRestraintsSetAtom(index, parseInt(text))
            }
            EaComponents.ListViewTextInput {
                text: p_form
                validator: IntValidator { bottom: 0 }
                onEditingFinished: Globals.BackendWrapper.positionRestraintsSetPForm(index, parseInt(text))
            }
            EaComponents.ListViewTextInput {
                text: geom
                validator: IntValidator { bottom: 0 }
                onEditingFinished: Globals.BackendWrapper.positionRestraintsSetGeom(index, parseInt(text))
            }
            EaComponents.ListViewTextInput {
                text: radius
                validator: DoubleValidator { bottom: 0 }
                onEditingFinished: Globals.BackendWrapper.positionRestraintsSetRadius(index, parseFloat(text))
            }
            EaComponents.TableViewLabel {
                text: f_constant
                enabled: false
            }
        }
    }
}
