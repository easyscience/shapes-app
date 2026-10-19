# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal

from .logic import structure
from .logic.session import Session


class RodStructure(QObject):
    """
    The rod's fields for QML, while the structure, or the unit its
    lattice repeats, is a rod.

    For any other shape the fields read 0 or False and the setters do
    nothing: the page shows the rod group only for a rod.
    """

    turnsChanged = Signal()
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

    @Property(int, notify=turnsChanged)
    def turns(self):
        rod = self._rod()
        return rod.turns if rod else 0

    @turns.setter
    def turns(self, value):
        rod = self._rod()
        if rod is None or rod.turns == value:
            return
        rod.turns = value
        self.turnsChanged.emit()

    @Property(float, notify=dminChanged)
    def dmin(self):
        rod = self._rod()
        return rod.dmin if rod else 0.0

    @dmin.setter
    def dmin(self, value):
        rod = self._rod()
        if rod is None or rod.dmin == value:
            return
        rod.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=rminChanged)
    def rmin(self):
        rod = self._rod()
        return rod.rmin if rod else 0.0

    @rmin.setter
    def rmin(self, value):
        rod = self._rod()
        if rod is None or rod.rmin == value:
            return
        rod.rmin = value
        self.rminChanged.emit()

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        rod = self._rod()
        return rod.fxz if rod else False

    @fxz.setter
    def fxz(self, value):
        rod = self._rod()
        if rod is None or rod.fxz == value:
            return
        rod.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        rod = self._rod()
        return rod.rev if rod else False

    @rev.setter
    def rev(self, value):
        rod = self._rod()
        if rod is None or rod.rev == value:
            return
        rod.rev = value
        self.revChanged.emit()

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the structure was replaced.
        """
        self.turnsChanged.emit()
        self.dminChanged.emit()
        self.rminChanged.emit()
        self.fxzChanged.emit()
        self.revChanged.emit()

    def _rod(self):
        return structure.shaped(self._session.sample_model, 'Rod')
