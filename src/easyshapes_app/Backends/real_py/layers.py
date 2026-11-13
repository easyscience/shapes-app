# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QAbstractListModel
from PySide6.QtCore import QModelIndex
from PySide6.QtCore import Qt
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot

from .composition import CompositionModel


class LayersModel(QAbstractListModel):
    """
    The current ball's layers as rows of an editable ListView, with one
    composition model per row, and the ball's full radius. A row's
    thickness, its longest bone, is read-only.

    The root builds it while the current structure, or the unit its
    lattice repeats, is a ball, and drops it on the next structure
    change. The page has no scaling: a scaled dmin or rmin (None in the
    library) gets the library default when the model is built, and so
    does an added layer's rmin that the library can't work out.
    """

    DminRole = Qt.UserRole + 1
    RminRole = Qt.UserRole + 2
    ThicknessRole = Qt.UserRole + 3

    countChanged = Signal()
    compositionsChanged = Signal()
    fullRadiusChanged = Signal()

    def __init__(self, ball, parent=None):
        super().__init__(parent)
        # The ball for its full radius, its layers for the rows
        self._ball = ball
        layers = ball.layers
        self._layers = layers
        # ponytail: the page has no scaling, so a scaled value becomes
        # the library default; keep it once the page can show scaling
        for layer in layers:
            if layer.dmin is None:
                layer.dmin = layers.DEFAULT_DMIN
            if layer.rmin is None:
                layer.rmin = layers.DEFAULT_RMIN
        # One per row, in row order
        self._compositions = [CompositionModel(layer.composition, self) for layer in layers]
        # A component ticked or given another ratio may change the
        # longest bone
        for composition in self._compositions:
            composition.dataChanged.connect(self._thickness_changed)

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        return {
            self.DminRole: b'dmin',
            self.RminRole: b'rmin',
            self.ThicknessRole: b'thickness',
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
            case self.ThicknessRole:
                # None while no component the layer places has a bone length
                return layer.thickness
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
                    # Only the last layer's counts, but a re-read is cheap
                    self.fullRadiusChanged.emit()
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

    @Property('QVariant', notify=fullRadiusChanged)
    def fullRadius(self):
        """
        The ball's full radius in nm: the last layer's rmin plus its
        thickness; None while that thickness is unknown.
        """
        return self._ball.outer_radius

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
        Add a layer over the structure components, and its composition
        model. The library stacks it on the layer before; a first layer
        gets the defaults.
        """
        row = len(self._layers)
        self.beginInsertRows(QModelIndex(), row, row)
        self._layers.add()
        # The library stacks a later layer on the one before, but leaves
        # its rmin unset when that layer has no bone length; the page
        # has no scaling to show that
        layer = self._layers[row]
        if layer.rmin is None:
            layer.rmin = self._layers.DEFAULT_RMIN
        self.endInsertRows()
        composition = CompositionModel(layer.composition, self)
        composition.dataChanged.connect(self._thickness_changed)
        self._compositions.append(composition)
        self.countChanged.emit()
        self.compositionsChanged.emit()
        # The new layer is the last one now
        self.fullRadiusChanged.emit()

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
        # The last layer may be another one now, or none
        self.fullRadiusChanged.emit()

    def refresh(self):
        """
        Show every row's composition and thickness after the components
        changed: the compositions follow them themselves, the views need
        telling.
        """
        for composition in self._compositions:
            composition.refresh()
        # A component's files or bone atoms may give it another bone
        # length
        self._thickness_changed()

    def _thickness_changed(self):
        # A bone length may have changed: any row's thickness, and so
        # the full radius
        if self.rowCount():
            last = self.index(self.rowCount() - 1)
            self.dataChanged.emit(self.index(0), last, [self.ThicknessRole])
        self.fullRadiusChanged.emit()
