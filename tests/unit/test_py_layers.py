# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Ball

from easyshapes_app.Backends.real_py.layers import LayersModel

Model = LayersModel
pytestmark = pytest.mark.usefixtures('qcore_application')


def test_rows_read_the_layers():
    model = Model(Ball().layers)

    assert model.count == 1
    assert model.get(0) == {'dmin': 0.5, 'rmin': 0.25}
    assert len(model.compositions) == 1


@pytest.mark.parametrize(
    ('role', 'attribute', 'value'),
    [(Model.DminRole, 'dmin', 0.7), (Model.RminRole, 'rmin', 0.4)],
    ids=['dmin', 'rmin'],
)
def test_writes_reach_the_layer_and_emit_only_on_change(role, attribute, value):
    layers = Ball().layers
    model = Model(layers)
    spy = QSignalSpy(model.dataChanged)

    assert model.setData(model.index(0), value, role)
    assert model.setData(model.index(0), value, role)

    assert getattr(layers[0], attribute) == value
    assert spy.count() == 1


def test_add_appends_a_layer_with_the_defaults_and_its_composition():
    model = Model(Ball().layers)
    inserted = QSignalSpy(model.rowsInserted)
    count = QSignalSpy(model.countChanged)
    compositions = QSignalSpy(model.compositionsChanged)

    model.add()

    assert model.get(1) == {'dmin': 0.5, 'rmin': 0.25}
    assert len(model.compositions) == 2
    assert (inserted.count(), count.count(), compositions.count()) == (1, 1, 1)


def test_scaled_values_become_the_defaults():
    layers = Ball().layers
    # The library scales a later layer
    layers.add()

    Model(layers)

    assert (layers[1].dmin, layers[1].rmin) == (0.5, 0.25)


def test_remove_drops_the_row_and_detaches_its_composition():
    layers = Ball().layers
    model = Model(layers)
    model.add()
    removed = layers[0]
    kept = model.compositions[1]
    removed_rows = QSignalSpy(model.rowsRemoved)
    count = QSignalSpy(model.countChanged)
    compositions = QSignalSpy(model.compositionsChanged)

    model.remove(0)

    assert model.count == 1
    assert model.compositions == [kept]
    assert (removed_rows.count(), count.count(), compositions.count()) == (1, 1, 1)
    # Detached already: the library raises on a second detach
    with pytest.raises(ValueError):
        removed.composition.detach()


def test_refresh_resets_every_composition():
    model = Model(Ball().layers)
    model.add()
    resets = [QSignalSpy(composition.modelReset) for composition in model.compositions]

    model.refresh()

    assert [reset.count() for reset in resets] == [1, 1]
