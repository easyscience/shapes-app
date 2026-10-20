# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class VesicleStructure(QObject):
    """
    One vesicle's fields for QML: the structure's, or the unit's its
    lattice repeats. Its lamellae have their own part.

    The root builds it while the current structure is a vesicle and
    drops it on the next structure change; for any other shape QML finds
    none.
    """

    fxzChanged = Signal()
    revChanged = Signal()
    fillChanged = Signal()

    def __init__(self, vesicle, parent=None):
        super().__init__(parent)
        self._vesicle = vesicle

    ##########################
    # GUI accessible variables
    ##########################

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        return self._vesicle.fxz

    @fxz.setter
    def fxz(self, value):
        if self._vesicle.fxz == value:
            return
        self._vesicle.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        return self._vesicle.rev

    @rev.setter
    def rev(self, value):
        if self._vesicle.rev == value:
            return
        self._vesicle.rev = value
        self.revChanged.emit()

    @Property(str, notify=fillChanged)
    def fill(self):
        return self._vesicle.fill.name

    @fill.setter
    def fill(self, value):
        if self._vesicle.fill.name == value:
            return
        # The library takes a Fill name as text
        self._vesicle.fill = value
        self.fillChanged.emit()
