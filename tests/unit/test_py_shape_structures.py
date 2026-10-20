# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Bilayer
from shapes.project import Lattice
from shapes.project import Ring

from easyshapes_app.Backends.real_py.ball_structure import BallStructure
from easyshapes_app.Backends.real_py.bilayer_structure import BilayerStructure
from easyshapes_app.Backends.real_py.lattice_structure import LatticeStructure
from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.logic.structure import SHAPES
from easyshapes_app.Backends.real_py.monolayer_structure import MonolayerStructure
from easyshapes_app.Backends.real_py.ring_structure import RingStructure
from easyshapes_app.Backends.real_py.rod_structure import RodStructure
from easyshapes_app.Backends.real_py.vesicle_structure import VesicleStructure
from tests.unit.factories import FakeSampleModel

pytestmark = pytest.mark.usefixtures('qcore_application')

# Each shape part, its shape, and a new value per field, unlike the
# library default
PARTS = [
    (
        RingStructure,
        'Ring',
        {'alpha': 30.0, 'theta': 60.0, 'dmin': 0.7, 'rmin': 0.4, 'fxz': True, 'rev': True},
    ),
    (BallStructure, 'Ball', {'fxz': True, 'rev': True, 'fill': 'FIBO'}),
    (VesicleStructure, 'Vesicle', {'fxz': True, 'rev': True, 'fill': 'FIBO'}),
    (RodStructure, 'Rod', {'turns': 3, 'dmin': 0.7, 'rmin': 0.4, 'fxz': True, 'rev': True}),
    (BilayerStructure, 'Bilayer', {'dmin': 0.7, 'zsep': 1.5, 'nside': 4}),
    (MonolayerStructure, 'Monolayer', {'dmin': 0.7, 'zsep': 1.5, 'nside': 4}),
    (
        LatticeStructure,
        'Lattice',
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
SHAPE_NAMES = [shape for _, shape, _ in PARTS]
FIELDS = [(case, field) for case in PARTS for field in case[2]]


def build(part_class, shape, fields):
    """
    A part over a lattice of its shape, so every part is switched on.
    The lattice part gets a lattice of rings.
    """
    sample_model = FakeSampleModel(Lattice(unit=SHAPES.get(shape, Ring)()))
    return part_class(Session(sample_model=sample_model)), sample_model


def switched_off(shape):
    """
    A structure the part of that shape doesn't read: another shape, no
    lattice.
    """
    return Bilayer() if shape == 'Ring' else Ring()


def all_signals(part, fields):
    return [QSignalSpy(getattr(part, f'{field}Changed')) for field in fields]


@pytest.mark.parametrize(
    ('case', 'field'), FIELDS, ids=[f'{case[1]}-{field}' for case, field in FIELDS]
)
def test_setters_write_the_structure_and_emit_only_on_change(case, field):
    part, _ = build(*case)
    spy = QSignalSpy(getattr(part, f'{field}Changed'))
    new = case[2][field]

    setattr(part, field, new)
    setattr(part, field, new)

    # The part keeps nothing: it reads the value back from the structure
    assert getattr(part, field) == new
    assert spy.count() == 1


@pytest.mark.parametrize('case', PARTS, ids=SHAPE_NAMES)
def test_fields_read_empty_and_setters_do_nothing_when_switched_off(case):
    part, sample_model = build(*case)
    fields = case[2]
    sample_model.structure = off = switched_off(case[1])
    before = dict(vars(off))
    spies = all_signals(part, fields)

    for field, new in fields.items():
        setattr(part, field, new)

    # 0, 0.0, False or '', by the field's type
    assert [getattr(part, field) for field in fields] == [type(new)() for new in fields.values()]
    assert vars(off) == before
    assert [spy.count() for spy in spies] == [0] * len(fields)


@pytest.mark.parametrize('case', PARTS, ids=SHAPE_NAMES)
def test_refresh_emits_every_field_signal_once(case):
    part, _ = build(*case)
    spies = all_signals(part, case[2])

    part.refresh()

    assert [spy.count() for spy in spies] == [1] * len(case[2])
