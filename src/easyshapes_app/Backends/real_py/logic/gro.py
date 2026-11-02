# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np

# Atom line columns (0-based, end excluded): the residue number and
# name, the atom name, then x, y, z in nm, each 8 wide with 3 decimals
_RESIDUE = slice(0, 10)
_NAME = slice(10, 15)
_XYZ = (slice(20, 28), slice(28, 36), slice(36, 44))


def read_gro_atoms(path):
    """
    The atom names and positions of a GRO file, read as columns: no
    object per atom, so millions of atoms read in seconds.

    Every atom line must be as long as the first, line end included, as
    the library writes them; a file with lines of other lengths raises
    ValueError. Returns the names as 5-byte strings, as written, the
    positions in nm, N x 3, and the residues: number and name as one
    10-byte string each, for molecule_bonds.
    """
    data = path.read_bytes()
    # The title line, then the atom count line
    title_end = data.index(b'\n') + 1
    count_end = data.index(b'\n', title_end) + 1
    count = int(data[title_end:count_end])
    # Every atom line is as long as the first, line end included
    width = data.index(b'\n', count_end) + 1 - count_end
    lines = np.frombuffer(data, np.uint8, count * width, count_end).reshape(count, width)
    if not (lines[:, -1] == ord('\n')).all():
        raise ValueError(f'{path.name}: atom lines differ in length')
    names = lines[:, _NAME].copy().view('S5').ravel()
    xyz = np.stack(
        [lines[:, column].copy().view('S8').ravel().astype(np.float32) for column in _XYZ],
        axis=1,
    )
    residues = lines[:, _RESIDUE].copy().view('S10').ravel()
    return names, xyz, residues


def molecule_bonds(residues, bonds_by_name):
    """
    The bonds of a structure's molecules: N x 2 atom indices.

    A molecule is a run of atoms of one residue, as read_gro_atoms gives
    them; it takes the pairs bonds_by_name holds for its residue name
    (0-based, from a topology file). A molecule of another name, too few
    atoms for its pairs, or several residues (a protein) gets none.
    """
    # A molecule starts where the residue changes; no atoms, none
    starts = np.flatnonzero(np.r_[True, residues[1:] != residues[:-1]])[: len(residues)]
    sizes = np.diff(np.r_[starts, len(residues)])
    # The name half of each start's residue; GRO keeps 5 letters
    names = np.char.strip(residues[starts].view('S5')[1::2])
    found = [np.zeros((0, 2), np.int32)]
    for name, pairs in bonds_by_name.items():
        pairs = np.asarray(pairs, np.int32).reshape(-1, 2)
        if len(pairs):
            mine = starts[(names == name[:5].encode()) & (sizes > pairs.max())]
            found.append((mine[:, None, None] + pairs).reshape(-1, 2))
    # 8 bytes a bond: millions of them stay small
    return np.concatenate(found, dtype=np.int32)
