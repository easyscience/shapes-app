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
