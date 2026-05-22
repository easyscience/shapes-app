// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Pattern D backend (multi-row list with selection) for position restraints
// shown in the Advanced sidebar of the Sample Model page.
//
// Rows are derived from the shared Components list: one restraint row per
// loaded component, with the component name mirrored read-only and the
// atom / p_form / geom / radius / f_constant fields owned here. Sync is
// surgical so editing one component doesn't reset the others' state.
//
// Roles: component_name, atom, p_form, geom, radius, f_constant.
QtObject {
    id: root

    // Shared component list this mirrors. Wired by MockBackend at startup;
    // kept as a property (rather than a hard import) to side-step singleton
    // init-order quirks — same approach as Layers/Lamellae fractionsSource.
    property var source: null

    readonly property var items: ListModel { id: itemsModel }

    onSourceChanged: rebuild()

    property var __sync: Connections {
        target: root.source

        function onRowsInserted(parent, first, last) {
            for (let i = first; i <= last; ++i) {
                const c = root.source.get(i)
                itemsModel.insert(i, {
                    component_name: c.name,
                    atom: 1,
                    p_form: 1,
                    geom: 1,
                    radius: 0.5,
                    f_constant: 'POSRES_FC_LIP'
                })
            }
        }
        function onRowsRemoved(parent, first, last) {
            for (let i = last; i >= first; --i) itemsModel.remove(i)
        }
        function onDataChanged(topLeft, bottomRight, roles) {
            for (let i = topLeft.row; i <= bottomRight.row; ++i) {
                itemsModel.setProperty(i, 'component_name', root.source.get(i).name)
            }
        }
        function onModelReset() { root.rebuild() }
    }

    function rebuild() {
        itemsModel.clear()
        if (!source) return
        for (let i = 0; i < source.count; ++i) {
            const c = source.get(i)
            itemsModel.append({
                component_name: c.name,
                atom: 1,
                p_form: 1,
                geom: 1,
                radius: 0.5,
                f_constant: 'POSRES_FC_LIP'
            })
        }
    }

    function setAtom(index, value) {
        if (index < 0 || index >= itemsModel.count) return
        itemsModel.setProperty(index, 'atom', value)
    }

    function setPForm(index, value) {
        if (index < 0 || index >= itemsModel.count) return
        itemsModel.setProperty(index, 'p_form', value)
    }

    function setGeom(index, value) {
        if (index < 0 || index >= itemsModel.count) return
        itemsModel.setProperty(index, 'geom', value)
    }

    function setRadius(index, value) {
        if (index < 0 || index >= itemsModel.count) return
        itemsModel.setProperty(index, 'radius', value)
    }
}
