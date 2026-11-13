# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class RodStructure(QObject):
    """
    One rod's fields for QML: the structure's, or the unit's its lattice
    repeats.

    The root builds it while the current structure is a rod and drops it
    on the next structure change; for any other shape QML finds none.
    Its sizes are the library's, read-only: sizesChanged follows the
    fields here, and the components and fractions through the root.
    """

    turnsChanged = Signal()
    dminChanged = Signal()
    rminChanged = Signal()
    fxzChanged = Signal()
    revChanged = Signal()
    sizesChanged = Signal()

    def __init__(self, rod, parent=None):
        super().__init__(parent)
        self._rod = rod
        # The length stacks turns rings dmin apart; both sizes grow
        # with rmin
        self.turnsChanged.connect(self.sizesChanged)
        self.dminChanged.connect(self.sizesChanged)
        self.rminChanged.connect(self.sizesChanged)

    ##########################
    # GUI accessible variables
    ##########################

    @Property(int, notify=turnsChanged)
    def turns(self):
        return self._rod.turns

    @turns.setter
    def turns(self, value):
        if self._rod.turns == value:
            return
        self._rod.turns = value
        self.turnsChanged.emit()

    @Property(float, notify=dminChanged)
    def dmin(self):
        return self._rod.dmin

    @dmin.setter
    def dmin(self, value):
        if self._rod.dmin == value:
            return
        self._rod.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=rminChanged)
    def rmin(self):
        return self._rod.rmin

    @rmin.setter
    def rmin(self, value):
        if self._rod.rmin == value:
            return
        self._rod.rmin = value
        self.rminChanged.emit()

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        return self._rod.fxz

    @fxz.setter
    def fxz(self, value):
        if self._rod.fxz == value:
            return
        self._rod.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        return self._rod.rev

    @rev.setter
    def rev(self, value):
        if self._rod.rev == value:
            return
        self._rod.rev = value
        self.revChanged.emit()

    @Property('QVariant', notify=sizesChanged)
    def outerRadius(self):
        # None while no component has a bone length
        return self._rod.outer_radius

    @Property('QVariant', notify=sizesChanged)
    def length(self):
        # Cap tip to cap tip; None while the outer radius is unknown
        return self._rod.length
