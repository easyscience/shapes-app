# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause


from PySide6.QtCore import QObject, Signal, Property


class Status(QObject):
    projectChanged = Signal()
    engineChanged = Signal()

    def __init__(self):
        super().__init__()
        self._project = 'Undefined'
        self._engine = 'GROMACS'

    ##########################
    # GUI accessible variables
    ##########################

    @Property(str, notify=projectChanged)
    def project(self):
        return self._project

    @project.setter
    def project(self, new_value):
        if self._project == new_value:
            return
        self._project = new_value
        self.projectChanged.emit()

    @Property(str, notify=engineChanged)
    def engine(self):
        return self._engine

    @engine.setter
    def engine(self, new_value):
        if self._engine == new_value:
            return
        self._engine = new_value
        self.engineChanged.emit()
