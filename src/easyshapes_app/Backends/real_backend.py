# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from shapes.project import Ball
from shapes.project import Bilayer
from shapes.project import Lattice
from shapes.project import Monolayer
from shapes.project import Ring
from shapes.project import Rod
from shapes.project import Vesicle

from .real_py.ball_structure import BallStructure
from .real_py.bilayer_structure import BilayerStructure
from .real_py.buffer import Buffer
from .real_py.components import Components
from .real_py.composition import CompositionModel
from .real_py.config import Config
from .real_py.error import Error
from .real_py.lamellae import LamellaeModel
from .real_py.lattice_structure import LatticeStructure
from .real_py.layers import LayersModel
from .real_py.library import Library
from .real_py.library_assets import LibraryAssets
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

    Also builds, anew on every structure change, the structure adapters
    (one for the current shape and one for a lattice), the model of what
    the shape holds (its composition, layers or lamellae) and the sample
    model's buffer adapter.
    """

    # The adapter of the current structure's shape was replaced
    ringStructureChanged = Signal()
    ballStructureChanged = Signal()
    vesicleStructureChanged = Signal()
    rodStructureChanged = Signal()
    bilayerStructureChanged = Signal()
    monolayerStructureChanged = Signal()
    latticeStructureChanged = Signal()
    compositionChanged = Signal()
    layersChanged = Signal()
    lamellaeChanged = Signal()
    bufferChanged = Signal()

    def __init__(self, session: Session | None = None):
        super().__init__()

        # What the app works on, shared by all parts.
        # Tests pass their own.
        self._session = session or Session()

        self._project = Project(self._session)
        self._library = Library()
        self._library_assets = LibraryAssets()
        self._config = Config()
        self._error = Error()
        self._sample_model = SampleModel(self._session)
        # The adapter of the current shape; None while another shape is
        # current
        self._ring_structure = None
        self._ball_structure = None
        self._vesicle_structure = None
        self._rod_structure = None
        self._bilayer_structure = None
        self._monolayer_structure = None
        self._lattice_structure = None
        self._composition = None
        self._layers = None
        self._lamellae = None
        self._buffer = None
        self._components = Components(self._session)

        # Recent reads the project index, which create, load and save
        # change.
        self._project.externalProjectChanged.connect(self._library.availableProjectsChanged)

        # A saved asset joins the catalogs
        self._library_assets.externalAssetsChanged.connect(self._library.availableAssetsChanged)

        # Create and load bring their own sample model
        self._project.externalProjectChanged.connect(self._sample_model.refresh)

        # A new structure or sample model: the components list reads it
        # again
        self._sample_model.externalStructureChanged.connect(self._components.refresh)

        # A new structure or sample model: adapt its shape anew
        self._sample_model.externalStructureChanged.connect(self._adapt_structure)

    @Property('QVariant', constant=True)
    def project(self):
        return self._project

    @Property('QVariant', constant=True)
    def library(self):
        return self._library

    @Property('QVariant', constant=True)
    def libraryAssets(self):
        return self._library_assets

    @Property('QVariant', constant=True)
    def config(self):
        return self._config

    @Property('QVariant', constant=True)
    def error(self):
        return self._error

    @Property('QVariant', constant=True)
    def sampleModel(self):
        return self._sample_model

    @Property('QVariant', notify=ringStructureChanged)
    def ringStructure(self):
        return self._ring_structure

    @Property('QVariant', notify=ballStructureChanged)
    def ballStructure(self):
        return self._ball_structure

    @Property('QVariant', notify=vesicleStructureChanged)
    def vesicleStructure(self):
        return self._vesicle_structure

    @Property('QVariant', notify=rodStructureChanged)
    def rodStructure(self):
        return self._rod_structure

    @Property('QVariant', notify=bilayerStructureChanged)
    def bilayerStructure(self):
        return self._bilayer_structure

    @Property('QVariant', notify=monolayerStructureChanged)
    def monolayerStructure(self):
        return self._monolayer_structure

    @Property('QVariant', notify=latticeStructureChanged)
    def latticeStructure(self):
        return self._lattice_structure

    @Property('QVariant', constant=True)
    def components(self):
        return self._components

    @Property('QVariant', notify=compositionChanged)
    def composition(self):
        return self._composition

    @Property('QVariant', notify=layersChanged)
    def layers(self):
        return self._layers

    @Property('QVariant', notify=lamellaeChanged)
    def lamellae(self):
        return self._lamellae

    @Property('QVariant', notify=bufferChanged)
    def buffer(self):
        return self._buffer

    def _adapt_structure(self):
        sample_model = self._session.sample_model
        structure = sample_model.structure if sample_model else None
        lattice = structure if isinstance(structure, Lattice) else None
        unit = lattice.unit if lattice else structure
        for adapter in (
            self._ring_structure,
            self._ball_structure,
            self._vesicle_structure,
            self._rod_structure,
            self._bilayer_structure,
            self._monolayer_structure,
            self._lattice_structure,
            self._composition,
            self._layers,
            self._lamellae,
            self._buffer,
        ):
            if adapter is not None:
                # Deleted after QML has re-read the new one
                adapter.deleteLater()
        self._ring_structure = RingStructure(unit, self) if type(unit) is Ring else None
        self._ball_structure = BallStructure(unit, self) if type(unit) is Ball else None
        self._vesicle_structure = VesicleStructure(unit, self) if type(unit) is Vesicle else None
        self._rod_structure = RodStructure(unit, self) if type(unit) is Rod else None
        self._bilayer_structure = BilayerStructure(unit, self) if type(unit) is Bilayer else None
        self._monolayer_structure = (
            MonolayerStructure(unit, self) if type(unit) is Monolayer else None
        )
        self._lattice_structure = LatticeStructure(lattice, self) if lattice else None
        # A ball or a vesicle keeps its compositions in layers and
        # lamellae
        composition = getattr(unit, 'composition', None)
        self._composition = (
            CompositionModel(composition, self) if composition is not None else None
        )
        self._layers = LayersModel(unit.layers, self) if type(unit) is Ball else None
        self._lamellae = LamellaeModel(unit.lamellae, self) if type(unit) is Vesicle else None
        # The sample model's, not the structure's: built here because a
        # new sample model comes with this signal too
        self._buffer = Buffer(sample_model.buffer, self) if sample_model else None
        # Adding, removing or renaming a component changes their
        # composition rows; the connections end when the model is
        # deleted
        for model in (self._composition, self._layers, self._lamellae):
            if model is not None:
                self._components.loaded.rowsInserted.connect(model.refresh)
                self._components.loaded.rowsRemoved.connect(model.refresh)
                self._components.loaded.dataChanged.connect(model.refresh)
        self.ringStructureChanged.emit()
        self.ballStructureChanged.emit()
        self.vesicleStructureChanged.emit()
        self.rodStructureChanged.emit()
        self.bilayerStructureChanged.emit()
        self.monolayerStructureChanged.emit()
        self.latticeStructureChanged.emit()
        self.compositionChanged.emit()
        self.layersChanged.emit()
        self.lamellaeChanged.emit()
        self.bufferChanged.emit()
