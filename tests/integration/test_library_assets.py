# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project.species import Ion

from easyshapes_app.Backends.real_py.library import Library
from easyshapes_app.Backends.real_py.library_assets import LibraryAssets
from easyshapes_app.Backends.real_py.library_assets import SaltCompositionModel


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_salt_made_in_the_editor_joins_the_catalog_and_loads_back(qcore_application):
    # The ions it is made of, in the offline library
    Ion(name='NAT').save()
    Ion(name='CLA').save()
    editor = LibraryAssets()
    editor.assetType = 'Salt'
    editor.assetName = 'NaCl'
    salt = editor.saltComposition
    salt.setData(salt.index(0), 'NAT', SaltCompositionModel.IonRole)
    salt.setData(salt.index(1), 'CLA', SaltCompositionModel.IonRole)
    assert not editor.nameTaken()

    editor.save(False)
    editor.createNew()
    editor.load('Salt', 'NaCl')

    assert Library().availableSalts == ['NaCl']
    assert editor.saltComposition.rows == (('NAT', 1), ('CLA', 1))


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_lipid_saved_over_a_taken_name_replaces_the_entry(qcore_application, tmp_path):
    Ion(name='CLA').save()
    itp = tmp_path / 'DPPC.itp'
    itp.write_text('[ moleculetype ]\n')
    gro = tmp_path / 'DPPC.gro'
    gro.write_text('DPPC\n0\n   1.0 1.0 1.0\n')
    editor = LibraryAssets()
    editor.assetName = 'DPPC'
    editor.counterIon = 'CLA'
    editor.mext = 130
    editor.appendPath(str(itp))
    editor.appendPath(str(gro))
    editor.save(False)

    # A new draft under the same name asks, then replaces the entry
    editor.createNew()
    editor.assetName = 'DPPC'
    editor.appendPath(str(itp))
    assert editor.nameTaken()
    editor.save(True)
    editor.load('Lipid', 'DPPC')

    assert [path.name for path in editor.paths.paths] == ['DPPC.itp']
    assert (editor.counterIon, editor.mext) == ('', 0)
    # Loaded from the library's copy, not the picked file
    assert editor.paths.paths[0] != itp


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_export_asks_about_a_taken_folder_and_replaces_its_export(qcore_application, tmp_path):
    itp = tmp_path / 'NAT.itp'
    itp.write_text('[ moleculetype ]\n')
    editor = LibraryAssets()
    editor.assetType = 'Ion'
    editor.assetName = 'NAT'
    editor.appendPath(str(itp))
    folder = tmp_path / 'export'

    assert not editor.exportTaken(str(folder), -1)
    editor.exportTo(str(folder), -1, False)
    assert editor.exportTaken(str(folder), -1)
    editor.exportTo(str(folder), -1, True)

    assert (folder / 'NAT.itp').read_text() == '[ moleculetype ]\n'
    # The record import_from reads the asset back from
    assert Ion.import_from(folder).name == 'NAT'
