// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick


// Mirrors Backend.libraryAssets: the Library assets editor's draft, which
// the user creates or loads from the library, edits and saves back. Only
// the fields are kept while editing; Python builds the typed asset on save
// and export, so changing the type never leaves a half-built one. A salt
// has no files of its own: its two ion rows replace the file list.
QtObject {
    id: root

    // 'create' while the draft is new; 'edit' once loaded or saved, which
    // locks the type
    property string mode: 'create'

    // The library's class names for the asset types
    readonly property var typeOptions: ['Lipid', 'Surfactant', 'Component', 'Ion', 'Solvent', 'Salt']

    // Draft fields. counterIon, mint and mext belong to Lipid, Surfactant
    // and Component; the page hides them for the other types
    property string assetType: 'Lipid'
    property string assetName: ''
    property string counterIon: ''
    property int mint: 0
    property int mext: 0

    // The draft's files. Roles: path, size. A size is a fake label: the mock
    // never touches the disk; added files take one from fakeSizes in turn
    readonly property var paths: ListModel { id: pathsModel }

    readonly property var fakeSizes: ['58 kB', '2.3 MB', '640 kB', '5.1 MB', '11.2 MB']
    property int fakeSizeIndex: 0

    // The salt's ions: row 0 the cation, row 1 the anion. Roles: ion (a
    // library ion name, '' while unset), count. The page writes the roles
    readonly property var saltComposition: ListModel {
        id: saltCompositionModel
        ListElement { ion: ''; count: 1 }
        ListElement { ion: ''; count: 1 }

        onDataChanged: root._recomputeSalt()
    }

    // True when a salt can be saved: a name and both ions
    property bool saltReady: false

    // Mock only: the mock Library, set by MockBackend. A save adds to its
    // index, as a library save does
    property var library: null

    // Mock only: 'Type/name' of the library entry the draft holds, '' for
    // a new draft
    property string _loaded: ''

    // Mock only: the fields of each asset saved this session, by
    // 'Type/name', so loading it back shows them. Other assets load with
    // stand-in values
    property var _saved: ({})

    onAssetNameChanged: _recomputeSalt()

    function createNew() {
        mode = 'create'
        assetType = 'Lipid'
        assetName = ''
        counterIon = ''
        mint = 0
        mext = 0
        pathsModel.clear()
        _setSalt([['', 1], ['', 1]])
        _loaded = ''
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

    function load(type, name) {
        const key = type + '/' + name
        const record = _saved[key] ?? {
            counterIon: '',
            mint: 0,
            mext: 0,
            // Stand-in files and ions
            files: type === 'Salt' ? [] : [
                { path: 'assets/' + name + '.itp', size: '47 kB' },
                { path: 'assets/' + name + '.gro', size: '2.5 MB' }
            ],
            salt: type === 'Salt'
                  ? [[library.availableIons[0], 1], [library.availableIons[1], 1]]
                  : [['', 1], ['', 1]]
        }
        mode = 'edit'
        assetType = type
        assetName = name
        counterIon = record.counterIon
        mint = record.mint
        mext = record.mext
        pathsModel.clear()
        for (const file of record.files)
            pathsModel.append(file)
        _setSalt(record.salt)
        _loaded = key
    }

    // Another entry's name: saving the loaded one back is a regular save
    function nameTaken() {
        return assetType + '/' + assetName !== _loaded
               && (library.availableAssets[assetType] ?? []).includes(assetName)
    }

    function save(overwrite) {
        const key = assetType + '/' + assetName
        const files = []
        for (let i = 0; i < pathsModel.count; ++i) {
            const row = pathsModel.get(i)
            files.push({ path: row.path, size: row.size })
        }
        const salt = [0, 1].map(i => [saltCompositionModel.get(i).ion, saltCompositionModel.get(i).count])
        _saved = Object.assign({}, _saved, { [key]: { counterIon, mint, mext, files, salt } })
        library.addAsset(assetType, assetName)
        _loaded = key
        mode = 'edit'
        console.debug('LibraryAssetsEditor.save:', key, 'overwrite:', overwrite)
    }

    // The mock has no file system: a folder ending in 'taken' counts as
    // taken, as in Project.locationTaken
    function exportTaken(folder, row) {
        return folder.endsWith('taken')
    }

    // Row -1 exports the whole asset, a row that one file
    function exportTo(folder, row, overwrite) {
        console.debug('LibraryAssetsEditor.exportTo:', assetType, assetName, 'row:', row,
                      '->', folder, 'overwrite:', overwrite)
    }

    function _setSalt(rows) {
        for (let i = 0; i < 2; ++i)
            saltCompositionModel.set(i, { ion: rows[i][0], count: rows[i][1] })
    }

    function _recomputeSalt() {
        saltReady = assetName !== ''
                    && saltCompositionModel.get(0).ion !== ''
                    && saltCompositionModel.get(1).ion !== ''
    }
}
