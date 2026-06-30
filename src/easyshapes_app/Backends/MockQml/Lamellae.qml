// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Pattern D backend (multi-row list with selection) for lamellae, plus
// parallel arrays of per-lamella Fractions instances. Each lamella owns
// distinct inner and outer leaflet fractions so asymmetric lamellae can
// diverge without leaking state between leaflets.
QtObject {
    id: root

    // Source of components shared with every leaflet's Fractions instance.
    // Each leaflet keeps its own per-instance fracs/present state but
    // mirrors the same component name list.
    property var fractionsSource: null

    // Table of lamellae. Roles: rmin, innerDmin, outerDmin, shell, symmetric.
    readonly property var items: ListModel {
        id: lamellaeModel
        ListElement { rmin: 0.5; innerDmin: 0.25; outerDmin: 0.3; shell: 1.0; symmetric: true }
    }

    // Parallel arrays of Fractions QtObjects, one inner and one outer
    // leaflet instance per lamella.
    property var innerFractionsInstances: []
    property var outerFractionsInstances: []
    property int itemsRevision: 0
    property int fractionsRevision: 0

    property var __fractionsComponent: null

    Component.onCompleted: {
        __fractionsComponent = Qt.createComponent(Qt.resolvedUrl("Fractions.qml"))
        if (__fractionsComponent.status !== Component.Ready) {
            console.warn("Lamellae: failed to load Fractions.qml:", __fractionsComponent.errorString())
            return
        }
        const inner = []
        const outer = []
        for (let i = 0; i < lamellaeModel.count; ++i) {
            inner.push(__createFractions())
            outer.push(__createFractions())
        }
        innerFractionsInstances = inner
        outerFractionsInstances = outer
        itemsRevision++
        fractionsRevision++
    }

    function __createFractions() {
        // Bind (don't snapshot) so per-instance Fractions follow later
        // assignments to root.fractionsSource — singleton init order is
        // not deterministic, so the source may be set after this runs.
        const f = __fractionsComponent.createObject(root)
        f.source = Qt.binding(function() { return root.fractionsSource })
        return f
    }

    function appendItem(item) {
        lamellaeModel.append({
            rmin: item.rmin,
            innerDmin: item.innerDmin,
            outerDmin: item.outerDmin,
            shell: item.shell,
            symmetric: item.symmetric
        })

        const inner = innerFractionsInstances.slice()
        const outer = outerFractionsInstances.slice()
        inner.push(__createFractions())
        outer.push(__createFractions())
        innerFractionsInstances = inner
        outerFractionsInstances = outer
        itemsRevision++
        fractionsRevision++
    }

    function removeItem(index) {
        if (index < 0 || index >= lamellaeModel.count) return
        lamellaeModel.remove(index)

        const inner = innerFractionsInstances.slice()
        const outer = outerFractionsInstances.slice()
        const removedInner = inner.splice(index, 1)[0]
        const removedOuter = outer.splice(index, 1)[0]
        if (removedInner) removedInner.destroy()
        if (removedOuter) removedOuter.destroy()
        innerFractionsInstances = inner
        outerFractionsInstances = outer
        itemsRevision++
        fractionsRevision++
    }

    function setRmin(index, value) {
        if (index < 0 || index >= lamellaeModel.count) return
        lamellaeModel.setProperty(index, 'rmin', value)
    }

    function setInnerDmin(index, value) {
        if (index < 0 || index >= lamellaeModel.count) return
        lamellaeModel.setProperty(index, 'innerDmin', value)
    }

    function setOuterDmin(index, value) {
        if (index < 0 || index >= lamellaeModel.count) return
        lamellaeModel.setProperty(index, 'outerDmin', value)
    }

    function setShell(index, value) {
        if (index < 0 || index >= lamellaeModel.count) return
        lamellaeModel.setProperty(index, 'shell', value)
    }

    function setSymmetric(index, value) {
        if (index < 0 || index >= lamellaeModel.count) return
        lamellaeModel.setProperty(index, 'symmetric', value)
        itemsRevision++
    }

    function innerFractionsModelAt(index) {
        if (index < 0 || index >= innerFractionsInstances.length) return null
        const f = innerFractionsInstances[index]
        return f ? f.model : null
    }

    function outerFractionsModelAt(index) {
        if (index < 0 || index >= outerFractionsInstances.length) return null
        const f = outerFractionsInstances[index]
        return f ? f.model : null
    }
}
