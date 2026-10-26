# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path
from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.components_files import ComponentsFiles
from easyshapes_app.Backends.real_py.logic.session import Session
from tests.unit.factories import FakeSampleModel

pytestmark = pytest.mark.usefixtures('qcore_application')


class FakeComponent:
    """
    Holds its files as the library does: sorted, each once, added and
    removed by path. Logs saves and exports in calls.
    """

    def __init__(self, name, *paths):
        self.name = name
        self._paths = {Path(path) for path in paths}
        self.calls = []

    @property
    def paths(self):
        return tuple(sorted(self._paths))

    def add_new_files(self, paths):
        self._paths.update(Path(path) for path in paths)

    def remove_files(self, paths):
        self._paths.difference_update(Path(path) for path in paths)

    def save(self, *, overwrite=False):
        self.calls.append(('save', overwrite))

    def export_to(self, folder, *, overwrite=False):
        self.calls.append(('export_to', folder, overwrite))


class FakeComponents(list):
    """
    The library's collection: a component by its name, held names.
    """

    def __getitem__(self, name):
        for component in self:
            if component.name == name:
                return component
        raise KeyError(name)

    def __contains__(self, name):
        return any(component.name == name for component in self)


class FakeLibrary:
    """
    Holds a FakeComponent named DPPC.
    """

    def has_entry(self, asset_type, name):
        return (asset_type, name) == ('FakeComponent', 'DPPC')


class OfflineComponentsFiles(ComponentsFiles):
    """
    Makes FakeComponents and checks names in FakeLibrary.
    """

    _component_class = FakeComponent
    _library_class = FakeLibrary


def part_with(*components):
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=FakeComponents(components))
    return (
        OfflineComponentsFiles(Session(sample_model=sample_model)),
        sample_model.structure.components,
    )


def test_select_shows_the_components_name_and_files():
    part, _ = part_with(FakeComponent('DPPC', 'DPPC.itp', 'DPPC.gro'))
    spy = QSignalSpy(part.selectedComponentChanged)

    part.selectComponent('DPPC')

    assert part.selectedComponent == 'DPPC'
    assert part.files.paths == (Path('DPPC.gro'), Path('DPPC.itp'))
    assert spy.count() == 1


def test_unknown_name_raises():
    part, _ = part_with(FakeComponent('DPPC'))

    with pytest.raises(KeyError):
        part.selectComponent('POPC')


def test_create_new_clears_the_pick_and_the_rows():
    part, _ = part_with(FakeComponent('DPPC', 'DPPC.itp'))
    part.selectComponent('DPPC')

    part.createNew()

    assert (part.selectedComponent, part.files.count) == ('', 0)


def test_file_changes_go_to_the_live_component():
    dppc = FakeComponent('DPPC', 'DPPC.itp')
    part, _ = part_with(dppc)
    part.selectComponent('DPPC')

    part.appendFile('DPPC.gro')
    part.appendFile('DPPC.gro')
    # Rows are sorted: DPPC.gro, then DPPC.itp
    part.removeFile(1)

    assert dppc.paths == (Path('DPPC.gro'),)
    assert part.files.paths == dppc.paths


def test_refresh_keeps_a_renamed_pick_and_drops_a_removed_one():
    dppc = FakeComponent('DPPC', 'DPPC.itp')
    part, components = part_with(dppc, FakeComponent('POPC'))
    part.selectComponent('DPPC')
    spy = QSignalSpy(part.selectedComponentChanged)

    dppc.name = 'DOPC'
    part.refresh()
    assert part.selectedComponent == 'DOPC'

    components.remove(dppc)
    part.refresh()
    assert (part.selectedComponent, part.files.count) == ('', 0)
    assert spy.count() == 2


def test_create_hands_a_new_component_to_the_root_and_picks_it():
    part, _ = part_with()
    created = []
    part.externalComponentCreated.connect(created.append)

    part.create('DOPC')

    (component,) = created
    assert (component.name, part.selectedComponent) == ('DOPC', 'DOPC')


def test_create_of_a_held_name_raises_and_emits_nothing():
    part, _ = part_with(FakeComponent('DPPC'))
    created = QSignalSpy(part.externalComponentCreated)

    with pytest.raises(ValueError, match='already holds DPPC'):
        part.create('DPPC')

    assert created.count() == 0


def test_name_is_taken_by_a_library_entry_of_its_class():
    part, _ = part_with(FakeComponent('DPPC'), FakeComponent('POPC'))

    part.selectComponent('DPPC')
    assert part.nameTaken()
    part.selectComponent('POPC')
    assert not part.nameTaken()


def test_save_writes_the_live_component_and_refreshes_the_catalogs():
    dppc = FakeComponent('DPPC')
    part, _ = part_with(dppc)
    part.selectComponent('DPPC')
    saved = QSignalSpy(part.externalAssetsChanged)

    part.save(True)

    assert dppc.calls == [('save', True)]
    assert saved.count() == 1


def test_export_taken_checks_the_rows_file_or_the_whole_component(tmp_path):
    part, _ = part_with(FakeComponent('DPPC', 'files/DPPC.itp'))
    part.selectComponent('DPPC')
    (tmp_path / 'DPPC.itp').write_text('')

    assert part.exportTaken(str(tmp_path), 0)
    assert part.exportTaken(str(tmp_path), -1)
    assert not part.exportTaken(str(tmp_path / 'empty'), -1)


def test_export_to_copies_one_file_or_exports_the_component(tmp_path):
    itp = tmp_path / 'DPPC.itp'
    itp.write_text('[ moleculetype ]')
    folder = tmp_path / 'export'
    folder.mkdir()
    dppc = FakeComponent('DPPC', itp)
    part, _ = part_with(dppc)
    part.selectComponent('DPPC')

    part.exportTo(str(folder), 0, False)
    part.exportTo(str(folder), -1, True)

    assert (folder / 'DPPC.itp').read_text() == '[ moleculetype ]'
    assert dppc.calls == [('export_to', str(folder), True)]
