# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class LatticeStructure(QObject):
    """
    One lattice's fields for QML. The unit's fields are on its shape's
    adapter.

    The root builds it while a lattice repeats the structure and drops
    it on the next structure change; without a lattice QML finds none.
    """

    alphaChanged = Signal()
    thetaChanged = Signal()
    nlatxChanged = Signal()
    nlatyChanged = Signal()
    nlatzChanged = Signal()
    sbuffChanged = Signal()
    latticeTypeChanged = Signal()

    def __init__(self, lattice, parent=None):
        super().__init__(parent)
        self._lattice = lattice

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=alphaChanged)
    def alpha(self):
        return self._lattice.alpha

    @alpha.setter
    def alpha(self, value):
        if self._lattice.alpha == value:
            return
        self._lattice.alpha = value
        self.alphaChanged.emit()

    @Property(float, notify=thetaChanged)
    def theta(self):
        return self._lattice.theta

    @theta.setter
    def theta(self, value):
        if self._lattice.theta == value:
            return
        self._lattice.theta = value
        self.thetaChanged.emit()

    @Property(int, notify=nlatxChanged)
    def nlatx(self):
        return self._lattice.nlatx

    @nlatx.setter
    def nlatx(self, value):
        if self._lattice.nlatx == value:
            return
        self._lattice.nlatx = value
        self.nlatxChanged.emit()

    @Property(int, notify=nlatyChanged)
    def nlaty(self):
        return self._lattice.nlaty

    @nlaty.setter
    def nlaty(self, value):
        if self._lattice.nlaty == value:
            return
        self._lattice.nlaty = value
        self.nlatyChanged.emit()

    @Property(int, notify=nlatzChanged)
    def nlatz(self):
        return self._lattice.nlatz

    @nlatz.setter
    def nlatz(self, value):
        if self._lattice.nlatz == value:
            return
        self._lattice.nlatz = value
        self.nlatzChanged.emit()

    @Property(float, notify=sbuffChanged)
    def sbuff(self):
        return self._lattice.sbuff

    @sbuff.setter
    def sbuff(self, value):
        if self._lattice.sbuff == value:
            return
        self._lattice.sbuff = value
        self.sbuffChanged.emit()

    @Property(str, notify=latticeTypeChanged)
    def latticeType(self):
        return self._lattice.lattice_type.name

    @latticeType.setter
    def latticeType(self, value):
        if self._lattice.lattice_type.name == value:
            return
        # The library takes a lattice ShapeType name as text
        self._lattice.lattice_type = value
        self.latticeTypeChanged.emit()
