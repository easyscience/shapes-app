# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.asset_files import AssetFiles
from easyshapes_app.Backends.real_py.logic.session import Session
from tests.unit.factories import FakeAnalysis
from tests.unit.factories import FakeAsset

pytestmark = pytest.mark.usefixtures('qcore_application')

# The equilibration's attribute each part shows, and its file
ATTRIBUTES = [('configuration', 'equil0.mdp'), ('force_field', 'CHARMM36.itp')]


class FakeAssetClass(FakeAsset):
    """
    A library class whose load gives an asset of the name, holding one
    file named after it.
    """

    @classmethod
    def load(cls, name):
        return cls(name, f'{name}.dat')


class FakeLibrary:
    """
    Holds a FakeAssetClass named Taken.
    """

    def has_entry(self, asset_type, name):
        return (asset_type, name) == ('FakeAssetClass', 'Taken')


class OfflineAssetFiles(AssetFiles):
    """
    Checks names in FakeLibrary, not in the library.
    """

    _library_class = FakeLibrary


def part_and_asset(attribute):
    """
    A part on a session holding a FakeAnalysis, and the asset it shows.
    """
    session = Session(analysis=FakeAnalysis())
    part = OfflineAssetFiles(session, attribute, FakeAssetClass)
    return part, getattr(session.analysis.equilibration, attribute)


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_fields_are_empty_without_analysis(attribute, file):
    part = AssetFiles(Session(), attribute, FakeAssetClass)

    part.refresh()
    part.name = 'Mine'

    assert (part.name, part.files.paths) == ('', ())


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_refresh_shows_the_assets_files(attribute, file):
    part, _ = part_and_asset(attribute)
    named = QSignalSpy(part.nameChanged)

    part.refresh()

    assert (part.name, part.files.paths) == ('CHARMM36', (Path(file),))
    assert named.count() == 1


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_rename_emits_only_on_change_and_reads_the_files_again(attribute, file):
    part, asset = part_and_asset(attribute)
    named = QSignalSpy(part.nameChanged)
    # A real rename moves the files of the asset's working folder
    asset.add_new_files([f'Mine/{file}'])

    part.name = 'Mine'
    part.name = 'Mine'

    assert (asset.name, named.count()) == ('Mine', 1)
    assert Path(f'Mine/{file}') in part.files.paths


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_load_puts_the_librarys_asset_into_the_equilibration(attribute, file):
    session = Session(analysis=FakeAnalysis())
    part = AssetFiles(session, attribute, FakeAssetClass)
    named = QSignalSpy(part.nameChanged)

    part.load('Other')

    asset = getattr(session.analysis.equilibration, attribute)
    assert (asset.name, part.name) == ('Other', 'Other')
    assert part.files.paths == (Path('Other.dat'),)
    assert named.count() == 1


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_file_changes_go_to_the_asset(attribute, file):
    part, asset = part_and_asset(attribute)

    part.appendFile('added.dat')
    # By its row: sorted paths put CHARMM36.itp first on Linux, last on
    # Windows, which ignores case
    part.removeFile(part.files.paths.index(Path(file)))

    assert asset.paths == (Path('added.dat'),)
    assert part.files.paths == asset.paths


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_edit_file_opens_the_rows_file(opened, attribute, file):
    part, _ = part_and_asset(attribute)
    part.refresh()

    part.editFile(0)

    assert opened == [Path(file)]


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_name_is_taken_by_a_library_entry_of_the_assets_class(attribute, file):
    part, _ = part_and_asset(attribute)

    free = part.nameTaken()
    part.name = 'Taken'

    assert not free
    assert part.nameTaken()


@pytest.mark.parametrize(('attribute', 'file'), ATTRIBUTES)
def test_save_and_export_pass_overwrite_and_save_refreshes_the_catalogs(attribute, file):
    part, asset = part_and_asset(attribute)
    saved = QSignalSpy(part.externalAssetsChanged)

    part.save(True)
    part.exportTo('/exports/mine', False)

    assert asset.calls == [('save', True), ('export_to', '/exports/mine', False)]
    assert saved.count() == 1


def test_export_taken_checks_the_whole_folder(tmp_path):
    part, _ = part_and_asset('configuration')
    (tmp_path / 'equil0.mdp').write_text('')

    assert part.exportTaken(str(tmp_path))
    assert not part.exportTaken(str(tmp_path / 'empty'))
