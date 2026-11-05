# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot

from .logic.report import outline
from .logic.session import Session


class Report(QObject):
    """
    The Summary page's text: the session's project as an outline of what
    its save writes, until shapespyer's Project.summary is written.

    The page calls refresh each time it comes to the front, so the text
    holds the latest changes without a signal from every part. When the
    library can't serialize the project, error says why, and the page
    shows it in red in place of the text.
    """

    # The text or the error changed
    textChanged = Signal()

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        self._text = ''
        self._error = ''

    @Property(str, notify=textChanged)
    def text(self):
        return self._text

    @Property(str, notify=textChanged)
    def error(self):
        """
        Why the project can't be outlined; '' when it can.
        """
        return self._error

    @Slot()
    def refresh(self):
        """
        Read the session's project again; '' without one.
        """
        project = self._session.project
        try:
            text, error = (outline(project.to_dict()) if project else ''), ''
        # to_dict's refusals: an attribute it can't find or serialize
        except (KeyError, TypeError, ValueError) as err:
            text, error = '', f"The project can't be summarized: {err}"
        if (text, error) != (self._text, self._error):
            self._text, self._error = text, error
            self.textChanged.emit()
