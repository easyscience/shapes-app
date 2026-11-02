# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause


def read_bonds(path, name):
    """
    The bonds of a molecule type in a GROMACS topology file, as pairs of
    0-based atom indices: the type of the name, or the only one. Empty
    when no type matches or it lists no bonds.
    """
    # Pairs by molecule type; a bond line's first two fields are
    # 1-based atom numbers, as gmx reads them
    bonds = {}
    section = molecule = ''
    with path.open(encoding='utf-8', errors='replace') as file:
        for raw in file:
            line = raw.split(';', 1)[0].strip()
            if not line or line.startswith('#'):
                continue
            if line.startswith('['):
                section = line.strip('[] ')
                continue
            fields = line.split()
            if section == 'moleculetype':
                molecule = fields[0]
                bonds[molecule] = []
            elif section == 'bonds' and molecule:
                bonds[molecule].append([int(fields[0]) - 1, int(fields[1]) - 1])
    # The molecule type the library's charge reads: the name, or the
    # only one
    if name in bonds:
        return bonds[name]
    return next(iter(bonds.values())) if len(bonds) == 1 else []
