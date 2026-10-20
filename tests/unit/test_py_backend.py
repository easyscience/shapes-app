# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Lattice
from shapes.project import Ring

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session
from tests.unit.factories import FakeSampleModel


def test_project_change_refreshes_recent(qcore_application):
    backend = Backend(Session())
    spy = QSignalSpy(backend.library.availableProjectsChanged)

    backend.project.externalProjectChanged.emit()

    assert spy.count() == 1


# One signal from each structure part, to see its refresh
STRUCTURE_SIGNALS = [
    ('ballStructure', 'fillChanged'),
    ('vesicleStructure', 'fillChanged'),
    ('rodStructure', 'turnsChanged'),
    ('bilayerStructure', 'nsideChanged'),
    ('monolayerStructure', 'nsideChanged'),
    ('latticeStructure', 'latticeTypeChanged'),
]


def test_project_change_refreshes_sample_model_and_structure_parts(qcore_application):
    backend = Backend(Session())
    name = QSignalSpy(backend.sampleModel.nameChanged)
    spies = [
        QSignalSpy(getattr(getattr(backend, part), signal)) for part, signal in STRUCTURE_SIGNALS
    ]
    components = QSignalSpy(backend.components.loaded.modelReset)
    ring = QSignalSpy(backend.ringStructureChanged)

    backend.project.externalProjectChanged.emit()

    assert name.count() == 1
    assert [spy.count() for spy in spies] == [1] * len(STRUCTURE_SIGNALS)
    assert components.count() == 1
    assert ring.count() == 1
    assert backend.ringStructure is None


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
