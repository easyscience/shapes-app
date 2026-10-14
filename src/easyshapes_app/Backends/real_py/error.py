# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import sys

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal


class Error(QObject):
    """
    The last uncaught exception, for the error dialog.

    Creating it sets report() as sys.excepthook. PySide6 sends there
    every exception raised in a getter, setter or slot that QML calls,
    so parts need no try/except.
    """

    messageChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._message = ''
        sys.excepthook = self.report

    @Property(str, notify=messageChanged)
    def message(self):
        return self._message

    # The dialog clears it on close, so the same error next time opens
    # the dialog again
    @message.setter
    def message(self, value):
        self._message = value
        self.messageChanged.emit()

    def report(self, exc_type, exc_value, exc_traceback):
        """
        Print the traceback as Python does, and show the exception in
        the dialog.
        """
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        self.message = f'{exc_type.__name__}: {exc_value}'
