# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal

from .logic import structure
from .logic.session import Session


class RingStructure(QObject):
    """
    The ring's fields for QML, while the structure, or the unit its
    lattice repeats, is a ring.

    For any other shape the fields read 0 or False and the setters do
    nothing: the page shows the ring group only for a ring.
    """

    alphaChanged = Signal()
    thetaChanged = Signal()
    dminChanged = Signal()
    rminChanged = Signal()
    fxzChanged = Signal()
    revChanged = Signal()

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=alphaChanged)
    def alpha(self):
        ring = self._ring()
        return ring.alpha if ring else 0.0

    @alpha.setter
    def alpha(self, value):
        ring = self._ring()
        if ring is None or ring.alpha == value:
            return
        ring.alpha = value
        self.alphaChanged.emit()

    @Property(float, notify=thetaChanged)
    def theta(self):
        ring = self._ring()
        return ring.theta if ring else 0.0

    @theta.setter
    def theta(self, value):
        ring = self._ring()
        if ring is None or ring.theta == value:
            return
        ring.theta = value
        self.thetaChanged.emit()

    @Property(float, notify=dminChanged)
    def dmin(self):
        ring = self._ring()
        return ring.dmin if ring else 0.0

    @dmin.setter
    def dmin(self, value):
        ring = self._ring()
        if ring is None or ring.dmin == value:
            return
        ring.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=rminChanged)
    def rmin(self):
        ring = self._ring()
        return ring.rmin if ring else 0.0

    @rmin.setter
    def rmin(self, value):
        ring = self._ring()
        if ring is None or ring.rmin == value:
            return
        ring.rmin = value
        self.rminChanged.emit()

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        ring = self._ring()
        return ring.fxz if ring else False

    @fxz.setter
    def fxz(self, value):
        ring = self._ring()
        if ring is None or ring.fxz == value:
            return
        ring.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        ring = self._ring()
        return ring.rev if ring else False

    @rev.setter
    def rev(self, value):
        ring = self._ring()
        if ring is None or ring.rev == value:
            return
        ring.rev = value
        self.revChanged.emit()

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the structure was replaced.
        """
        self.alphaChanged.emit()
        self.thetaChanged.emit()
        self.dminChanged.emit()
        self.rminChanged.emit()
        self.fxzChanged.emit()
        self.revChanged.emit()

    def _ring(self):
        return structure.shaped(self._session.sample_model, 'Ring')
