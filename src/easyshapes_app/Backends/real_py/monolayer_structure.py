# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
The monolayer shape's fields for QML.
"""

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class MonolayerStructure(QObject):
    """
    One monolayer's fields for QML.

    The monolayer is the structure, or the motif its lattice repeats.

    The root builds it while the current structure is a monolayer and
    drops it on the next structure change; for any other shape QML finds
    none. Its sizes are the library's, read-only: sizesChanged follows
    the fields here, and the components and fractions through the root.
    """

    dminChanged = Signal()
    zsepChanged = Signal()
    nsideChanged = Signal()
    sizesChanged = Signal()

    def __init__(self, monolayer, parent=None):
        super().__init__(parent)
        self._monolayer = monolayer
        # The width is nside sites dmin apart; the thickness is zsep, or
        # dmin, plus a bone on each side
        self.dminChanged.connect(self.sizesChanged)
        self.zsepChanged.connect(self.sizesChanged)
        self.nsideChanged.connect(self.sizesChanged)

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=dminChanged)
    def dmin(self):
        """
        The dmin value.
        """
        return self._monolayer.dmin

    @dmin.setter
    def dmin(self, value):
        if self._monolayer.dmin == value:
            return
        self._monolayer.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=zsepChanged)
    def zsep(self):
        """
        The zsep value.
        """
        return self._monolayer.zsep

    @zsep.setter
    def zsep(self, value):
        if self._monolayer.zsep == value:
            return
        self._monolayer.zsep = value
        self.zsepChanged.emit()

    @Property(int, notify=nsideChanged)
    def nside(self):
        """
        The number of sites along a side.
        """
        return self._monolayer.nside

    @nside.setter
    def nside(self, value):
        if self._monolayer.nside == value:
            return
        self._monolayer.nside = value
        self.nsideChanged.emit()

    @Property(float, notify=sizesChanged)
    def width(self):
        """
        The width: nside sites, dmin apart.
        """
        # nside sites dmin apart: always known
        return self._monolayer.width

    @Property('QVariant', notify=sizesChanged)
    def thickness(self):
        """
        The thickness, None while no component has a bone length.
        """
        # zsep, or dmin, plus the longest bone on each side; None while
        # no component has one
        return self._monolayer.thickness
