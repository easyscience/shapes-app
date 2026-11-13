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


# Each adapter, what builds the object it adapts, a field, a new value
# for it, and whether the field changes a size
SIZE_FIELDS = [
    (RingStructure, Ring, 'rmin', 0.4, True),
    (RingStructure, Ring, 'dmin', 0.7, False),
    (RodStructure, Rod, 'turns', 3, True),
    (RodStructure, Rod, 'dmin', 0.7, True),
    (RodStructure, Rod, 'rmin', 0.4, True),
    (RodStructure, Rod, 'fxz', True, False),
    (BilayerStructure, Bilayer, 'dmin', 0.7, True),
    (BilayerStructure, Bilayer, 'zsep', 1.5, True),
    (BilayerStructure, Bilayer, 'nside', 4, True),
    (MonolayerStructure, Monolayer, 'dmin', 0.7, True),
    (MonolayerStructure, Monolayer, 'nside', 4, True),
    (MonolayerStructure, Monolayer, 'zsep', 1.5, False),
]


@pytest.mark.parametrize(
    ('adapter_class', 'build', 'field', 'value', 'changes_size'),
    SIZE_FIELDS,
    ids=[f'{case[0].__name__}-{case[2]}' for case in SIZE_FIELDS],
)
def test_fields_that_change_a_size_announce_it(adapter_class, build, field, value, changes_size):
    adapter = adapter_class(build())
    spy = QSignalSpy(adapter.sizesChanged)

    setattr(adapter, field, value)

    assert spy.count() == (1 if changes_size else 0)


def test_sizes_read_the_library():
    bilayer = Bilayer()
    bilayer.zsep = 1.5
    monolayer = Monolayer()
    rod = RodStructure(Rod())

    # No components, so no bone to measure
    assert RingStructure(Ring()).outerRadius is None
    assert (rod.outerRadius, rod.length) == (None, None)
    assert MonolayerStructure(monolayer).thickness is None
    # The width needs no bone, nor does a set zsep
    assert BilayerStructure(bilayer).width == pytest.approx(bilayer.nside * bilayer.dmin)
    assert BilayerStructure(bilayer).thickness == 1.5
    assert MonolayerStructure(monolayer).width == pytest.approx(monolayer.nside * monolayer.dmin)
