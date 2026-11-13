# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Vesicle

from easyshapes_app.Backends.real_py.lamellae import LamellaeModel
from tests.unit.factories import REFUSED
from tests.unit.factories import refusals

Model = LamellaeModel
pytestmark = pytest.mark.usefixtures('qcore_application')


def test_rows_read_the_lamellae():
    model = Model(Vesicle())

    assert model.count == 1
    # No bone lengths to work the shell out from
    assert model.get(0) == {
        'rmin': 1.2,
        'shellThickness': None,
        'innerLeafletDmin': 0.5,
        'outerLeafletDmin': 0.5,
        'symmetric': True,
    }
    assert len(model.innerLeafletCompositions) == 1
    assert model.outerLeafletCompositions == [None]


def test_rows_refuse_an_invalid_index_or_an_unknown_role():
    assert refusals(Model(Vesicle()), 0.4) == REFUSED


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
    vesicle = Vesicle()
    lamellae = vesicle.lamellae
    model = Model(vesicle)
    spy = QSignalSpy(model.dataChanged)

    assert model.setData(model.index(0), value, role)
    assert model.setData(model.index(0), value, role)

    assert getattr(lamellae[0], attribute) == value
    assert spy.count() == 1


def test_splitting_gives_the_outer_leaflet_its_own_composition_model():
    vesicle = Vesicle()
    lamellae = vesicle.lamellae
    model = Model(vesicle)
    data = QSignalSpy(model.dataChanged)
    outer = QSignalSpy(model.outerLeafletCompositionsChanged)

    assert model.setData(model.index(0), False, Model.SymmetricRole)
    assert model.setData(model.index(0), False, Model.SymmetricRole)

    assert not lamellae[0].symmetric
    assert model.outerLeafletCompositions[0] is not None
    assert (data.count(), outer.count()) == (1, 1)


def test_sharing_drops_the_outer_leaflet_composition_model():
    vesicle = Vesicle()
    lamellae = vesicle.lamellae
    model = Model(vesicle)
    model.setData(model.index(0), False, Model.SymmetricRole)
    outer = QSignalSpy(model.outerLeafletCompositionsChanged)

    model.setData(model.index(0), True, Model.SymmetricRole)

    assert lamellae[0].symmetric
    assert model.outerLeafletCompositions == [None]
    assert outer.count() == 1


def test_add_appends_a_symmetric_lamella_keeping_the_library_dmins():
    model = Model(Vesicle())
    model.setData(model.index(0), 0.7, Model.InnerLeafletDminRole)
    model.setData(model.index(0), 0.6, Model.OuterLeafletDminRole)
    inserted = QSignalSpy(model.rowsInserted)
    count = QSignalSpy(model.countChanged)
    inner = QSignalSpy(model.innerLeafletCompositionsChanged)
    outer = QSignalSpy(model.outerLeafletCompositionsChanged)

    model.add()

    # The library copies the dmins before; with no bone lengths it can't
    # stack the rmin
    assert model.get(1) == {
        'rmin': 1.2,
        'shellThickness': None,
        'innerLeafletDmin': 0.7,
        'outerLeafletDmin': 0.6,
        'symmetric': True,
    }
    assert len(model.innerLeafletCompositions) == 2
    assert model.outerLeafletCompositions == [None, None]
    assert (inserted.count(), count.count(), inner.count(), outer.count()) == (1, 1, 1, 1)


def test_scaled_values_become_the_defaults():
    vesicle = Vesicle()
    lamellae = vesicle.lamellae
    lamellae.add()
    lamella = lamellae[1]
    # As a project saved with scaling holds them
    lamella.rmin = None
    lamella.inner_leaflet_dmin = None
    lamella.outer_leaflet_dmin = None

    Model(vesicle)

    assert (lamella.rmin, lamella.inner_leaflet_dmin, lamella.outer_leaflet_dmin) == (
        1.2,
        0.5,
        0.5,
    )


@pytest.mark.parametrize('symmetric', [True, False], ids=['symmetric', 'split'])
def test_remove_drops_the_row_and_detaches_its_compositions(symmetric):
    vesicle = Vesicle()
    lamellae = vesicle.lamellae
    model = Model(vesicle)
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
    model = Model(Vesicle())
    model.add()
    model.setData(model.index(0), False, Model.SymmetricRole)
    compositions = [*model.innerLeafletCompositions, model.outerLeafletCompositions[0]]
    resets = [QSignalSpy(composition.modelReset) for composition in compositions]

    model.refresh()

    assert [reset.count() for reset in resets] == [1, 1, 1]


def test_edits_add_and_remove_announce_the_full_radius():
    model = Model(Vesicle())
    radius = QSignalSpy(model.fullRadiusChanged)

    # The full radius doesn't depend on the inner leaflet's dmin
    model.setData(model.index(0), 0.7, Model.InnerLeafletDminRole)
    assert radius.count() == 0
    model.setData(model.index(0), 1.5, Model.RminRole)
    model.setData(model.index(0), 2.0, Model.ShellThicknessRole)
    model.setData(model.index(0), 0.6, Model.OuterLeafletDminRole)
    model.setData(model.index(0), False, Model.SymmetricRole)
    model.add()
    model.remove(1)
    assert radius.count() == 6


def test_outer_dmin_announces_the_shell_with_it():
    model = Model(Vesicle())
    data = QSignalSpy(model.dataChanged)

    model.setData(model.index(0), 0.6, Model.OuterLeafletDminRole)

    # A worked-out shell holds the outer dmin
    assert data.count() == 1
    assert data.at(0)[2] == [Model.OuterLeafletDminRole, Model.ShellThicknessRole]


def test_a_set_shell_gives_a_full_radius():
    model = Model(Vesicle())
    assert model.fullRadius is None

    model.setData(model.index(0), 2.0, Model.ShellThicknessRole)

    # Known without bones: rmin plus the shell set
    assert model.fullRadius == pytest.approx(1.2 + 2.0)


def test_refresh_announces_the_shell_and_the_full_radius():
    model = Model(Vesicle())
    model.add()
    data = QSignalSpy(model.dataChanged)
    radius = QSignalSpy(model.fullRadiusChanged)

    model.refresh()

    top_left, bottom_right, roles = data.at(0)
    assert data.count() == 1
    assert (top_left.row(), bottom_right.row(), roles) == (0, 1, [Model.ShellThicknessRole])
    assert radius.count() == 1
