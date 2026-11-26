# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
The vesicle's lamellae as an editable list model for QML.
"""

from PySide6.QtCore import Property
from PySide6.QtCore import QAbstractListModel
from PySide6.QtCore import QModelIndex
from PySide6.QtCore import Qt
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot

from .composition import CompositionModel


class LamellaeModel(QAbstractListModel):
    """
    The current vesicle's lamellae as rows of an editable ListView, with
    one composition model per row and leaflet, and the vesicle's full
    radius. A row's shell shows rounded to 2 decimals; its outer leaflet
    rmin, worked out from rmin, shell and the outer leaflet's longest
    molecule, is read-only.

    The root builds it while the current structure, or the motif its
    lattice repeats, is a vesicle, and drops it on the next structure
    change. An outer leaflet model is None while its lamella is
    symmetric: both leaflets then hold the inner composition. The page
    has no scaling: a scaled rmin or dmin (None in the library) gets the
    library default when the model is built.
    """

    RminRole = Qt.UserRole + 1
    ShellThicknessRole = Qt.UserRole + 2
    InnerLeafletDminRole = Qt.UserRole + 3
    OuterLeafletDminRole = Qt.UserRole + 4
    SymmetricRole = Qt.UserRole + 5
    OuterLeafletRminRole = Qt.UserRole + 6

    countChanged = Signal()
    innerLeafletCompositionsChanged = Signal()
    outerLeafletCompositionsChanged = Signal()
    fullRadiusChanged = Signal()

    def __init__(self, vesicle, parent=None):
        super().__init__(parent)
        # The vesicle for its full radius, its lamellae for the rows
        self._vesicle = vesicle
        lamellae = vesicle.lamellae
        self._lamellae = lamellae
        # ponytail: the page has no scaling, so a scaled value becomes
        # the library default; keep it once the page can show scaling
        for lamella in lamellae:
            if lamella.rmin is None:
                lamella.rmin = lamellae.DEFAULT_RMIN
            if lamella.inner_leaflet_dmin is None:
                lamella.inner_leaflet_dmin = lamellae.DEFAULT_DMIN
            if lamella.outer_leaflet_dmin is None:
                lamella.outer_leaflet_dmin = lamellae.DEFAULT_DMIN
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
        # A component ticked in a leaflet may change the outer leaflet's
        # longest molecule, and so where that leaflet starts
        for composition in self._inner_compositions + self._outer_compositions:
            if composition is not None:
                composition.dataChanged.connect(self._outer_rmin_changed)

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        """
        Map each role to the name QML reads it by.
        """
        return {
            self.RminRole: b'rmin',
            self.ShellThicknessRole: b'shellThickness',
            self.InnerLeafletDminRole: b'innerLeafletDmin',
            self.OuterLeafletDminRole: b'outerLeafletDmin',
            self.SymmetricRole: b'symmetric',
            self.OuterLeafletRminRole: b'outerLeafletRmin',
        }

    def rowCount(self, parent=QModelIndex()):
        """
        Count the rows: one per lamella.
        """
        return 0 if parent.isValid() else len(self._lamellae)

    def data(self, index, role=Qt.DisplayRole):
        """
        Return one of a row's sizes, or whether it is symmetric.
        """
        if not index.isValid():
            return None
        lamella = self._lamellae[index.row()]
        match role:
            case self.RminRole:
                return lamella.rmin
            case self.ShellThicknessRole:
                return round(lamella.shell_thickness, 2)
            case self.InnerLeafletDminRole:
                return lamella.inner_leaflet_dmin
            case self.OuterLeafletDminRole:
                return lamella.outer_leaflet_dmin
            case self.SymmetricRole:
                return lamella.symmetric
            case self.OuterLeafletRminRole:
                return lamella.outer_leaflet_rmin
            case _:
                return None

    def setData(self, index, value, role=Qt.EditRole):
        """
        Write a row's rmin, shell, dmin or symmetry.
        """
        if not index.isValid():
            return False
        row = index.row()
        lamella = self._lamellae[row]
        match role:
            case self.RminRole:
                if lamella.rmin != value:
                    # The outer leaflet moves with it, the shell stays
                    lamella.rmin = value
                    self.dataChanged.emit(index, index, [role, self.OuterLeafletRminRole])
                    # Only the last lamella's counts, but a re-read is
                    # cheap
                    self.fullRadiusChanged.emit()
                return True
            case self.ShellThicknessRole:
                # Compared as shown: a cell left unchanged writes
                # nothing
                if round(lamella.shell_thickness, 2) != value:
                    lamella.shell_thickness = value
                    self.dataChanged.emit(index, index, [role, self.OuterLeafletRminRole])
                    self.fullRadiusChanged.emit()
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
                        composition = CompositionModel(outer, self)
                        composition.dataChanged.connect(self._outer_rmin_changed)
                        self._outer_compositions[row] = composition
                    # Shared, the outer leaflet takes the inner
                    # molecules
                    self.dataChanged.emit(index, index, [role, self.OuterLeafletRminRole])
                    self.outerLeafletCompositionsChanged.emit()
                return True
            case _:
                return False

    ############
    # QML access
    ############

    @Property(int, notify=countChanged)
    def count(self):
        """
        The number of rows.
        """
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

    @Property('QVariant', notify=fullRadiusChanged)
    def fullRadius(self):
        """
        The vesicle's full radius in nm: the last lamella's rmin plus
        its shell; None without a lamella.
        """
        return self._vesicle.outer_radius

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
        Add a symmetric lamella over the structure components, and its
        inner composition model. The library stacks it on the lamella
        before and works out its shell; a first lamella gets the
        defaults.
        """
        row = len(self._lamellae)
        self.beginInsertRows(QModelIndex(), row, row)
        self._lamellae.add()
        lamella = self._lamellae[row]
        self.endInsertRows()
        composition = CompositionModel(lamella.inner_leaflet_composition, self)
        composition.dataChanged.connect(self._outer_rmin_changed)
        self._inner_compositions.append(composition)
        # A new lamella is symmetric
        self._outer_compositions.append(None)
        self.countChanged.emit()
        self.innerLeafletCompositionsChanged.emit()
        self.outerLeafletCompositionsChanged.emit()
        # The new lamella is the last one now
        self.fullRadiusChanged.emit()

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
        # The last lamella may be another one now, or none
        self.fullRadiusChanged.emit()

    def refresh(self):
        """
        Show every leaflet's composition and outer rmin after the
        components changed: the compositions follow them themselves, the
        views need telling.
        """
        for composition in self._inner_compositions + self._outer_compositions:
            if composition is not None:
                composition.refresh()
        # A component's files may give it another molecule length
        self._outer_rmin_changed()

    def _outer_rmin_changed(self):
        # An outer leaflet's longest molecule may have changed: the
        # shell stays, so that leaflet starts elsewhere in any row
        if self.rowCount():
            last = self.index(self.rowCount() - 1)
            self.dataChanged.emit(self.index(0), last, [self.OuterLeafletRminRole])
