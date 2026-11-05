# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest
from PySide6.QtCore import QCoreApplication


@pytest.fixture(scope='session')
def qcore_application():
    app = QCoreApplication.instance()
    if app is None:
        app = QCoreApplication([])
    yield app
    app.quit()


@pytest.fixture
def opened(monkeypatch):
    """
    The paths open_file hands to the system, which opens nothing: every
    files group's pencil goes through it.
    """
    paths = []

    class Desktop:
        @staticmethod
        def openUrl(url):
            paths.append(Path(url.toLocalFile()))
            return True

    monkeypatch.setattr('easyshapes_app.Backends.real_py.library_assets.QDesktopServices', Desktop)
    return paths
