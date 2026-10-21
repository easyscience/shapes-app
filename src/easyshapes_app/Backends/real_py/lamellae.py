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


class LamellaeModel(QAbstractListModel):
    """
    The current vesicle's lamellae as rows of an editable ListView, with
    one composition model per row and leaflet.

    The root builds it while the current structure, or the unit its
    lattice repeats, is a vesicle, and drops it on the next structure
    change. An outer leaflet model is None while its lamella is
    symmetric: both leaflets then hold the inner composition. The page
    has no scaling: a scaled rmin or dmin (None in the library) gets the
    library default when the model is built and on add.
    """

    RminRole = Qt.UserRole + 1
    ShellThicknessRole = Qt.UserRole + 2
    InnerLeafletDminRole = Qt.UserRole + 3
    OuterLeafletDminRole = Qt.UserRole + 4
    SymmetricRole = Qt.UserRole + 5

    countChanged = Signal()
    innerLeafletCompositionsChanged = Signal()
    outerLeafletCompositionsChanged = Signal()

    def __init__(self, lamellae, parent=None):
        super().__init__(parent)
        self._lamellae = lamellae
        # ponytail: the page has no scaling, so a scaled value becomes
        # the library default; keep it once the page can show scaling
        for lamella in lamellae:
            if lamella.rmin is None:
                lamella.rmin = Defaults.Shape.RMIN
            if lamella.inner_leaflet_dmin is None:
                lamella.inner_leaflet_dmin = Defaults.Shape.DMIN
            if lamella.outer_leaflet_dmin is None:
                lamella.outer_leaflet_dmin = Defaults.Shape.DMIN
        # One per row, in row order; an outer one is None while the
        # lamella is symmetric, its outer leaflet holding the inner
        # composition
        self._inner_compositions = [
            CompositionModel(lamella.inner_leaflet_composition, self) for lamella in lamellae
        ]
        self._outer_compositions = [
            None
            if lamella.symmetric
            else CompositionModel(lamella.outer_leaflet_composition, self)
            for lamella in lamellae
        ]

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        return {
            self.RminRole: b'rmin',
            self.ShellThicknessRole: b'shellThickness',
            self.InnerLeafletDminRole: b'innerLeafletDmin',
            self.OuterLeafletDminRole: b'outerLeafletDmin',
            self.SymmetricRole: b'symmetric',
        }

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._lamellae)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        lamella = self._lamellae[index.row()]
        match role:
            case self.RminRole:
                return lamella.rmin
            case self.ShellThicknessRole:
                return lamella.shell_thickness
            case self.InnerLeafletDminRole:
                return lamella.inner_leaflet_dmin
            case self.OuterLeafletDminRole:
                return lamella.outer_leaflet_dmin
            case self.SymmetricRole:
                return lamella.symmetric
            case _:
                return None

    def setData(self, index, value, role=Qt.EditRole):
        if not index.isValid():
            return False
        row = index.row()
        lamella = self._lamellae[row]
        match role:
            case self.RminRole:
                if lamella.rmin != value:
                    lamella.rmin = value
                    self.dataChanged.emit(index, index, [role])
                return True
            case self.ShellThicknessRole:
                if lamella.shell_thickness != value:
                    lamella.shell_thickness = value
                    self.dataChanged.emit(index, index, [role])
                return True
            case self.InnerLeafletDminRole:
                if lamella.inner_leaflet_dmin != value:
                    lamella.inner_leaflet_dmin = value
                    self.dataChanged.emit(index, index, [role])
                return True
            case self.OuterLeafletDminRole:
                if lamella.outer_leaflet_dmin != value:
                    lamella.outer_leaflet_dmin = value
                    self.dataChanged.emit(index, index, [role])
                return True
            case self.SymmetricRole:
                if lamella.symmetric != value:
                    # Sharing detaches the outer composition; splitting
                    # gives the outer leaflet a copy of the inner one
                    lamella.symmetric = value
                    if value:
                        self._outer_compositions[row].deleteLater()
                        self._outer_compositions[row] = None
                    else:
                        outer = lamella.outer_leaflet_composition
                        self._outer_compositions[row] = CompositionModel(outer, self)
                    self.dataChanged.emit(index, index, [role])
                    self.outerLeafletCompositionsChanged.emit()
                return True
            case _:
                return False

    ############
    # QML access
    ############

    @Property(int, notify=countChanged)
    def count(self):
        return self.rowCount()

    @Property('QVariantList', notify=innerLeafletCompositionsChanged)
    def innerLeafletCompositions(self):
        """
        One inner leaflet composition model per row, in row order.
        """
        return self._inner_compositions

    @Property('QVariantList', notify=outerLeafletCompositionsChanged)
    def outerLeafletCompositions(self):
        """
        One outer leaflet composition model per row, in row order; None
        while the lamella is symmetric.
        """
        return self._outer_compositions

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
        Add a symmetric lamella over the structure components, with the
        default rmin and dmins and its inner composition model.
        """
        row = len(self._lamellae)
        self.beginInsertRows(QModelIndex(), row, row)
        self._lamellae.add()
        # The library scales a later lamella; the page has no scaling,
        # so every lamella gets the defaults a first one gets
        lamella = self._lamellae[row]
        lamella.rmin = Defaults.Shape.RMIN
        lamella.inner_leaflet_dmin = Defaults.Shape.DMIN
        lamella.outer_leaflet_dmin = Defaults.Shape.DMIN
        self.endInsertRows()
        self._inner_compositions.append(CompositionModel(lamella.inner_leaflet_composition, self))
        # A new lamella is symmetric
        self._outer_compositions.append(None)
        self.countChanged.emit()
        self.innerLeafletCompositionsChanged.emit()
        self.outerLeafletCompositionsChanged.emit()

    @Slot(int)
    def remove(self, row):
        """
        Remove the lamella in a row and its composition models. The
        dropped compositions stop following the components.
        """
        lamella = self._lamellae[row]
        self.beginRemoveRows(QModelIndex(), row, row)
        self._lamellae.remove(row)
        self.endRemoveRows()
        # As a shape change does; a symmetric lamella's outer leaflet
        # holds the inner composition, detached once
        lamella.inner_leaflet_composition.detach()
        if not lamella.symmetric:
            lamella.outer_leaflet_composition.detach()
        self._inner_compositions.pop(row).deleteLater()
        outer = self._outer_compositions.pop(row)
        if outer is not None:
            outer.deleteLater()
        self.countChanged.emit()
        self.innerLeafletCompositionsChanged.emit()
        self.outerLeafletCompositionsChanged.emit()

    def refresh(self):
        """
        Show every leaflet's composition after the components changed:
        the compositions follow them themselves, the views need telling.
        """
        for composition in self._inner_compositions + self._outer_compositions:
            if composition is not None:
                composition.refresh()
