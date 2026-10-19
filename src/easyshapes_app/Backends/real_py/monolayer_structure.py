# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal

from .logic import structure
from .logic.session import Session


class MonolayerStructure(QObject):
    """
    The monolayer's fields for QML, while the structure, or the unit its
    lattice repeats, is a monolayer.

    For any other shape the fields read 0 and the setters do nothing:
    the page shows the monolayer group only for a monolayer.
    """

    dminChanged = Signal()
    zsepChanged = Signal()
    nsideChanged = Signal()

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session

    ##########################
    # GUI accessible variables
    ##########################

    @Property(float, notify=dminChanged)
    def dmin(self):
        monolayer = self._monolayer()
        return monolayer.dmin if monolayer else 0.0

    @dmin.setter
    def dmin(self, value):
        monolayer = self._monolayer()
        if monolayer is None or monolayer.dmin == value:
            return
        monolayer.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=zsepChanged)
    def zsep(self):
        monolayer = self._monolayer()
        return monolayer.zsep if monolayer else 0.0

    @zsep.setter
    def zsep(self, value):
        monolayer = self._monolayer()
        if monolayer is None or monolayer.zsep == value:
            return
        monolayer.zsep = value
        self.zsepChanged.emit()

    @Property(int, notify=nsideChanged)
    def nside(self):
        monolayer = self._monolayer()
        return monolayer.nside if monolayer else 0

    @nside.setter
    def nside(self, value):
        monolayer = self._monolayer()
        if monolayer is None or monolayer.nside == value:
            return
        monolayer.nside = value
        self.nsideChanged.emit()

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the structure was replaced.
        """
        self.dminChanged.emit()
        self.zsepChanged.emit()
        self.nsideChanged.emit()

    def _monolayer(self):
        return structure.shaped(self._session.sample_model, 'Monolayer')
