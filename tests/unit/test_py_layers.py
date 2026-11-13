# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Ball

from easyshapes_app.Backends.real_py.layers import LayersModel
from tests.unit.factories import REFUSED
from tests.unit.factories import refusals

Model = LayersModel
pytestmark = pytest.mark.usefixtures('qcore_application')


def test_rows_read_the_layers():
    model = Model(Ball())

    assert model.count == 1
    # No components, so no bone to measure
    assert model.get(0) == {'dmin': 0.5, 'rmin': 1.2, 'thickness': None}
    assert len(model.compositions) == 1


def test_rows_refuse_an_invalid_index_or_an_unknown_role():
    assert refusals(Model(Ball()), 0.7) == REFUSED


@pytest.mark.parametrize(
    ('role', 'attribute', 'value'),
    [(Model.DminRole, 'dmin', 0.7), (Model.RminRole, 'rmin', 0.4)],
    ids=['dmin', 'rmin'],
)
def test_writes_reach_the_layer_and_emit_only_on_change(role, attribute, value):
    ball = Ball()
    layers = ball.layers
    model = Model(ball)
    spy = QSignalSpy(model.dataChanged)

    assert model.setData(model.index(0), value, role)
    assert model.setData(model.index(0), value, role)

    assert getattr(layers[0], attribute) == value
    assert spy.count() == 1


def test_add_keeps_the_library_dmin_and_fills_an_unknown_rmin():
    model = Model(Ball())
    model.setData(model.index(0), 0.7, Model.DminRole)
    inserted = QSignalSpy(model.rowsInserted)
    count = QSignalSpy(model.countChanged)
    compositions = QSignalSpy(model.compositionsChanged)

    model.add()

    # The library copies the dmin before; with no bone lengths it can't
    # stack the rmin
    assert model.get(1) == {'dmin': 0.7, 'rmin': 1.2, 'thickness': None}
    assert len(model.compositions) == 2
    assert (inserted.count(), count.count(), compositions.count()) == (1, 1, 1)


def test_scaled_values_become_the_defaults():
    ball = Ball()
    layers = ball.layers
    layers.add()
    # As a project saved with scaling holds them
    layers[1].dmin = None
    layers[1].rmin = None

    Model(ball)

    assert (layers[1].dmin, layers[1].rmin) == (0.5, 1.2)


def test_remove_drops_the_row_and_detaches_its_composition():
    ball = Ball()
    layers = ball.layers
    model = Model(ball)
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
    model = Model(Ball())
    model.add()
    resets = [QSignalSpy(composition.modelReset) for composition in model.compositions]

    model.refresh()

    assert [reset.count() for reset in resets] == [1, 1]


def test_rmin_add_and_remove_announce_the_full_radius():
    model = Model(Ball())
    radius = QSignalSpy(model.fullRadiusChanged)

    # The full radius doesn't depend on dmin
    model.setData(model.index(0), 0.7, Model.DminRole)
    assert radius.count() == 0
    model.setData(model.index(0), 1.5, Model.RminRole)
    assert radius.count() == 1
    model.add()
    assert radius.count() == 2
    model.remove(1)
    assert radius.count() == 3


def test_refresh_announces_the_thickness_and_the_full_radius():
    model = Model(Ball())
    model.add()
    data = QSignalSpy(model.dataChanged)
    radius = QSignalSpy(model.fullRadiusChanged)

    model.refresh()

    top_left, bottom_right, roles = data.at(0)
    assert data.count() == 1
    assert (top_left.row(), bottom_right.row(), roles) == (0, 1, [Model.ThicknessRole])
    assert radius.count() == 1
