# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QAbstractListModel
from PySide6.QtCore import QModelIndex
from PySide6.QtCore import Qt
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.basics.defaults import Defaults

from .composition import CompositionModel


class LayersModel(QAbstractListModel):
    """
    The current ball's layers as rows of an editable ListView, with one
    composition model per row.

    The root builds it while the current structure, or the unit its
    lattice repeats, is a ball, and drops it on the next structure
    change. The page has no scaling: a scaled dmin or rmin (None in the
    library) gets the library default when the model is built and on
    add.
    """

    DminRole = Qt.UserRole + 1
    RminRole = Qt.UserRole + 2

    countChanged = Signal()
    compositionsChanged = Signal()

    def __init__(self, layers, parent=None):
        super().__init__(parent)
        self._layers = layers
        # ponytail: the page has no scaling, so a scaled value becomes
        # the library default; keep it once the page can show scaling
        for layer in layers:
            if layer.dmin is None:
                layer.dmin = Defaults.Shape.DMIN
            if layer.rmin is None:
                layer.rmin = Defaults.Shape.RMIN
        # One per row, in row order
        self._compositions = [CompositionModel(layer.composition, self) for layer in layers]

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        return {
            self.DminRole: b'dmin',
            self.RminRole: b'rmin',
        }

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._layers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        layer = self._layers[index.row()]
        match role:
            case self.DminRole:
                return layer.dmin
            case self.RminRole:
                return layer.rmin
            case _:
                return None

    def setData(self, index, value, role=Qt.EditRole):
        if not index.isValid():
            return False
        layer = self._layers[index.row()]
        match role:
            case self.DminRole:
                if layer.dmin != value:
                    layer.dmin = value
                    self.dataChanged.emit(index, index, [role])
                return True
            case self.RminRole:
                if layer.rmin != value:
                    layer.rmin = value
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

    @Property('QVariantList', notify=compositionsChanged)
    def compositions(self):
        """
        One composition model per row, in row order.
        """
        return self._compositions

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

    @Slot()
    def add(self):
        """
        Add a layer over the structure components, with the default dmin
        and rmin and its composition model.
        """
        row = len(self._layers)
        self.beginInsertRows(QModelIndex(), row, row)
        self._layers.add()
        # The library scales a later layer; the page has no scaling, so
        # every layer gets the defaults a first one gets
        layer = self._layers[row]
        layer.dmin = Defaults.Shape.DMIN
        layer.rmin = Defaults.Shape.RMIN
        self.endInsertRows()
        self._compositions.append(CompositionModel(self._layers[row].composition, self))
        self.countChanged.emit()
        self.compositionsChanged.emit()

    @Slot(int)
    def remove(self, row):
        """
        Remove the layer in a row and its composition model. The dropped
        composition stops following the components.
        """
        layer = self._layers[row]
        self.beginRemoveRows(QModelIndex(), row, row)
        self._layers.remove(row)
        self.endRemoveRows()
        # As a shape change does; else the dropped composition keeps
        # following the components
        layer.composition.detach()
        self._compositions.pop(row).deleteLater()
        self.countChanged.emit()
        self.compositionsChanged.emit()

    def refresh(self):
        """
        Show every row's composition after the components changed: the
        compositions follow them themselves, the views need telling.
        """
        for composition in self._compositions:
            composition.refresh()
