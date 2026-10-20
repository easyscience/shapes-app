# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Ball
from shapes.project import Bilayer
from shapes.project import Lattice
from shapes.project import Monolayer
from shapes.project import Ring
from shapes.project import Rod
from shapes.project import Vesicle

from easyshapes_app.Backends.real_py.ball_structure import BallStructure
from easyshapes_app.Backends.real_py.bilayer_structure import BilayerStructure
from easyshapes_app.Backends.real_py.lattice_structure import LatticeStructure
from easyshapes_app.Backends.real_py.monolayer_structure import MonolayerStructure
from easyshapes_app.Backends.real_py.ring_structure import RingStructure
from easyshapes_app.Backends.real_py.rod_structure import RodStructure
from easyshapes_app.Backends.real_py.vesicle_structure import VesicleStructure

pytestmark = pytest.mark.usefixtures('qcore_application')

# Each adapter, what builds the object it adapts, and a new value per
# field, unlike the library default
ADAPTERS = [
    (
        RingStructure,
        Ring,
        {'alpha': 30.0, 'theta': 60.0, 'dmin': 0.7, 'rmin': 0.4, 'fxz': True, 'rev': True},
    ),
    (BallStructure, Ball, {'fxz': True, 'rev': True, 'fill': 'FIBO'}),
    (VesicleStructure, Vesicle, {'fxz': True, 'rev': True, 'fill': 'FIBO'}),
    (RodStructure, Rod, {'turns': 3, 'dmin': 0.7, 'rmin': 0.4, 'fxz': True, 'rev': True}),
    (BilayerStructure, Bilayer, {'dmin': 0.7, 'zsep': 1.5, 'nside': 4}),
    (MonolayerStructure, Monolayer, {'dmin': 0.7, 'zsep': 1.5, 'nside': 4}),
    (
        LatticeStructure,
        lambda: Lattice(unit=Ring()),
        {
            'alpha': 30.0,
            'theta': 60.0,
            'nlatx': 2,
            'nlaty': 2,
            'nlatz': 2,
            'sbuff': 2.0,
            'latticeType': 'LFCC',
        },
    ),
]
FIELDS = [(case, field) for case in ADAPTERS for field in case[2]]


@pytest.mark.parametrize(
    ('case', 'field'), FIELDS, ids=[f'{case[0].__name__}-{field}' for case, field in FIELDS]
)
def test_setters_write_the_structure_and_emit_only_on_change(case, field):
    adapter_class, build, fields = case
    adapter = adapter_class(build())
    spy = QSignalSpy(getattr(adapter, f'{field}Changed'))

    setattr(adapter, field, fields[field])
    setattr(adapter, field, fields[field])

    # The adapter keeps nothing: it reads the value back
    assert getattr(adapter, field) == fields[field]
    assert spy.count() == 1
