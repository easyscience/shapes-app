# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path
from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.library_assets import FilesModel
from easyshapes_app.Backends.real_py.library_assets import LibraryAssets
from easyshapes_app.Backends.real_py.library_assets import SaltCompositionModel

pytestmark = pytest.mark.usefixtures('qcore_application')


def test_rows_read_the_path_and_the_size_on_disk(tmp_path):
    itp = tmp_path / 'DPPC.itp'
    itp.write_bytes(bytes(47104))
    gro = tmp_path / 'DPPC.gro'
    gro.write_bytes(bytes(512))
    gone = tmp_path / 'DPPC.pdb'
    model = FilesModel()
    model.reset([itp, gro, gone])

    assert model.count == 3
    assert [
        (
            model.data(model.index(row), FilesModel.PathRole),
            model.data(model.index(row), FilesModel.SizeRole),
        )
        for row in range(model.count)
    ] == [(str(itp), '47.1 kB'), (str(gro), '512 bytes'), (str(gone), '')]


def test_append_adds_a_row():
    model = FilesModel()
    inserted = QSignalSpy(model.rowsInserted)
    count = QSignalSpy(model.countChanged)

    model.append('C:/files/DPPC.itp')

    assert model.paths == (Path('C:/files/DPPC.itp'),)
    assert (inserted.count(), count.count()) == (1, 1)


def test_remove_drops_the_row():
    model = FilesModel()
    model.reset(['DPPC.itp', 'DPPC.gro'])
    removed = QSignalSpy(model.rowsRemoved)
    count = QSignalSpy(model.countChanged)

    model.remove(0)

    assert model.paths == (Path('DPPC.gro'),)
    assert (removed.count(), count.count()) == (1, 1)


def test_reset_replaces_every_row():
    model = FilesModel()
    model.append('DPPC.itp')
    reset = QSignalSpy(model.modelReset)
    count = QSignalSpy(model.countChanged)

    model.reset(['DOPC.itp', 'DOPC.gro'])

    assert model.paths == (Path('DOPC.itp'), Path('DOPC.gro'))
    assert (reset.count(), count.count()) == (1, 1)


def test_new_salt_rows_hold_no_ions_and_one_of_each():
    model = SaltCompositionModel()

    assert [
        (
            model.data(model.index(row), SaltCompositionModel.IonRole),
            model.data(model.index(row), SaltCompositionModel.CountRole),
        )
        for row in range(model.rowCount())
    ] == [('', 1), ('', 1)]


def test_salt_writes_set_the_ion_and_the_count_and_emit_only_on_change():
    model = SaltCompositionModel()
    spy = QSignalSpy(model.dataChanged)

    assert model.setData(model.index(0), 'NAT', SaltCompositionModel.IonRole)
    assert model.setData(model.index(0), 'NAT', SaltCompositionModel.IonRole)
    assert model.setData(model.index(1), 2, SaltCompositionModel.CountRole)

    assert model.rows == (('NAT', 1), ('', 2))
    assert spy.count() == 2


def test_salt_reset_fills_the_rows_and_empties_them_again():
    model = SaltCompositionModel()
    reset = QSignalSpy(model.modelReset)

    model.reset((('NAT', 1), ('CLA', 2)))
    assert model.rows == (('NAT', 1), ('CLA', 2))

    model.reset()
    assert model.rows == (('', 1), ('', 1))
    assert reset.count() == 2


def test_type_options_are_the_library_class_names():
    assert LibraryAssets().typeOptions == [
        'Lipid',
        'Surfactant',
        'Component',
        'Ion',
        'Solvent',
        'Salt',
    ]


@pytest.mark.parametrize(
    ('field', 'value'),
    [
        ('assetType', 'Salt'),
        ('assetName', 'NaCl'),
        ('counterIon', 'CLA'),
        ('mint', 2),
        ('mext', 130),
    ],
)
def test_draft_field_writes_emit_only_on_change(field, value):
    part = LibraryAssets()
    spy = QSignalSpy(getattr(part, f'{field}Changed'))

    setattr(part, field, value)
    setattr(part, field, value)

    assert getattr(part, field) == value
    assert spy.count() == 1


def test_salt_ready_needs_a_name_and_both_ions():
    part = LibraryAssets()
    salt = part.saltComposition
    spy = QSignalSpy(part.saltReadyChanged)

    salt.setData(salt.index(0), 'NAT', SaltCompositionModel.IonRole)
    salt.setData(salt.index(1), 'CLA', SaltCompositionModel.IonRole)
    assert not part.saltReady

    part.assetName = 'NaCl'
    assert part.saltReady
    assert spy.count() == 3


def test_create_new_empties_the_draft_and_emits_only_what_changed():
    part = LibraryAssets()
    part.assetName = 'DPPC'
    part.mint = 2
    part.appendPath('DPPC.itp')
    name = QSignalSpy(part.assetNameChanged)
    mint = QSignalSpy(part.mintChanged)
    asset_type = QSignalSpy(part.assetTypeChanged)
    mode = QSignalSpy(part.modeChanged)

    part.createNew()

    assert (part.assetName, part.mint, part.paths.count) == ('', 0, 0)
    assert (name.count(), mint.count(), asset_type.count(), mode.count()) == (1, 1, 0, 0)


class FakeAsset(SimpleNamespace):
    """
    Builds as the library classes do: keeps the fields it is given, an
    ion given by name loaded as a new object. Logs saves and exports in
    LOG.
    """

    LOG = []
    # Fields by name, as the library loads its saved entries
    SAVED = {
        'DPPC': {
            'name': 'DPPC',
            'paths': (Path('DPPC.itp'), Path('DPPC.gro')),
            'counter_ion': SimpleNamespace(name='CLA'),
            'mint': 2,
            'mext': 130,
        },
        'CaCl2': {
            'name': 'CaCl2',
            'paths': (),
            'cation': SimpleNamespace(name='CAL'),
            'cation_count': 1,
            'anion': SimpleNamespace(name='CLA'),
            'anion_count': 2,
        },
    }

    def __init__(self, **fields):
        for attr in ('counter_ion', 'cation', 'anion'):
            if isinstance(fields.get(attr), str):
                fields[attr] = SimpleNamespace(name=fields[attr])
        super().__init__(**fields)

    @classmethod
    def load(cls, name):
        return cls(**cls.SAVED[name])

    def save(self, *, overwrite=False):
        self.LOG.append(('save', self, overwrite))

    def export_to(self, folder, *, overwrite=False):
        self.LOG.append(('export_to', self, folder, overwrite))


class FakeLibrary:
    """
    Holds the DPPC lipid and the CaCl2 salt.
    """

    def has_entry(self, asset_type, name):
        return (asset_type, name) in {('Lipid', 'DPPC'), ('Salt', 'CaCl2')}


class OfflineLibraryAssets(LibraryAssets):
    """
    Builds FakeAssets for every type and checks names in FakeLibrary.
    """

    _types = dict.fromkeys(LibraryAssets._types, FakeAsset)
    _library_class = FakeLibrary


@pytest.fixture
def log():
    FakeAsset.LOG.clear()
    return FakeAsset.LOG


def test_load_fills_the_draft_and_locks_the_type():
    part = OfflineLibraryAssets()
    mode = QSignalSpy(part.modeChanged)

    part.load('Lipid', 'DPPC')

    assert (part.assetType, part.assetName, part.counterIon, part.mint, part.mext) == (
        'Lipid',
        'DPPC',
        'CLA',
        2,
        130,
    )
    assert part.paths.paths == (Path('DPPC.itp'), Path('DPPC.gro'))
    assert part.saltComposition.rows == (('', 1), ('', 1))
    assert (part.mode, mode.count()) == ('edit', 1)


def test_load_salt_fills_its_rows_and_empties_the_rest():
    part = OfflineLibraryAssets()
    part.mint = 2
    part.appendPath('DPPC.itp')

    part.load('Salt', 'CaCl2')

    assert part.saltComposition.rows == (('CAL', 1), ('CLA', 2))
    assert (part.counterIon, part.mint, part.paths.count) == ('', 0, 0)


def test_name_is_taken_by_another_entry_not_by_the_loaded_one():
    part = OfflineLibraryAssets()
    part.assetName = 'POPC'
    assert not part.nameTaken()

    part.assetName = 'DPPC'
    assert part.nameTaken()

    part.load('Lipid', 'DPPC')
    assert not part.nameTaken()


def test_save_builds_the_lipid_and_saves_it_back_without_asking(log):
    part = OfflineLibraryAssets()
    saved = QSignalSpy(part.externalAssetsChanged)
    part.assetName = 'POPC'
    part.counterIon = 'CLA'
    part.mext = 134
    part.appendPath('POPC.itp')

    part.save(False)
    part.save(False)

    built = FakeAsset(name='POPC', paths=(Path('POPC.itp'),), counter_ion='CLA', mint=0, mext=134)
    assert log == [('save', built, False), ('save', built, True)]
    assert (part.mode, saved.count()) == ('edit', 2)


def test_save_builds_a_salt_from_its_rows(log):
    part = OfflineLibraryAssets()
    part.assetType = 'Salt'
    part.assetName = 'CaCl2'
    salt = part.saltComposition
    salt.setData(salt.index(0), 'CAL', SaltCompositionModel.IonRole)
    salt.setData(salt.index(1), 'CLA', SaltCompositionModel.IonRole)
    salt.setData(salt.index(1), 2, SaltCompositionModel.CountRole)

    part.save(True)

    built = FakeAsset(name='CaCl2', cation='CAL', cation_count=1, anion='CLA', anion_count=2)
    assert log == [('save', built, True)]


def test_save_builds_an_ion_from_its_name_and_files_only(log):
    part = OfflineLibraryAssets()
    part.assetType = 'Ion'
    part.assetName = 'CAL'
    # Left from a lipid draft; an ion takes no counter ion
    part.counterIon = 'CLA'
    part.appendPath('CAL.itp')

    part.save(False)

    assert log == [('save', FakeAsset(name='CAL', paths=(Path('CAL.itp'),)), False)]


def test_builds_reuse_the_ions_of_the_last_build_or_the_load(log):
    part = OfflineLibraryAssets()
    part.assetName = 'POPC'
    part.counterIon = 'CLA'
    part.save(False)
    part.save(False)
    part.load('Lipid', 'DPPC')
    part.save(False)
    part.createNew()
    part.assetName = 'POPC'
    part.counterIon = 'CLA'
    part.save(True)

    first, second, loaded, fresh = (entry[1].counter_ion for entry in log)
    assert second is first
    assert loaded is FakeAsset.SAVED['DPPC']['counter_ion']
    assert fresh is not first


def test_export_taken_finds_what_an_export_would_replace(tmp_path):
    part = OfflineLibraryAssets()
    part.appendPath('DPPC.itp')
    folder = tmp_path / 'export'

    assert not part.exportTaken(str(folder), -1)
    folder.mkdir()
    (folder / 'notes.txt').write_text('')
    assert part.exportTaken(str(folder), -1)
    assert not part.exportTaken(str(folder), 0)

    (folder / 'DPPC.itp').write_text('')
    assert part.exportTaken(str(folder), 0)


def test_export_to_copies_one_file_or_exports_the_asset(tmp_path, log):
    itp = tmp_path / 'DPPC.itp'
    itp.write_text('[ moleculetype ]')
    folder = tmp_path / 'export'
    folder.mkdir()
    part = OfflineLibraryAssets()
    part.assetName = 'DPPC'
    part.appendPath(str(itp))

    part.exportTo(str(folder), 0, False)
    part.exportTo(str(folder), -1, True)

    assert (folder / 'DPPC.itp').read_text() == '[ moleculetype ]'
    built = FakeAsset(name='DPPC', paths=(itp,), counter_ion=None, mint=0, mext=0)
    assert log == [('export_to', built, str(folder), True)]
