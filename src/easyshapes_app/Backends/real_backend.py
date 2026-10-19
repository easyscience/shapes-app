# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject

from .real_py.ball_structure import BallStructure
from .real_py.bilayer_structure import BilayerStructure
from .real_py.config import Config
from .real_py.error import Error
from .real_py.lattice_structure import LatticeStructure
from .real_py.library import Library
from .real_py.logic.session import Session
from .real_py.monolayer_structure import MonolayerStructure
from .real_py.project import Project
from .real_py.ring_structure import RingStructure
from .real_py.rod_structure import RodStructure
from .real_py.sample_model import SampleModel
from .real_py.vesicle_structure import VesicleStructure


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
        self._sample_model = SampleModel(self._session)
        self._ring_structure = RingStructure(self._session)
        self._ball_structure = BallStructure(self._session)
        self._vesicle_structure = VesicleStructure(self._session)
        self._rod_structure = RodStructure(self._session)
        self._bilayer_structure = BilayerStructure(self._session)
        self._monolayer_structure = MonolayerStructure(self._session)
        self._lattice_structure = LatticeStructure(self._session)

        # Recent reads the project index, which create, load and save
        # change.
        self._project.externalProjectChanged.connect(self._library.availableProjectsChanged)

        # Create and load bring their own sample model
        self._project.externalProjectChanged.connect(self._sample_model.refresh)

        # A new structure or sample model: every structure part reads it
        # again
        for part in (
            self._ring_structure,
            self._ball_structure,
            self._vesicle_structure,
            self._rod_structure,
            self._bilayer_structure,
            self._monolayer_structure,
            self._lattice_structure,
        ):
            self._sample_model.externalStructureChanged.connect(part.refresh)

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

    @Property('QVariant', constant=True)
    def sampleModel(self):
        return self._sample_model

    @Property('QVariant', constant=True)
    def ringStructure(self):
        return self._ring_structure

    @Property('QVariant', constant=True)
    def ballStructure(self):
        return self._ball_structure

    @Property('QVariant', constant=True)
    def vesicleStructure(self):
        return self._vesicle_structure

    @Property('QVariant', constant=True)
    def rodStructure(self):
        return self._rod_structure

    @Property('QVariant', constant=True)
    def bilayerStructure(self):
        return self._bilayer_structure

    @Property('QVariant', constant=True)
    def monolayerStructure(self):
        return self._monolayer_structure

    @Property('QVariant', constant=True)
    def latticeStructure(self):
        return self._lattice_structure
