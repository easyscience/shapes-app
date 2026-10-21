# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Vesicle

from easyshapes_app.Backends.real_py.lamellae import LamellaeModel

Model = LamellaeModel
pytestmark = pytest.mark.usefixtures('qcore_application')


def test_rows_read_the_lamellae():
    model = Model(Vesicle().lamellae)

    assert model.count == 1
    assert model.get(0) == {
        'rmin': 0.25,
        'shellThickness': 0.0,
        'innerLeafletDmin': 0.5,
        'outerLeafletDmin': 0.5,
        'symmetric': True,
    }
    assert len(model.innerLeafletCompositions) == 1
    assert model.outerLeafletCompositions == [None]


@pytest.mark.parametrize(
    ('role', 'attribute', 'value'),
    [
        (Model.RminRole, 'rmin', 0.4),
        (Model.ShellThicknessRole, 'shell_thickness', 1.0),
        (Model.InnerLeafletDminRole, 'inner_leaflet_dmin', 0.7),
        (Model.OuterLeafletDminRole, 'outer_leaflet_dmin', 0.6),
    ],
    ids=['rmin', 'shellThickness', 'innerLeafletDmin', 'outerLeafletDmin'],
)
def test_writes_reach_the_lamella_and_emit_only_on_change(role, attribute, value):
    lamellae = Vesicle().lamellae
    model = Model(lamellae)
    spy = QSignalSpy(model.dataChanged)

    assert model.setData(model.index(0), value, role)
    assert model.setData(model.index(0), value, role)

    assert getattr(lamellae[0], attribute) == value
    assert spy.count() == 1


def test_splitting_gives_the_outer_leaflet_its_own_composition_model():
    lamellae = Vesicle().lamellae
    model = Model(lamellae)
    data = QSignalSpy(model.dataChanged)
    outer = QSignalSpy(model.outerLeafletCompositionsChanged)

    assert model.setData(model.index(0), False, Model.SymmetricRole)
    assert model.setData(model.index(0), False, Model.SymmetricRole)

    assert not lamellae[0].symmetric
    assert model.outerLeafletCompositions[0] is not None
    assert (data.count(), outer.count()) == (1, 1)


def test_sharing_drops_the_outer_leaflet_composition_model():
    lamellae = Vesicle().lamellae
    model = Model(lamellae)
    model.setData(model.index(0), False, Model.SymmetricRole)
    outer = QSignalSpy(model.outerLeafletCompositionsChanged)

    model.setData(model.index(0), True, Model.SymmetricRole)

    assert lamellae[0].symmetric
    assert model.outerLeafletCompositions == [None]
    assert outer.count() == 1


def test_add_appends_a_symmetric_lamella_with_the_defaults():
    model = Model(Vesicle().lamellae)
    inserted = QSignalSpy(model.rowsInserted)
    count = QSignalSpy(model.countChanged)
    inner = QSignalSpy(model.innerLeafletCompositionsChanged)
    outer = QSignalSpy(model.outerLeafletCompositionsChanged)

    model.add()

    assert model.get(1) == {
        'rmin': 0.25,
        'shellThickness': 0.0,
        'innerLeafletDmin': 0.5,
        'outerLeafletDmin': 0.5,
        'symmetric': True,
    }
    assert len(model.innerLeafletCompositions) == 2
    assert model.outerLeafletCompositions == [None, None]
    assert (inserted.count(), count.count(), inner.count(), outer.count()) == (1, 1, 1, 1)


def test_scaled_values_become_the_defaults():
    lamellae = Vesicle().lamellae
    # The library scales a later lamella
    lamellae.add()

    Model(lamellae)

    lamella = lamellae[1]
    assert (lamella.rmin, lamella.inner_leaflet_dmin, lamella.outer_leaflet_dmin) == (
        0.25,
        0.5,
        0.5,
    )


@pytest.mark.parametrize('symmetric', [True, False], ids=['symmetric', 'split'])
def test_remove_drops_the_row_and_detaches_its_compositions(symmetric):
    lamellae = Vesicle().lamellae
    model = Model(lamellae)
    model.add()
    model.setData(model.index(0), symmetric, Model.SymmetricRole)
    removed = lamellae[0]
    kept = model.innerLeafletCompositions[1]
    removed_rows = QSignalSpy(model.rowsRemoved)
    count = QSignalSpy(model.countChanged)
    inner = QSignalSpy(model.innerLeafletCompositionsChanged)
    outer = QSignalSpy(model.outerLeafletCompositionsChanged)

    model.remove(0)

    assert model.count == 1
    assert model.innerLeafletCompositions == [kept]
    assert model.outerLeafletCompositions == [None]
    assert (removed_rows.count(), count.count(), inner.count(), outer.count()) == (1, 1, 1, 1)
    # Detached already: the library raises on a second detach
    with pytest.raises(ValueError):
        removed.inner_leaflet_composition.detach()
    with pytest.raises(ValueError):
        removed.outer_leaflet_composition.detach()


def test_refresh_resets_every_leaflet_composition():
    model = Model(Vesicle().lamellae)
    model.add()
    model.setData(model.index(0), False, Model.SymmetricRole)
    compositions = [*model.innerLeafletCompositions, model.outerLeafletCompositions[0]]
    resets = [QSignalSpy(composition.modelReset) for composition in compositions]

    model.refresh()

    assert [reset.count() for reset in resets] == [1, 1, 1]
