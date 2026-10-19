# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal

from .logic import structure
from .logic.session import Session


class BilayerStructure(QObject):
    """
    The bilayer's fields for QML, while the structure, or the unit its
    lattice repeats, is a bilayer.

    For any other shape the fields read 0 and the setters do nothing:
    the page shows the bilayer group only for a bilayer.
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
        bilayer = self._bilayer()
        return bilayer.dmin if bilayer else 0.0

    @dmin.setter
    def dmin(self, value):
        bilayer = self._bilayer()
        if bilayer is None or bilayer.dmin == value:
            return
        bilayer.dmin = value
        self.dminChanged.emit()

    @Property(float, notify=zsepChanged)
    def zsep(self):
        bilayer = self._bilayer()
        return bilayer.zsep if bilayer else 0.0

    @zsep.setter
    def zsep(self, value):
        bilayer = self._bilayer()
        if bilayer is None or bilayer.zsep == value:
            return
        bilayer.zsep = value
        self.zsepChanged.emit()

    @Property(int, notify=nsideChanged)
    def nside(self):
        bilayer = self._bilayer()
        return bilayer.nside if bilayer else 0

    @nside.setter
    def nside(self, value):
        bilayer = self._bilayer()
        if bilayer is None or bilayer.nside == value:
            return
        bilayer.nside = value
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

    def _bilayer(self):
        return structure.shaped(self._session.sample_model, 'Bilayer')
