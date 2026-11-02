# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest

from easyshapes_app.Backends.real_py.logic.itp import read_bonds

ITP = """\
; two molecule types, bond lines of 3 and 5 fields
[ moleculetype ]
OTHER  3

[ atoms ]
1  CT  1  OTHER  C1  1  0.0

[ bonds ]
1  2  1

[ moleculetype ]
; name  nrexcl
DPPC  3

[ bonds ]
1  2  1  0.1510 179912.0  ; C-C
2  5  1
#ifdef FLEXIBLE
#endif
"""


@pytest.mark.parametrize(
    ('text', 'name', 'bonds'),
    [
        (ITP, 'DPPC', [[0, 1], [1, 4]]),
        (ITP, 'POPC', []),
        (ITP.split('[ moleculetype ]\n; name')[0], 'DPPC', [[0, 1]]),
    ],
    ids=['by-name', 'no-match', 'only-one'],
)
def test_bonds_come_from_the_matching_molecule_type(tmp_path, text, name, bonds):
    itp = tmp_path / 'topology.itp'
    itp.write_text(text)

    assert read_bonds(itp, name) == bonds
