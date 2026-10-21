# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class MonolayerStructure(QObject):
    """
    One monolayer's fields for QML: the structure's, or the unit's its
    lattice repeats.

    The root builds it while the current structure is a monolayer and
    drops it on the next structure change; for any other shape QML finds
    none.
    """

    dminChanged = Signal()
    zsepChanged = Signal()
    nsideChanged = Signal()

    def __init__(self, monolayer, parent=None):
        super().__init__(parent)
        self._monolayer = monolayer

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=dminChanged)
    def dmin(self):
        return self._monolayer.dmin

    @dmin.setter
    def dmin(self, value):
        if self._monolayer.dmin == value:
            return
        self._monolayer.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=zsepChanged)
    def zsep(self):
        return self._monolayer.zsep

    @zsep.setter
    def zsep(self, value):
        if self._monolayer.zsep == value:
            return
        self._monolayer.zsep = value
        self.zsepChanged.emit()

    @Property(int, notify=nsideChanged)
    def nside(self):
        return self._monolayer.nside

    @nside.setter
    def nside(self, value):
        if self._monolayer.nside == value:
            return
        self._monolayer.nside = value
        self.nsideChanged.emit()
