# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QAbstractListModel
from PySide6.QtCore import QModelIndex
from PySide6.QtCore import Qt
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot


class CompositionModel(QAbstractListModel):
    """
    One composition as rows of an editable ListView: one per component,
    in component order.

    Only a ring, rod, bilayer or monolayer has a composition. The root
    builds this model over the current one, and drops it on the next
    structure change. A molRatio of 0 marks the component absent and
    keeps its stored ratio, as the library does.
    """

    NameRole = Qt.UserRole + 1
    PresentRole = Qt.UserRole + 2
    MolRatioRole = Qt.UserRole + 3

    countChanged = Signal()

    def __init__(self, composition, parent=None):
        super().__init__(parent)
        self._composition = composition

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        return {
            self.NameRole: b'name',
            self.PresentRole: b'present',
            self.MolRatioRole: b'molRatio',
        }

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._composition)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        component, present, ratio = self._composition.items[index.row()]
        match role:
            case self.NameRole:
                return component.name
            case self.PresentRole:
                return present
            case self.MolRatioRole:
                return ratio
            case _:
                return None

    def setData(self, index, value, role=Qt.EditRole):
        if not index.isValid():
            return False
        component, present, ratio = self._composition.items[index.row()]
        match role:
            case self.PresentRole:
                self._composition.set_presence(component, value)
            case self.MolRatioRole:
                # 0 marks the component absent; a negative ratio raises
                # ValueError, which the page's validator keeps out
                self._composition.set_mol_ratio(component, value)
            case _:
                return False
        _, new_present, new_ratio = self._composition.items[index.row()]
        roles = []
        if new_present != present:
            roles.append(self.PresentRole)
        if new_ratio != ratio:
            roles.append(self.MolRatioRole)
        if roles:
            self.dataChanged.emit(index, index, roles)
        return True

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

    def refresh(self):
        """
        Show the rows after the components changed: the composition
        follows them itself, the view needs telling.
        """
        self.beginResetModel()
        self.endResetModel()
        self.countChanged.emit()
