# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtCore import QModelIndex
from PySide6.QtTest import QSignalSpy
from shapes.project import Ball
from shapes.project import Bilayer
from shapes.project import Lattice
from shapes.project import Monolayer
from shapes.project import Ring
from shapes.project import Rod
from shapes.project import Vesicle

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session
from tests.unit.factories import FakeSampleModel


def test_project_change_refreshes_recent(qcore_application):
    backend = Backend(Session())
    spy = QSignalSpy(backend.library.availableProjectsChanged)

    backend.project.externalProjectChanged.emit()

    assert spy.count() == 1


# Each shape adapter on the backend, and the class it adapts
SHAPE_ADAPTERS = {
    'ringStructure': Ring,
    'ballStructure': Ball,
    'vesicleStructure': Vesicle,
    'rodStructure': Rod,
    'bilayerStructure': Bilayer,
    'monolayerStructure': Monolayer,
}
ADAPTERS = [*SHAPE_ADAPTERS, 'latticeStructure']


def test_project_change_refreshes_sample_model_components_and_adapters(qcore_application):
    backend = Backend(Session())
    name = QSignalSpy(backend.sampleModel.nameChanged)
    components = QSignalSpy(backend.components.loaded.modelReset)
    swapped = [QSignalSpy(getattr(backend, f'{adapter}Changed')) for adapter in ADAPTERS]
    composition = QSignalSpy(backend.compositionChanged)

    backend.project.externalProjectChanged.emit()

    assert name.count() == 1
    assert components.count() == 1
    assert [spy.count() for spy in swapped] == [1] * len(ADAPTERS)
    assert [getattr(backend, adapter) for adapter in ADAPTERS] == [None] * len(ADAPTERS)
    assert composition.count() == 1
    assert backend.composition is None


@pytest.mark.parametrize('lattice', [False, True], ids=['plain', 'lattice'])
@pytest.mark.parametrize('adapter', list(SHAPE_ADAPTERS))
def test_only_the_current_shape_and_its_lattice_are_adapted(qcore_application, adapter, lattice):
    unit = SHAPE_ADAPTERS[adapter]()
    sample_model = FakeSampleModel(Lattice(unit=unit) if lattice else unit)
    backend = Backend(Session(sample_model=sample_model))

    backend.sampleModel.externalStructureChanged.emit()

    adapted = {name for name in ADAPTERS if getattr(backend, name) is not None}
    assert adapted == ({adapter, 'latticeStructure'} if lattice else {adapter})


@pytest.mark.parametrize('lattice', [False, True], ids=['plain', 'lattice'])
def test_ring_adapter_follows_the_current_structure(qcore_application, lattice):
    ring = Ring()
    sample_model = FakeSampleModel(Lattice(unit=ring) if lattice else ring)
    backend = Backend(Session(sample_model=sample_model))
    swapped = QSignalSpy(backend.ringStructureChanged)

    backend.sampleModel.externalStructureChanged.emit()
    backend.ringStructure.dmin = 0.7

    assert ring.dmin == 0.7
    assert swapped.count() == 1

    backend.sampleModel.shape = 'Ball'

    assert backend.ringStructure is None
    assert swapped.count() == 2


@pytest.mark.parametrize('adapter', list(SHAPE_ADAPTERS))
def test_only_shapes_that_own_a_composition_get_its_model(qcore_application, adapter):
    backend = Backend(Session(sample_model=FakeSampleModel(SHAPE_ADAPTERS[adapter]())))

    backend.sampleModel.externalStructureChanged.emit()

    owns = adapter not in ('ballStructure', 'vesicleStructure')
    assert (backend.composition is not None) == owns


def test_component_changes_refresh_the_composition(qcore_application):
    backend = Backend(Session(sample_model=FakeSampleModel(Ring())))
    backend.sampleModel.externalStructureChanged.emit()
    reset = QSignalSpy(backend.composition.modelReset)

    backend.components.loaded.dataChanged.emit(QModelIndex(), QModelIndex(), [])

    assert reset.count() == 1
