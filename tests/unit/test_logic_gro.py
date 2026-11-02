# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np
import pytest

from easyshapes_app.Backends.real_py.logic.gro import molecule_bonds
from easyshapes_app.Backends.real_py.logic.gro import read_gro_atoms
from tests.unit.factories import GRO_ATOMS
from tests.unit.factories import gro_text


def residues(*molecules):
    """
    The 10-byte residues of molecules given as (number, name, atom
    count), as read_gro_atoms reads them.
    """
    return np.array(
        [
            f'{number:>5}{name:<5}'.encode()
            for number, name, count in molecules
            for _ in range(count)
        ],
        'S10',
    )


@pytest.mark.parametrize('newline', ['\n', '\r\n'], ids=['lf', 'crlf'])
def test_reads_names_and_positions_in_nm(tmp_path, newline):
    gro = tmp_path / 'model.gro'
    gro.write_bytes(gro_text(newline).encode())

    names, xyz, _ = read_gro_atoms(gro)

    assert [name.strip() for name in names] == [b'C1', b'S1', b'H1']
    assert xyz.shape == (3, 3)
    assert xyz == pytest.approx(np.array([atom[1:] for atom in GRO_ATOMS]), abs=1e-6)


def test_lines_of_other_lengths_raise(tmp_path):
    lines = gro_text().split('\n')
    # A velocity column on one atom line only
    lines[3] += '  0.1000'
    gro = tmp_path / 'model.gro'
    gro.write_text('\n'.join(lines))

    with pytest.raises(ValueError, match='atom lines differ in length'):
        read_gro_atoms(gro)


def test_reads_each_atoms_residue_number_and_name(tmp_path):
    gro = tmp_path / 'model.gro'
    gro.write_bytes(gro_text().encode())

    _, _, held = read_gro_atoms(gro)

    assert held.tolist() == [b'    1SDS  '] * 3


def test_each_molecule_takes_the_bonds_of_its_name():
    # Two SDS of 3 atoms, a water, an SDS too short for its pairs, then
    # a name GRO cut to 5 letters
    held = residues((1, 'SDS', 3), (2, 'SDS', 3), (3, 'SOL', 3), (4, 'SDS', 2), (5, 'LONGN', 2))

    bonds = molecule_bonds(held, {'SDS': [[0, 1], [1, 2]], 'CHOL': [[0, 1]], 'LONGNAME': [[0, 1]]})

    assert bonds.dtype == np.int32
    assert bonds.tolist() == [[0, 1], [1, 2], [3, 4], [4, 5], [11, 12]]


def test_no_atoms_have_no_bonds():
    assert molecule_bonds(np.zeros(0, 'S10'), {'SDS': [[0, 1]]}).shape == (0, 2)
