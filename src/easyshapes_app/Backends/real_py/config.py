# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from shapes.project.files import AppFileManager


class Config(QObject):
    """
    GROMACS status for QML, from the config the file manager reads.
    """

    @Property(str, constant=True)
    def gmxVersion(self):
        """
        GROMACS version, or '' when the program can't be run.
        """
        return AppFileManager().config.gmx_version or ''

    @Property(str, constant=True)
    def gmxProblem(self):
        """
        Why GROMACS can't be run, for the status bar; '' when it can.
        """
        return AppFileManager().config.gmx_problem or ''
