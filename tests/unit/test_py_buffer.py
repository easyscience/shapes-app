# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path
from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.buffer import Buffer
from easyshapes_app.Backends.real_py.buffer import BufferComponentsModel

Model = BufferComponentsModel
pytestmark = pytest.mark.usefixtures('qcore_application')


class FakeAsset:
    """
    Loads the salts and solvents named in NAMES, as the library loads
    saved assets, and imports one from any folder, named after it.
    """

    NAMES = ('NaCl', 'KCl', 'TIP3')

    def __init__(self, name, concentration=0.0):
        self.name = name
        self.concentration = concentration

    @classmethod
    def load(cls, name):
        if name not in cls.NAMES:
            raise LookupError(f'Asset with the name {name} was not found in the asset library.')
        return cls(name)

    @classmethod
    def import_from(cls, folder):
        return cls(Path(folder).name)


class FakeBufferComponents(list):
    """
    The library's collection: rows by index, held names, remove by row.
    """

    def __contains__(self, name):
        return any(component.name == name for component in self)

    def remove(self, row):
        del self[row]


class OfflineBuffer(Buffer):
    """
    Loads FakeAssets, not library ones.
    """

    _salt_class = FakeAsset
    _solvent_class = FakeAsset


def buffer_with(*salts):
    return SimpleNamespace(solvent=None, components=FakeBufferComponents(salts))


def test_rows_read_the_concentrations_in_mm():
    # Kept: the model is the part's child and goes with it
    part = OfflineBuffer(buffer_with(FakeAsset('NaCl', 0.15), FakeAsset('KCl', 0.0035)))
    model = part.components

    assert model.count == 2
    # 0.0035 * 1000 is 3.5000000000000004 before rounding
    assert [model.get(row) for row in range(model.count)] == [
        {'name': 'NaCl', 'concentration': 150.0},
        {'name': 'KCl', 'concentration': 3.5},
    ]


def test_concentration_writes_mol_per_litre_and_emits_only_on_change():
    salt = FakeAsset('NaCl', 0.15)
    part = OfflineBuffer(buffer_with(salt))
    model = part.components
    spy = QSignalSpy(model.dataChanged)

    # The value already shown, in mM
    assert model.setData(model.index(0), 150.0, Model.ConcentrationRole)
    assert model.setData(model.index(0), 2.5, Model.ConcentrationRole)
    assert model.setData(model.index(0), 2.5, Model.ConcentrationRole)

    assert salt.concentration == 0.0025
    assert spy.count() == 1


def test_solvent_loads_by_name_and_emits_only_on_change():
    buffer = buffer_with()
    part = OfflineBuffer(buffer)
    spy = QSignalSpy(part.solventChanged)

    assert part.solvent == ''
    part.solvent = 'TIP3'
    part.solvent = 'TIP3'

    assert buffer.solvent.name == 'TIP3'
    assert spy.count() == 1

    part.solvent = ''

    assert buffer.solvent is None
    assert spy.count() == 2


def test_unknown_solvent_raises_and_keeps_the_solvent():
    part = OfflineBuffer(buffer_with())

    with pytest.raises(LookupError):
        part.solvent = 'Water'

    assert part.solvent == ''


def test_append_component_loads_the_salt_as_a_new_row():
    part = OfflineBuffer(buffer_with(FakeAsset('NaCl', 0.15)))
    model = part.components
    inserted = QSignalSpy(model.rowsInserted)
    count = QSignalSpy(model.countChanged)

    part.appendComponent('KCl')

    assert model.get(1) == {'name': 'KCl', 'concentration': 0.0}
    assert (inserted.count(), count.count()) == (1, 1)


@pytest.mark.parametrize(
    ('name', 'error'),
    [('NaCl', ValueError), ('Tris', LookupError)],
    ids=['held', 'unknown'],
)
def test_held_or_unknown_salt_raises_before_any_row_opens(name, error):
    part = OfflineBuffer(buffer_with(FakeAsset('NaCl', 0.15)))
    model = part.components
    opening = QSignalSpy(model.rowsAboutToBeInserted)

    with pytest.raises(error):
        part.appendComponent(name)

    assert model.count == 1
    assert opening.count() == 0


def test_remove_component_drops_the_row():
    part = OfflineBuffer(buffer_with(FakeAsset('NaCl', 0.15), FakeAsset('KCl', 0.01)))
    model = part.components
    removed = QSignalSpy(model.rowsRemoved)
    count = QSignalSpy(model.countChanged)

    part.removeComponent(0)

    assert [model.get(row)['name'] for row in range(model.count)] == ['KCl']
    assert (removed.count(), count.count()) == (1, 1)


def test_import_adds_the_exported_salt_as_a_new_row():
    part = OfflineBuffer(buffer_with(FakeAsset('NaCl', 0.15)))
    model = part.components
    inserted = QSignalSpy(model.rowsInserted)

    part.importFrom('exports/KCl')

    assert model.get(1) == {'name': 'KCl', 'concentration': 0.0}
    assert inserted.count() == 1


def test_import_of_a_held_salt_raises_before_any_row_opens():
    part = OfflineBuffer(buffer_with(FakeAsset('NaCl', 0.15)))
    opening = QSignalSpy(part.components.rowsAboutToBeInserted)

    with pytest.raises(ValueError, match='already holds NaCl'):
        part.importFrom('exports/NaCl')

    assert opening.count() == 0
