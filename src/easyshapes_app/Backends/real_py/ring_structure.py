# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class RingStructure(QObject):
    """
    One ring's fields for QML: the structure's, or the unit's its
    lattice repeats.

    The root builds it while the current structure is a ring and drops
    it on the next structure change; for any other shape QML finds none.
    """

    alphaChanged = Signal()
    thetaChanged = Signal()
    dminChanged = Signal()
    rminChanged = Signal()
    fxzChanged = Signal()
    revChanged = Signal()

    def __init__(self, ring, parent=None):
        super().__init__(parent)
        self._ring = ring

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=alphaChanged)
    def alpha(self):
        return self._ring.alpha

    @alpha.setter
    def alpha(self, value):
        if self._ring.alpha == value:
            return
        self._ring.alpha = value
        self.alphaChanged.emit()

    @Property(float, notify=thetaChanged)
    def theta(self):
        return self._ring.theta

    @theta.setter
    def theta(self, value):
        if self._ring.theta == value:
            return
        self._ring.theta = value
        self.thetaChanged.emit()

    @Property(float, notify=dminChanged)
    def dmin(self):
        return self._ring.dmin

    @dmin.setter
    def dmin(self, value):
        if self._ring.dmin == value:
            return
        self._ring.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=rminChanged)
    def rmin(self):
        return self._ring.rmin

    @rmin.setter
    def rmin(self, value):
        if self._ring.rmin == value:
            return
        self._ring.rmin = value
        self.rminChanged.emit()

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        return self._ring.fxz

    @fxz.setter
    def fxz(self, value):
        if self._ring.fxz == value:
            return
        self._ring.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        return self._ring.rev

    @rev.setter
    def rev(self, value):
        if self._ring.rev == value:
            return
        self._ring.rev = value
        self.revChanged.emit()
