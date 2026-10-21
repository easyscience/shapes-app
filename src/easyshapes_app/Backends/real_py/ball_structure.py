# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class BallStructure(QObject):
    """
    One ball's fields for QML: the structure's, or the unit's its
    lattice repeats. Its layers are the root's layers model.

    The root builds it while the current structure is a ball and drops
    it on the next structure change; for any other shape QML finds none.
    """

    fxzChanged = Signal()
    revChanged = Signal()
    fillChanged = Signal()

    def __init__(self, ball, parent=None):
        super().__init__(parent)
        self._ball = ball

    ##########################
    # GUI accessible variables
    ##########################

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        return self._ball.fxz

    @fxz.setter
    def fxz(self, value):
        if self._ball.fxz == value:
            return
        self._ball.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        return self._ball.rev

    @rev.setter
    def rev(self, value):
        if self._ball.rev == value:
            return
        self._ball.rev = value
        self.revChanged.emit()

    @Property(str, notify=fillChanged)
    def fill(self):
        return self._ball.fill.name

    @fill.setter
    def fill(self, value):
        if self._ball.fill.name == value:
            return
        # The library takes a Fill name as text
        self._ball.fill = value
        self.fillChanged.emit()
