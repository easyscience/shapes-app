# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject

from .real_py.config import Config
from .real_py.error import Error
from .real_py.library import Library
from .real_py.logic.session import Session
from .real_py.project import Project


class Backend(QObject):
    """
    The object QML reaches as Backends.PyBackend, mirroring MockBackend.

    Holds the session and one part per domain, and connects parts that
    react to each other, so the parts don't know each other.
    """

    def __init__(self, session: Session | None = None):
        super().__init__()

        # What the app works on, shared by all parts.
        # Tests pass their own.
        self._session = session or Session()

        self._project = Project(self._session)
        self._library = Library()
        self._config = Config()
        self._error = Error()

        # Recent reads the project index, which create, load and save
        # change.
        self._project.externalProjectChanged.connect(self._library.availableProjectsChanged)

    @Property('QVariant', constant=True)
    def project(self):
        return self._project

    @Property('QVariant', constant=True)
    def library(self):
        return self._library

    @Property('QVariant', constant=True)
    def config(self):
        return self._config

    @Property('QVariant', constant=True)
    def error(self):
        return self._error
