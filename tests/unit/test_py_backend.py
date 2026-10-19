# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session


def test_project_change_refreshes_recent(qcore_application):
    backend = Backend(Session())
    spy = QSignalSpy(backend.library.availableProjectsChanged)

    backend.project.externalProjectChanged.emit()

    assert spy.count() == 1


# One signal from each structure part, to see its refresh
STRUCTURE_SIGNALS = [
    ('ringStructure', 'dminChanged'),
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

    backend.project.externalProjectChanged.emit()

    assert name.count() == 1
    assert [spy.count() for spy in spies] == [1] * len(STRUCTURE_SIGNALS)
