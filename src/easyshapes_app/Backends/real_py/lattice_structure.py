# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from shapes.project import Lattice

from .logic.session import Session


class LatticeStructure(QObject):
    """
    The lattice's fields for QML, while a lattice repeats the discrete
    structure. The unit's fields are on its shape's part.

    Without a lattice the fields read 0 or '' and the setters do
    nothing: the page shows the lattice group only for a lattice.
    """

    alphaChanged = Signal()
    thetaChanged = Signal()
    nlatxChanged = Signal()
    nlatyChanged = Signal()
    nlatzChanged = Signal()
    sbuffChanged = Signal()
    latticeTypeChanged = Signal()

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=alphaChanged)
    def alpha(self):
        lattice = self._lattice()
        return lattice.alpha if lattice else 0.0

    @alpha.setter
    def alpha(self, value):
        lattice = self._lattice()
        if lattice is None or lattice.alpha == value:
            return
        lattice.alpha = value
        self.alphaChanged.emit()

    @Property(float, notify=thetaChanged)
    def theta(self):
        lattice = self._lattice()
        return lattice.theta if lattice else 0.0

    @theta.setter
    def theta(self, value):
        lattice = self._lattice()
        if lattice is None or lattice.theta == value:
            return
        lattice.theta = value
        self.thetaChanged.emit()

    @Property(int, notify=nlatxChanged)
    def nlatx(self):
        lattice = self._lattice()
        return lattice.nlatx if lattice else 0

    @nlatx.setter
    def nlatx(self, value):
        lattice = self._lattice()
        if lattice is None or lattice.nlatx == value:
            return
        lattice.nlatx = value
        self.nlatxChanged.emit()

    @Property(int, notify=nlatyChanged)
    def nlaty(self):
        lattice = self._lattice()
        return lattice.nlaty if lattice else 0

    @nlaty.setter
    def nlaty(self, value):
        lattice = self._lattice()
        if lattice is None or lattice.nlaty == value:
            return
        lattice.nlaty = value
        self.nlatyChanged.emit()

    @Property(int, notify=nlatzChanged)
    def nlatz(self):
        lattice = self._lattice()
        return lattice.nlatz if lattice else 0

    @nlatz.setter
    def nlatz(self, value):
        lattice = self._lattice()
        if lattice is None or lattice.nlatz == value:
            return
        lattice.nlatz = value
        self.nlatzChanged.emit()

    @Property(float, notify=sbuffChanged)
    def sbuff(self):
        lattice = self._lattice()
        return lattice.sbuff if lattice else 0.0

    @sbuff.setter
    def sbuff(self, value):
        lattice = self._lattice()
        if lattice is None or lattice.sbuff == value:
            return
        lattice.sbuff = value
        self.sbuffChanged.emit()

    @Property(str, notify=latticeTypeChanged)
    def latticeType(self):
        lattice = self._lattice()
        return lattice.lattice_type.name if lattice else ''

    @latticeType.setter
    def latticeType(self, value):
        lattice = self._lattice()
        if lattice is None or lattice.lattice_type.name == value:
            return
        # The library takes a lattice ShapeType name as text
        lattice.lattice_type = value
        self.latticeTypeChanged.emit()

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the structure was replaced.
        """
        self.alphaChanged.emit()
        self.thetaChanged.emit()
        self.nlatxChanged.emit()
        self.nlatyChanged.emit()
        self.nlatzChanged.emit()
        self.sbuffChanged.emit()
        self.latticeTypeChanged.emit()

    def _lattice(self):
        sample_model = self._session.sample_model
        if sample_model is None or not isinstance(sample_model.structure, Lattice):
            return None
        return sample_model.structure
