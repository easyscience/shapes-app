# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
The ring shape's fields for QML.
"""

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class RingStructure(QObject):
    """
    One ring's fields for QML.

    The ring is the structure, or the motif its lattice repeats.

    The root builds it while the current structure is a ring and drops
    it on the next structure change; for any other shape QML finds none.
    Its sizes are the library's, read-only: sizesChanged follows the
    fields here, and the components and fractions through the root.
    """

    alphaChanged = Signal()
    thetaChanged = Signal()
    dminChanged = Signal()
    rminChanged = Signal()
    fxzChanged = Signal()
    revChanged = Signal()
    sizesChanged = Signal()

    def __init__(self, ring, parent=None):
        super().__init__(parent)
        self._ring = ring
        # The outer radius is rmin plus the longest bone
        self.rminChanged.connect(self.sizesChanged)

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=alphaChanged)
    def alpha(self):
        """
        The alpha angle.
        """
        return self._ring.alpha

    @alpha.setter
    def alpha(self, value):
        if self._ring.alpha == value:
            return
        self._ring.alpha = value
        self.alphaChanged.emit()

    @Property(float, notify=thetaChanged)
    def theta(self):
        """
        The theta angle.
        """
        return self._ring.theta

    @theta.setter
    def theta(self, value):
        if self._ring.theta == value:
            return
        self._ring.theta = value
        self.thetaChanged.emit()

    @Property(float, notify=dminChanged)
    def dmin(self):
        """
        The dmin value.
        """
        return self._ring.dmin

    @dmin.setter
    def dmin(self, value):
        if self._ring.dmin == value:
            return
        self._ring.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=rminChanged)
    def rmin(self):
        """
        The rmin value.
        """
        return self._ring.rmin

    @rmin.setter
    def rmin(self, value):
        if self._ring.rmin == value:
            return
        self._ring.rmin = value
        self.rminChanged.emit()

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        """
        The fxz flag.
        """
        return self._ring.fxz

    @fxz.setter
    def fxz(self, value):
        if self._ring.fxz == value:
            return
        self._ring.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        """
        The rev flag.
        """
        return self._ring.rev

    @rev.setter
    def rev(self, value):
        if self._ring.rev == value:
            return
        self._ring.rev = value
        self.revChanged.emit()

    @Property('QVariant', notify=sizesChanged)
    def outerRadius(self):
        """
        The outer radius, None while no component has a bone length.
        """
        # None while no component has a bone length; Alpha and Theta
        # don't tilt it
        return self._ring.outer_radius
