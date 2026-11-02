# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np
from PySide6.QtCore import Property
from PySide6.QtCore import QByteArray
from PySide6.QtCore import Signal
from PySide6.QtQuick3D import QQuick3DInstancing
from shapes.basics.mendeleyev import Chemistry

# CPK colour and van der Waals radius (Å), as in MoleculeSketch.qml
_CPK = {
    'H': ('#ffffff', 1.20),
    'C': ('#909090', 1.70),
    'N': ('#3050f8', 1.55),
    'O': ('#ff0d0d', 1.52),
    'P': ('#ff8000', 1.80),
    'S': ('#ffff30', 1.80),
    'F': ('#90e050', 1.47),
    'Cl': ('#1ff01f', 1.75),
    'Br': ('#a62929', 1.85),
    'Na': ('#ab5cf2', 2.27),
    'K': ('#8f40d4', 2.75),
    'Ca': ('#3dff00', 2.31),
    'Mg': ('#8aff00', 1.73),
}
_OTHER = ('#ff40ff', 1.6)
# Sphere radius = 0.4 x the van der Waals radius, as in the viewers
_ATOM_SCALE = 0.4
# Bond radius, Å, as in MoleculeSketch.qml
_BOND_RADIUS = 0.15
# The slab's starting width, as a share of the structure's size
_FRACTION = 0.05


def _linear(colour):
    """
    An sRGB hex colour as linear RGB, as Qt hands colours to shaders.
    """
    rgb = np.array([int(colour[i : i + 2], 16) / 255 for i in (1, 3, 5)])
    return np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)


class _Table(QQuick3DInstancing):
    """
    An instance table made elsewhere: Qt reads what set() was given.
    """

    def __init__(self):
        super().__init__()
        self._table = QByteArray()
        self._count = 0

    def set(self, table):
        self._table = QByteArray(table.tobytes())
        self._count = len(table)
        self.markDirty()

    def getInstanceBuffer(self):
        return self._table, self._count


class StructureInstancing(QQuick3DInstancing):
    """
    A structure's atoms as the instance table of the structure viewer:
    one row per atom in the slab, the atoms within half its width of the
    centre plane across an axis.

    Only the slab reaches the GPU: its atoms and, with bonds, those with
    both atoms in it, each as two halves in its atom's colour
    (bondInstancing); slabRows says how many rows they take. Keeps the
    atoms as positions and one style row per distinct atom name, not as
    table rows, so millions of atoms take little memory.
    """

    atomsChanged = Signal()
    slabChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        # Å, centred on the bounds
        self._xyz = np.zeros((0, 3), np.float32)
        # Each atom's row in _style
        self._kind = np.zeros(0, np.intp)
        # Per distinct atom name: linear RGBA, radius
        self._style = np.zeros((0, 5), np.float32)
        self._axis = 2
        self._fraction = _FRACTION
        self._table = QByteArray()
        self._slab = 0
        self._shown = 0
        self._rows = 0
        # Pairs of atom indices
        self._bonds = np.zeros((0, 2), np.int32)
        # No parent: a Quick 3D object takes only a Quick 3D parent;
        # this reference keeps it alive
        self._bond_table = _Table()

    def set_atoms(self, names, xyz, bonds=None):
        """
        Show atoms by GRO name (5-byte strings) and position in nm, and
        the bonds between them as pairs of atom indices.
        """
        # One element lookup per distinct name: POPC has 134
        unique, self._kind = np.unique(names, return_inverse=True)
        styles = [
            _CPK.get(Chemistry.getElement(name.decode().strip()) or '', _OTHER) for name in unique
        ]
        self._style = np.array(
            [[*_linear(colour), 1.0, _ATOM_SCALE * radius] for colour, radius in styles],
            np.float32,
        ).reshape(-1, 5)
        xyz = xyz * 10.0  # nm -> Å
        if len(xyz):
            xyz = xyz - (xyz.max(axis=0) + xyz.min(axis=0)) / 2
        self._xyz = xyz
        self._bonds = np.zeros((0, 2), np.int32) if bonds is None else bonds
        self.atomsChanged.emit()
        self._update()

    def clear(self):
        """
        Drop the atoms, and set the slab back to its starting width.
        """
        self._fraction = _FRACTION
        self.set_atoms(np.zeros(0, 'S5'), np.zeros((0, 3), np.float32))

    @Property(int, notify=atomsChanged)
    def atomCount(self):
        return len(self._xyz)

    @Property(float, notify=atomsChanged)
    def radius(self):
        """
        The farthest atom centre from the centre, Å: the camera fits it.
        """
        return float(np.linalg.norm(self._xyz, axis=1).max(initial=0.0))

    @Property('QVariant', constant=True)
    def bondInstancing(self):
        """
        The slab's bond halves, as an instance table of their own.
        """
        return self._bond_table

    @Property(int, notify=slabChanged)
    def slabRows(self):
        """
        The rows the slab takes on the GPU: one an atom, two a bond, 80
        bytes each.
        """
        return self._rows

    @Property(int, notify=slabChanged)
    def slabCount(self):
        """
        The atoms in the slab.
        """
        return self._slab

    @Property(int, notify=slabChanged)
    def shownCount(self):
        """
        The atoms sent to the GPU: the slab's.
        """
        return self._shown

    @Property(int, notify=slabChanged)
    def slabAxis(self):
        """
        The axis the slab is cut across: 0, 1, 2 for X, Y, Z.
        """
        return self._axis

    @slabAxis.setter
    def slabAxis(self, value):
        if self._axis != value:
            self._axis = value
            self._update()

    @Property(float, notify=slabChanged)
    def slabFraction(self):
        """
        The slab's width as a share of the structure's size across the
        axis, 0 to 1.
        """
        return self._fraction

    @slabFraction.setter
    def slabFraction(self, value):
        if self._fraction != value:
            self._fraction = value
            self._update()

    def getInstanceBuffer(self):
        # Qt asks after markDirty: the table _update made, and its rows
        return self._table, self._shown

    def _update(self):
        """
        Pick the slab's atoms and pack them as Qt's instance table.
        """
        across = np.abs(self._xyz[:, self._axis])
        half = self._fraction * across.max(initial=0.0)
        shown = np.flatnonzero(across <= half)
        # The bonds with both atoms in the slab
        inside = np.zeros(len(self._xyz), bool)
        inside[shown] = True
        bonds = self._bonds[inside[self._bonds].all(axis=1)]
        self._slab = len(shown)
        self._rows = len(shown) + 2 * len(bonds)
        style = self._style[self._kind[shown]]
        # One 80-byte row per atom, as Qt reads it: three rows of the
        # 3x4 transform (scale on the diagonal, position last), then the
        # colour, then 4 unused floats
        table = np.zeros((len(shown), 20), np.float32)
        table[:, 0] = table[:, 5] = table[:, 10] = style[:, 4]
        table[:, [3, 7, 11]] = self._xyz[shown]
        table[:, 12:16] = style[:, :4]
        self._table = QByteArray(table.tobytes())
        self._shown = len(shown)
        self._bond_table.set(self._bond_rows(bonds))
        self.slabChanged.emit()
        self.markDirty()

    def _bond_rows(self, bonds):
        """
        The table of bonds given as pairs of atom indices: two rows a
        bond, one half from each atom to the middle, in its colour.
        """
        # Each bond's two atoms in turn
        ends = bonds.ravel()
        start = self._xyz[ends]
        middle = np.repeat(self._xyz[bonds].mean(axis=1), 2, axis=0)
        # As the atoms' rows, but the shader takes the half from the
        # position (its start) and the last 4 floats (the way to the
        # middle, then the radius)
        table = np.zeros((len(ends), 20), np.float32)
        table[:, 0] = table[:, 5] = table[:, 10] = _BOND_RADIUS
        table[:, [3, 7, 11]] = start
        table[:, 12:16] = self._style[self._kind[ends], :4]
        table[:, 16:19] = middle - start
        table[:, 19] = _BOND_RADIUS
        return table
