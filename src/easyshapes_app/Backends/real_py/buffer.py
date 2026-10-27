# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QAbstractListModel
from PySide6.QtCore import QModelIndex
from PySide6.QtCore import QObject
from PySide6.QtCore import Qt
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project.species import Salt
from shapes.project.species import Solvent


class BufferComponentsModel(QAbstractListModel):
    """
    The buffer's components as rows of an editable ListView: a name and
    a concentration each.

    The page works in mM, as wet-lab protocols do; the library holds
    mol/L, so reads multiply by 1000 and writes divide. The Buffer part
    adds and removes rows.
    """

    NameRole = Qt.UserRole + 1
    ConcentrationRole = Qt.UserRole + 2

    countChanged = Signal()

    def __init__(self, components, parent=None):
        super().__init__(parent)
        self._components = components

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        return {
            self.NameRole: b'name',
            self.ConcentrationRole: b'concentration',
        }

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._components)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        component = self._components[index.row()]
        match role:
            case self.NameRole:
                return component.name
            case self.ConcentrationRole:
                # In mM, as the page shows it; the library holds mol/L.
                # Rounded: 0.0035 * 1000 is 3.5000000000000004
                return round(component.concentration * 1000, 6)
            case _:
                return None

    def setData(self, index, value, role=Qt.EditRole):
        if not index.isValid():
            return False
        component = self._components[index.row()]
        match role:
            case self.ConcentrationRole:
                if self.data(index, role) != value:
                    component.concentration = value / 1000
                    self.dataChanged.emit(index, index, [role])
                return True
            case _:
                return False

    ############
    # QML access
    ############

    @Property(int, notify=countChanged)
    def count(self):
        return self.rowCount()

    @Slot(int, result='QVariant')
    def get(self, row):
        """
        One row's roles by name, as ListModel.get gives them.
        """
        index = self.index(row)
        return {name.decode(): self.data(index, role) for role, name in self.roleNames().items()}

    #########
    # Changes
    #########

    def append(self, component):
        """
        Add a component as a new row.
        """
        # The library refuses a held name only inside append, after the
        # model has opened the new row: refuse before. The error dialog
        # shows it
        if component.name in self._components:
            raise ValueError(f'The buffer already holds {component.name}')
        row = len(self._components)
        self.beginInsertRows(QModelIndex(), row, row)
        self._components.append(component)
        self.endInsertRows()
        self.countChanged.emit()

    def remove(self, row):
        """
        Remove the component in a row.
        """
        self.beginRemoveRows(QModelIndex(), row, row)
        self._components.remove(row)
        self.endRemoveRows()
        self.countChanged.emit()


class Buffer(QObject):
    """
    One buffer's fields for QML: its solvent, by name, and its
    components.

    The root builds it over the current sample model's buffer and drops
    it on the next structure change; with no sample model QML finds
    none. Salts and solvents load from the library by name, and a salt
    imports from an export folder. A name the library lacks, or a salt
    already held, goes to the error dialog.
    """

    solventChanged = Signal()

    # The library classes salts and solvents load from; tests swap in
    # fakes
    _salt_class = Salt
    _solvent_class = Solvent

    def __init__(self, buffer, parent=None):
        super().__init__(parent)
        self._buffer = buffer
        self._components = BufferComponentsModel(buffer.components, self)

    @Property(str, notify=solventChanged)
    def solvent(self):
        """
        The solvent's name, '' for none.
        """
        return self._buffer.solvent.name if self._buffer.solvent else ''

    @solvent.setter
    def solvent(self, value):
        if self.solvent == value:
            return
        # '' takes no solvent; an unknown name goes to the error dialog
        self._buffer.solvent = self._solvent_class.load(value) if value else None
        self.solventChanged.emit()

    @Property('QVariant', constant=True)
    def components(self):
        return self._components

    @Slot(str)
    def appendComponent(self, name):
        """
        Load a salt from the library by name and add it as a new row.
        """
        self._components.append(self._salt_class.load(name))

    @Slot(str)
    def importFrom(self, folder):
        """
        Add the salt an export folder holds as a new row.
        """
        self._components.append(self._salt_class.import_from(folder))

    @Slot(int)
    def removeComponent(self, row):
        """
        Remove the component in a row.
        """
        self._components.remove(row)
