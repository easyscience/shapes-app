# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal

from .logic import structure
from .logic.session import Session


class VesicleStructure(QObject):
    """
    The vesicle's fields for QML, while the structure, or the unit its
    lattice repeats, is a vesicle. Its lamellae have their own part.

    For any other shape the fields read '' or False and the setters do
    nothing: the page shows the vesicle group only for a vesicle.
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
        vesicle = self._vesicle()
        return vesicle.fxz if vesicle else False

    @fxz.setter
    def fxz(self, value):
        vesicle = self._vesicle()
        if vesicle is None or vesicle.fxz == value:
            return
        vesicle.fxz = value
        self.fxzChanged.emit()

    @Property(bool, notify=revChanged)
    def rev(self):
        vesicle = self._vesicle()
        return vesicle.rev if vesicle else False

    @rev.setter
    def rev(self, value):
        vesicle = self._vesicle()
        if vesicle is None or vesicle.rev == value:
            return
        vesicle.rev = value
        self.revChanged.emit()

    @Property(str, notify=fillChanged)
    def fill(self):
        vesicle = self._vesicle()
        return vesicle.fill.name if vesicle else ''

    @fill.setter
    def fill(self, value):
        vesicle = self._vesicle()
        if vesicle is None or vesicle.fill.name == value:
            return
        # The library takes a Fill name as text
        vesicle.fill = value
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

    def _vesicle(self):
        return structure.shaped(self._session.sample_model, 'Vesicle')
