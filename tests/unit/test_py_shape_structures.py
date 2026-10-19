# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.basics.defaults import Fill
from shapes.basics.options import ShapeType

from easyshapes_app.Backends.real_py.ball_structure import BallStructure
from easyshapes_app.Backends.real_py.bilayer_structure import BilayerStructure
from easyshapes_app.Backends.real_py.lattice_structure import LatticeStructure
from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.monolayer_structure import MonolayerStructure
from easyshapes_app.Backends.real_py.ring_structure import RingStructure
from easyshapes_app.Backends.real_py.rod_structure import RodStructure
from easyshapes_app.Backends.real_py.vesicle_structure import VesicleStructure
from tests.unit.factories import FakeSampleModel
from tests.unit.factories import FakeStructureLogic

# Each shape part, its shape, and its fields as (start, new) values
PARTS = [
    (
        RingStructure,
        'Ring',
        {
            'alpha': (0.0, 30.0),
            'theta': (0.0, 60.0),
            'dmin': (0.5, 0.7),
            'rmin': (0.25, 0.4),
            'fxz': (False, True),
            'rev': (False, True),
        },
    ),
    (
        BallStructure,
        'Ball',
        {'fxz': (False, True), 'rev': (False, True), 'fill': ('FIBO', 'RINGS')},
    ),
    (
        VesicleStructure,
        'Vesicle',
        {'fxz': (False, True), 'rev': (False, True), 'fill': ('FIBO', 'RINGS')},
    ),
    (
        RodStructure,
        'Rod',
        {
            'turns': (1, 3),
            'dmin': (0.5, 0.7),
            'rmin': (0.25, 0.4),
            'fxz': (False, True),
            'rev': (False, True),
        },
    ),
    (BilayerStructure, 'Bilayer', {'dmin': (0.5, 0.7), 'zsep': (0.0, 1.5), 'nside': (1, 4)}),
    (MonolayerStructure, 'Monolayer', {'dmin': (0.5, 0.7), 'zsep': (0.0, 1.5), 'nside': (1, 4)}),
    (
        LatticeStructure,
        'Lattice',
        {
            'alpha': (0.0, 30.0),
            'theta': (0.0, 60.0),
            'nlatx': (1, 2),
            'nlaty': (1, 2),
            'nlatz': (1, 2),
            'sbuff': (1.0, 2.0),
            'latticeType': ('LCUB', 'LFCC'),
        },
    ),
]
SHAPES = [shape for _, shape, _ in PARTS]
FIELDS = [(case, field) for case in PARTS for field in case[2]]


class FakeStructure:
    """
    A structure's fields. Like the library, it turns a fill or lattice
    type name into a Fill or a ShapeType.
    """

    def __init__(self, **fields):
        for field, value in fields.items():
            setattr(self, field, value)

    @property
    def fill(self):
        return self._fill

    @fill.setter
    def fill(self, value):
        self._fill = Fill[value]

    @property
    def lattice_type(self):
        return self._lattice_type

    @lattice_type.setter
    def lattice_type(self, value):
        self._lattice_type = ShapeType[value]


@pytest.fixture(autouse=True)
def fake_logic(monkeypatch, qcore_application):
    for part_class, _, _ in PARTS:
        monkeypatch.setattr(f'{part_class.__module__}.structure', FakeStructureLogic)


def library_name(field):
    """
    The library attribute behind a part field: latticeType is
    lattice_type.
    """
    return ''.join(f'_{char.lower()}' if char.isupper() else char for char in field)


def build(part_class, shape, fields):
    sample_model = FakeSampleModel()
    # Switch on every part: each reads only its own switch
    sample_model.shape = shape
    sample_model.lattice = True
    sample_model.structure = FakeStructure(**{
        library_name(field): start for field, (start, _) in fields.items()
    })
    return part_class(Session(sample_model=sample_model)), sample_model


def all_signals(part, fields):
    return [QSignalSpy(getattr(part, f'{field}Changed')) for field in fields]


@pytest.mark.parametrize(
    ('case', 'field'), FIELDS, ids=[f'{case[1]}-{field}' for case, field in FIELDS]
)
def test_setters_write_the_structure_and_emit_only_on_change(case, field):
    part, _ = build(*case)
    spy = QSignalSpy(getattr(part, f'{field}Changed'))
    new = case[2][field][1]

    setattr(part, field, new)
    setattr(part, field, new)

    # The part keeps nothing: it reads the value back from the structure
    assert getattr(part, field) == new
    assert spy.count() == 1


@pytest.mark.parametrize('case', PARTS, ids=SHAPES)
def test_fields_read_empty_and_setters_do_nothing_when_switched_off(case):
    part, sample_model = build(*case)
    fields = case[2]
    sample_model.shape, sample_model.lattice = 'Other', False
    before = dict(vars(sample_model.structure))
    spies = all_signals(part, fields)

    for field, (_, new) in fields.items():
        setattr(part, field, new)

    # 0, 0.0, False or '', by the field's type
    empty = [type(start)() for start, _ in fields.values()]
    assert [getattr(part, field) for field in fields] == empty
    assert vars(sample_model.structure) == before
    assert [spy.count() for spy in spies] == [0] * len(fields)


@pytest.mark.parametrize('case', PARTS, ids=SHAPES)
def test_refresh_emits_every_field_signal_once(case):
    part, _ = build(*case)
    spies = all_signals(part, case[2])

    part.refresh()

    assert [spy.count() for spy in spies] == [1] * len(case[2])
