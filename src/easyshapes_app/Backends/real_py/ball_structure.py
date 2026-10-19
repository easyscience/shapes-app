# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal

from .logic import structure
from .logic.session import Session


class BallStructure(QObject):
    """
    The ball's fields for QML, while the structure, or the unit its
    lattice repeats, is a ball. Its layers have their own part.

    For any other shape the fields read '' or False and the setters do
    nothing: the page shows the ball group only for a ball.
    """

    fxzChanged = Signal()
    revChanged = Signal()
    fillChanged = Signal()

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session

    ##########################
    # GUI accessible variables
    ##########################

    @Property(bool, notify=fxzChanged)
    def fxz(self):
        ball = self._ball()
        return ball.fxz if ball else False

    @fxz.setter
    def fxz(self, value):
        ball = self._ball()
        if ball is None or ball.fxz == value:
            return
        ball.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        ball = self._ball()
        return ball.rev if ball else False

    @rev.setter
    def rev(self, value):
        ball = self._ball()
        if ball is None or ball.rev == value:
            return
        ball.rev = value
        self.revChanged.emit()

    @Property(str, notify=fillChanged)
    def fill(self):
        ball = self._ball()
        return ball.fill.name if ball else ''

    @fill.setter
    def fill(self, value):
        ball = self._ball()
        if ball is None or ball.fill.name == value:
            return
        # The library takes a Fill name as text
        ball.fill = value
        self.fillChanged.emit()

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the structure was replaced.
        """
        self.fxzChanged.emit()
        self.revChanged.emit()
        self.fillChanged.emit()

    def _ball(self):
        return structure.shaped(self._session.sample_model, 'Ball')
