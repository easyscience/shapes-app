// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick


// Mirrors the residue list of Python's StructureInstancing: one row per
// residue name in the file shown, whose atoms are drawn while it is
// shown. Roles: name, count (its atoms), shown. Instantiable, NOT a
// singleton: each viewer's instancing holds one. The mock's micelle
// table carries no residues, so a row unticked hides nothing here.
ListModel {
    id: root

    // Rows ticked, for the header's box: all, none or some
    property int shownCount: 0

    function setAllShown(shown) {
        for (let i = 0; i < count; ++i)
            setProperty(i, 'shown', shown)
    }

    function _recount() {
        let shown = 0
        for (let i = 0; i < count; ++i)
            if (get(i).shown)
                shown += 1
        shownCount = shown
    }

    onDataChanged: _recount()
    onCountChanged: _recount()

    // Fake counts, for layout work
    Component.onCompleted: {
        append({ name: 'SDS', count: 2520, shown: true })
        append({ name: 'SOD', count: 60, shown: true })
        append({ name: 'TIP3', count: 45000, shown: true })
    }
}
