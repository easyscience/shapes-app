// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Backend for the "Library assets" editor (Advanced sidebar). Holds a single
// draft the user either creates from scratch or loads from the library, edits,
// and saves back. Most types are file-bearing assets (Lipid/Surfactant/
// Component/Ion/Solvent). 'Salt' is the odd one out: it is NOT an asset but a
// named collection of ion assets with stoichiometric counts, so for that type
// the file list is replaced by a two-ion composition.
//
// Instantiation of the typed asset is deferred to save() — while editing we
// keep plain draft fields, so switching the type dropdown never leaves a
// half-built typed object.
QtObject {
    id: root

    // Editor mode:
    //   'create' — new draft; type dropdown editable. This is the default, so
    //              the editor opens ready to compose a new asset.
    //   'edit'   — loaded/saved; type locked (storage is keyed on type).
    //   'empty'  — reserved; not entered by default.
    property string mode: 'create'

    // Type options shown in the dropdown. 'Component (Other)' maps to the
    // Component class; 'Salt' is a collection, not a class.
    readonly property var typeOptions: ['Lipid', 'Surfactant', 'Component (Other)', 'Ion', 'Solvent', 'Salt']

    // Draft fields. assetType is a display label from typeOptions. The
    // component-only fields (cIon/mint/mext) stay at their defaults for the
    // Ion/Solvent/Salt types, where the UI hides them. Defaults to a molecule
    // so the editor opens on a typical new-asset form.
    property string assetType: 'Lipid'
    property string assetName: ''
    property string cIon: ''
    property int mint: 0
    property int mext: 0

    // Draft file list (composition of a file-bearing asset). Roles: path, size.
    // `size` is a fake label — the mock never touches the disk; files the user
    // adds get one from `fakeSizes` in order. The real backend stats the file.
    readonly property var paths: ListModel { id: pathsModel }

    readonly property var fakeSizes: ['58 kB', '2.3 MB', '640 kB', '5.1 MB', '11.2 MB']
    property int fakeSizeIndex: 0

    // Draft salt composition (used only when assetType === 'Salt'). Two fixed
    // ion slots. Roles: ion (library ion name, or '' when unset), count (>=1).
    readonly property var saltComposition: ListModel {
        id: saltCompositionModel
        ListElement { ion: ''; count: 1 }
        ListElement { ion: ''; count: 1 }
    }

    // True when a Salt draft can be saved: a name plus both ion slots filled.
    property bool saltReady: false

    // Mock asset library browsed by the Load-from-lib popup. A mix of kinds so
    // the browser shows more than components. Roles uniform across rows so the
    // statically-typed ListModel keeps every column: file-bearing assets leave
    // the ion0/ion1 slots blank; salts leave c_ion/mint/mext at defaults.
    // Saving upserts here by (type, name).
    readonly property var library: ListModel {
        id: libraryModel
        ListElement { name: 'DPPC';        type: 'Lipid';             c_ion: '';                 mint: 0; mext: 130; ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'DOPC';        type: 'Lipid';             c_ion: '';                 mint: 0; mext: 138; ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'POPC';        type: 'Lipid';             c_ion: '';                 mint: 0; mext: 134; ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'Cholesterol'; type: 'Lipid';             c_ion: '';                 mint: 0; mext: 74;  ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'SDS';         type: 'Surfactant';        c_ion: 'Na<sup>+</sup>';   mint: 0; mext: 42;  ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'CTAB';        type: 'Surfactant';        c_ion: 'Br<sup>-</sup>';   mint: 0; mext: 62;  ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'Triton-X100'; type: 'Surfactant';        c_ion: '';                 mint: 0; mext: 85;  ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'D2O-buffer';  type: 'Component (Other)';  c_ion: '';                 mint: 0; mext: 3;   ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'Na';          type: 'Ion';               c_ion: '';                 mint: 0; mext: 0;   ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'Cl';          type: 'Ion';               c_ion: '';                 mint: 0; mext: 0;   ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'TIP3';        type: 'Solvent';           c_ion: '';                 mint: 0; mext: 0;   ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'Ethanol';     type: 'Solvent';           c_ion: '';                 mint: 0; mext: 0;   ion0: ''; count0: 0; ion1: ''; count1: 0 }
        ListElement { name: 'NaCl';        type: 'Salt';              c_ion: '';                 mint: 0; mext: 0;   ion0: 'Na<sup>+</sup>';  count0: 1; ion1: 'Cl<sup>-</sup>'; count1: 1 }
        ListElement { name: 'CaCl2';       type: 'Salt';              c_ion: '';                 mint: 0; mext: 0;   ion0: 'Ca<sup>2+</sup>'; count0: 1; ion1: 'Cl<sup>-</sup>'; count1: 2 }
    }

    onAssetNameChanged: _recomputeSalt()

    // Start a fresh, unsaved draft. Type is editable; default to a molecule so
    // the component fields are visible to begin with.
    function createNew() {
        mode = 'create'
        assetType = 'Lipid'
        assetName = ''
        cIon = ''
        mint = 0
        mext = 0
        pathsModel.clear()
        _clearSalt()
    }

    // Adopt a library record into the draft for editing. Type is locked.
    function loadAsset(item) {
        mode = 'edit'
        assetType = item.type
        assetName = item.name
        cIon = item.c_ion !== undefined ? item.c_ion : ''
        mint = item.mint !== undefined ? item.mint : 0
        mext = item.mext !== undefined ? item.mext : 0
        pathsModel.clear()
        if (item.type === 'Salt') {
            saltCompositionModel.setProperty(0, 'ion', item.ion0)
            saltCompositionModel.setProperty(0, 'count', item.count0)
            saltCompositionModel.setProperty(1, 'ion', item.ion1)
            saltCompositionModel.setProperty(1, 'count', item.count1)
        } else {
            _clearSalt()
            // Mock: stand-in files for the loaded asset, with fake sizes.
            pathsModel.append({ path: 'assets/' + item.name + '.itp', size: '47 kB' })
            pathsModel.append({ path: 'assets/' + item.name + '.gro', size: '2.5 MB' })
        }
        _recomputeSalt()
    }

    function appendPath(path) {
        pathsModel.append({ path: path, size: nextFakeSize() })
    }

    function nextFakeSize() {
        const label = fakeSizes[fakeSizeIndex % fakeSizes.length]
        fakeSizeIndex = fakeSizeIndex + 1
        return label
    }

    function removePath(index) {
        if (index < 0 || index >= pathsModel.count) return
        pathsModel.remove(index)
    }

    function editPath(index) {
        if (index < 0 || index >= pathsModel.count) return
        console.debug('LibraryAssetsEditor.editPath:', pathsModel.get(index).path)
    }

    // Export a single file of the draft asset. Mock placeholder — the real
    // backend will copy the file to a chosen location.
    function exportPath(index) {
        if (index < 0 || index >= pathsModel.count) return
        console.debug('LibraryAssetsEditor.exportPath:', pathsModel.get(index).path)
    }

    function setSaltIon(index, value) {
        if (index < 0 || index >= saltCompositionModel.count) return
        saltCompositionModel.setProperty(index, 'ion', value)
        _recomputeSalt()
    }

    function setSaltCount(index, value) {
        if (index < 0 || index >= saltCompositionModel.count) return
        saltCompositionModel.setProperty(index, 'count', value)
    }

    // Instantiate (conceptually) the typed asset / salt from the draft and
    // persist it to the library. Mock upserts by (type, name) and flips to edit
    // mode so the type locks. Returns false if the draft is incomplete.
    function save() {
        const name = (assetName || '').trim()
        if (name === '') return false
        let record
        if (assetType === 'Salt') {
            if (!saltReady) return false
            const r0 = saltCompositionModel.get(0)
            const r1 = saltCompositionModel.get(1)
            record = { name: name, type: assetType, c_ion: '', mint: 0, mext: 0,
                       ion0: r0.ion, count0: r0.count, ion1: r1.ion, count1: r1.count }
        } else {
            if (pathsModel.count === 0) return false
            record = { name: name, type: assetType, c_ion: cIon, mint: mint, mext: mext,
                       ion0: '', count0: 0, ion1: '', count1: 0 }
        }
        for (let i = 0; i < libraryModel.count; ++i) {
            const r = libraryModel.get(i)
            if (r.type === assetType && r.name === name) {
                libraryModel.set(i, record)
                mode = 'edit'
                console.debug('LibraryAssetsEditor.save (overwrite):', assetType, name)
                return true
            }
        }
        libraryModel.append(record)
        mode = 'edit'
        console.debug('LibraryAssetsEditor.save (new):', assetType, name)
        return true
    }

    function exportAsset() {
        console.debug('LibraryAssetsEditor.exportAsset:', assetType, assetName)
    }

    function _clearSalt() {
        saltCompositionModel.setProperty(0, 'ion', '')
        saltCompositionModel.setProperty(0, 'count', 1)
        saltCompositionModel.setProperty(1, 'ion', '')
        saltCompositionModel.setProperty(1, 'count', 1)
    }

    function _recomputeSalt() {
        const r0 = saltCompositionModel.get(0)
        const r1 = saltCompositionModel.get(1)
        saltReady = (assetName || '').trim() !== '' && !!r0.ion && !!r1.ion
    }
}
