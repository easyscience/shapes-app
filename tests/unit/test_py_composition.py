# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.composition import CompositionModel

Model = CompositionModel
pytestmark = pytest.mark.usefixtures('qcore_application')


class FakeComposition:
    """
    The library's Composition: one (component, present, ratio) entry per
    component, a ratio of 0 marking the component absent.
    """

    def __init__(self, *names):
        self._items = [(SimpleNamespace(name=name), True, 1.0) for name in names]

    def __len__(self):
        return len(self._items)

    @property
    def items(self):
        return list(self._items)

    def set_presence(self, component, present):
        row = next(row for row, (held, _, _) in enumerate(self._items) if held is component)
        self._items[row] = (component, present, self._items[row][2])

    def set_mol_ratio(self, component, value):
        row = next(row for row, (held, _, _) in enumerate(self._items) if held is component)
        ratio = self._items[row][2]
        self._items[row] = (component, False, ratio) if value == 0 else (component, True, value)


def write(model, row, value, role):
    return model.setData(model.index(row), value, role)


def emitted_roles(model):
    """
    The roles of each dataChanged, collected as they come.
    """
    emitted = []
    model.dataChanged.connect(lambda top, bottom, roles: emitted.append(list(roles)))
    return emitted


def test_rows_read_the_composition():
    model = Model(FakeComposition('DPPC', 'CHOL'))

    assert model.count == 2
    assert model.get(1) == {'name': 'CHOL', 'present': True, 'molRatio': 1.0}


@pytest.mark.parametrize(
    ('role', 'value', 'entry'),
    [(Model.PresentRole, False, (False, 1.0)), (Model.MolRatioRole, 2.5, (True, 2.5))],
    ids=['present', 'molRatio'],
)
def test_writes_reach_the_composition_and_emit_only_on_change(role, value, entry):
    composition = FakeComposition('DPPC')
    model = Model(composition)
    emitted = emitted_roles(model)

    assert write(model, 0, value, role)
    assert write(model, 0, value, role)

    assert composition.items[0][1:] == entry
    assert emitted == [[role]]


def test_zero_ratio_marks_absent_and_keeps_the_ratio():
    composition = FakeComposition('DPPC')
    model = Model(composition)
    write(model, 0, 2.5, Model.MolRatioRole)
    emitted = emitted_roles(model)

    write(model, 0, 0.0, Model.MolRatioRole)

    assert model.get(0) == {'name': 'DPPC', 'present': False, 'molRatio': 2.5}
    assert emitted == [[Model.PresentRole]]


def test_positive_ratio_on_an_absent_component_marks_it_present():
    model = Model(FakeComposition('DPPC'))
    write(model, 0, False, Model.PresentRole)
    emitted = emitted_roles(model)

    write(model, 0, 3.0, Model.MolRatioRole)

    assert emitted == [[Model.PresentRole, Model.MolRatioRole]]


def test_refresh_resets_the_rows():
    model = Model(FakeComposition('DPPC'))
    reset = QSignalSpy(model.modelReset)
    count = QSignalSpy(model.countChanged)

    model.refresh()

    assert (reset.count(), count.count()) == (1, 1)
