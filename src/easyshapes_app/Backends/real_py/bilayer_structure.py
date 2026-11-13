# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class BilayerStructure(QObject):
    """
    One bilayer's fields for QML: the structure's, or the unit's its
    lattice repeats.

    The root builds it while the current structure is a bilayer and
    drops it on the next structure change; for any other shape QML finds
    none. Its sizes are the library's, read-only: sizesChanged follows
    the fields here, and the components and fractions through the root.
    """

    dminChanged = Signal()
    zsepChanged = Signal()
    nsideChanged = Signal()
    sizesChanged = Signal()

    def __init__(self, bilayer, parent=None):
        super().__init__(parent)
        self._bilayer = bilayer
        # The width is nside sites dmin apart; the thickness is zsep, or
        # grows with dmin
        self.dminChanged.connect(self.sizesChanged)
        self.zsepChanged.connect(self.sizesChanged)
        self.nsideChanged.connect(self.sizesChanged)

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=dminChanged)
    def dmin(self):
        return self._bilayer.dmin

    @dmin.setter
    def dmin(self, value):
        if self._bilayer.dmin == value:
            return
        self._bilayer.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=zsepChanged)
    def zsep(self):
        return self._bilayer.zsep

    @zsep.setter
    def zsep(self, value):
        if self._bilayer.zsep == value:
            return
        self._bilayer.zsep = value
        self.zsepChanged.emit()

    @Property(int, notify=nsideChanged)
    def nside(self):
        return self._bilayer.nside

    @nside.setter
    def nside(self, value):
        if self._bilayer.nside == value:
            return
        self._bilayer.nside = value
        self.nsideChanged.emit()

    @Property(float, notify=sizesChanged)
    def width(self):
        # nside sites dmin apart: always known
        return self._bilayer.width

    @Property('QVariant', notify=sizesChanged)
    def thickness(self):
        # zsep when set, else dmin plus a bone on each side; None while
        # neither is known
        return self._bilayer.thickness
