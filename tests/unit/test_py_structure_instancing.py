# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np
import pytest

from easyshapes_app.Backends.real_py.structure_instancing import StructureInstancing
from easyshapes_app.Backends.real_py.structure_instancing import _linear


def instancing(xyz, names=None):
    """
    Carbons, or the named atoms, at positions in nm.
    """
    names = names or [b'    C'] * len(xyz)
    shown = StructureInstancing()
    shown.set_atoms(np.array(names, 'S5'), np.array(xyz, np.float32))
    return shown


def rows(shown):
    table, count = shown.getInstanceBuffer()
    return count, np.frombuffer(table.data(), np.float32).reshape(-1, 20)


# Along z, in Å once centred: -10, -0.2, 0.3, 10; at 5% the slab is
# 0.5 Å either side of the centre plane
ALONG_Z = [[0, 0, -1], [0, 0, -0.02], [0, 0, 0.03], [0, 0, 1]]


def test_the_slab_holds_the_atoms_near_the_centre_plane(qcore_application):
    shown = instancing(ALONG_Z)

    assert (shown.atomCount, shown.slabCount, shown.shownCount) == (4, 2, 2)
    assert shown.radius == pytest.approx(10)

    shown.slabFraction = 1.0
    assert shown.shownCount == 4

    # Every atom lies on the plane across x
    shown.slabFraction = 0.05
    shown.slabAxis = 0
    assert shown.shownCount == 4


def test_rows_hold_the_radius_the_position_and_the_colour(qcore_application):
    shown = instancing([[0, 0, 0], [1, 0, 0]], names=[b'    C', b'   O1'])

    count, table = rows(shown)

    assert count == 2
    # Centred on the bounds, in Å
    assert table[:, [3, 7, 11]] == pytest.approx(np.array([[-5, 0, 0], [5, 0, 0]]))
    assert table[:, [0, 5, 10]] == pytest.approx(np.array([[0.68] * 3, [0.608] * 3]))
    assert table[0, 12:16] == pytest.approx([*_linear('#909090'), 1.0])
    assert table[1, 12:16] == pytest.approx([*_linear('#ff0d0d'), 1.0])


def test_bonds_in_the_slab_come_as_two_halves_in_their_atoms_colours(qcore_application):
    names = np.array([b'    C', b'   O1', b'   H1', b'   H2'], 'S5')
    # In Å once centred: C and O 1 Å apart on the centre plane, the Hs
    # 10 Å off it, outside the 0.5 Å slab
    xyz = np.array([[0, 0, 0], [0.1, 0, 0], [0, 0, 1], [0, 0, -1]], np.float32)
    shown = StructureInstancing()
    shown.set_atoms(names, xyz, np.array([[0, 1], [0, 2]], np.int32))

    count, table = rows(shown.bondInstancing)

    # Only C-O: the H is outside the slab
    assert count == 2
    assert table[:, [3, 7, 11]] == pytest.approx(np.array([[-0.5, 0, 0], [0.5, 0, 0]]))
    assert table[:, 16:19] == pytest.approx(np.array([[0.5, 0, 0], [-0.5, 0, 0]]))
    assert table[:, 19] == pytest.approx([0.15, 0.15])
    assert table[0, 12:16] == pytest.approx([*_linear('#909090'), 1.0])
    assert table[1, 12:16] == pytest.approx([*_linear('#ff0d0d'), 1.0])
    # Two atoms, two halves
    assert shown.slabRows == 4

    shown.set_atoms(names, xyz)

    assert (shown.slabRows, shown.shownCount, rows(shown.bondInstancing)[0]) == (2, 2, 0)


# In Å: SDS at x 0 and 2 on the centre plane, water 10 off it either
# side along z
MIXED = [[0, 0, 0], [0.2, 0, 0], [0, 0, -1], [0, 0, 1]]
RESIDUES = [b'SDS', b'SDS', b'TIP3', b'TIP3']


def residue_instancing(xyz=MIXED, residues=RESIDUES, bonds=None):
    """
    Carbons at positions in nm, each of a residue.
    """
    shown = StructureInstancing()
    shown.set_atoms(
        np.array([b'    C'] * len(xyz), 'S5'),
        np.array(xyz, np.float32),
        None if bonds is None else np.array(bonds, np.int32),
        np.array(residues, 'S5'),
    )
    return shown


def residue_rows(shown):
    residues = shown.residues
    roles = (residues.NameRole, residues.CountRole, residues.ShownRole)
    return [
        tuple(residues.data(residues.index(row), role) for role in roles)
        for row in range(residues.count)
    ]


def test_residues_are_listed_with_their_atom_counts_all_shown(qcore_application):
    assert residue_rows(residue_instancing()) == [('SDS', 2, True), ('TIP3', 2, True)]
    # Without residue names: no rows, every atom drawn
    unnamed = instancing(ALONG_Z)
    assert (unnamed.residues.count, unnamed.slabCount) == (0, 2)


def test_an_unticked_residue_is_not_drawn_and_the_rest_is_framed(qcore_application):
    shown = residue_instancing(bonds=[[0, 1], [0, 2]])
    shown.slabFraction = 1.0
    # Centred on all four: the waters 10 Å from the centre, sideways 1
    before = (shown.shownCount, shown.radius, shown.slabRows)

    residues = shown.residues
    residues.setData(residues.index(1), False, residues.ShownRole)
    count, table = rows(shown)

    assert before == (4, pytest.approx(101**0.5), 8)
    # Centred on the SDS: 1 Å either side, and only their bond
    assert (count, shown.radius, residues.shownCount) == (2, pytest.approx(1), 1)
    assert table[:, 3] == pytest.approx([-1, 1])
    assert (rows(shown.bondInstancing)[0], shown.slabRows) == (2, 4)


def test_select_all_shows_or_hides_every_residue(qcore_application):
    shown = residue_instancing()

    shown.residues.setAllShown(False)
    none = (shown.shownCount, shown.residues.shownCount)
    shown.residues.setAllShown(True)

    assert none == (0, 0)
    assert (shown.shownCount, shown.residues.shownCount) == (2, 2)


def test_a_hidden_residue_stays_hidden_in_the_next_file(qcore_application):
    shown = residue_instancing()
    residues = shown.residues
    residues.setData(residues.index(1), False, residues.ShownRole)

    shown.set_atoms(
        np.array([b'   NA', b'   OW'], 'S5'),
        np.array([[0, 0, 0], [0.1, 0, 0]], np.float32),
        residues=np.array([b'SOD', b'TIP3'], 'S5'),
    )

    assert residue_rows(shown) == [('SOD', 1, True), ('TIP3', 1, False)]
    assert shown.shownCount == 1


def test_clear_drops_the_atoms_and_resets_the_slab_width(qcore_application):
    shown = instancing(ALONG_Z)
    shown.slabFraction = 1.0
    shown.slabAxis = 0

    shown.clear()

    assert (shown.atomCount, shown.slabCount, shown.shownCount) == (0, 0, 0)
    assert (shown.slabFraction, shown.slabAxis) == (0.05, 0)
