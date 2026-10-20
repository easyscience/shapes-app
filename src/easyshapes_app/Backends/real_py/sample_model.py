# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project import SampleModel as SampleModelLib

from .logic import structure
from .logic.session import Session


class SampleModel(QObject):
    """
    The session's sample model for QML: its name, the shape of its
    structure, and whether a lattice repeats it.

    Fields read '' or False while there is no sample model. Continue on
    the Project page creates one; a project create or load brings its
    own.
    """

    nameChanged = Signal()
    shapeChanged = Signal()
    latticeChanged = Signal()

    # The structure was replaced: the root tells the shape parts
    externalStructureChanged = Signal()

    # The library class create builds; tests swap in a fake
    _sample_model_class = SampleModelLib

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session

    ##########################
    # GUI accessible variables
    ##########################

    @Property(str, notify=nameChanged)
    def name(self):
        sample_model = self._session.sample_model
        return sample_model.name if sample_model else ''

    @name.setter
    def name(self, value):
        sample_model = self._session.sample_model
        if sample_model is None or sample_model.name == value:
            return
        sample_model.name = value
        self.nameChanged.emit()

    @Property('QVariant', constant=True)
    def shapes(self):
        return list(structure.SHAPES)

    @Property(str, notify=shapeChanged)
    def shape(self):
        sample_model = self._session.sample_model
        return structure.shape(sample_model) if sample_model else ''

    @shape.setter
    def shape(self, value):
        if self._session.sample_model is None or self.shape == value:
            return
        structure.set_shape(self._session.sample_model, value)
        self.shapeChanged.emit()
        self.externalStructureChanged.emit()

    @Property(bool, notify=latticeChanged)
    def lattice(self):
        sample_model = self._session.sample_model
        return structure.is_lattice(sample_model) if sample_model else False

    @lattice.setter
    def lattice(self, value):
        if self._session.sample_model is None or self.lattice == value:
            return
        structure.set_lattice(self._session.sample_model, value)
        self.latticeChanged.emit()
        self.externalStructureChanged.emit()

    ##########################
    # GUI accessible functions
    ##########################

    @Slot()
    def create(self):
        """
        Give the session a new sample model, unless it has one.
        """
        if self._session.sample_model is not None:
            return
        self._session.sample_model = self._sample_model_class()
        self.refresh()

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the session holds another sample model.
        """
        self.nameChanged.emit()
        self.shapeChanged.emit()
        self.latticeChanged.emit()
        self.externalStructureChanged.emit()
