# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py import sample_model as sample_model_module
from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.sample_model import SampleModel
from tests.unit.factories import FakeSampleModel
from tests.unit.factories import FakeStructureLogic


@pytest.fixture(autouse=True)
def fake_library(monkeypatch, qcore_application):
    monkeypatch.setattr(sample_model_module, 'SampleModelLib', FakeSampleModel)
    monkeypatch.setattr(sample_model_module, 'structure', FakeStructureLogic)


def all_signals(part):
    return [
        QSignalSpy(signal)
        for signal in (
            part.nameChanged,
            part.shapeChanged,
            part.latticeChanged,
            part.externalStructureChanged,
        )
    ]


def test_fields_are_empty_and_setters_do_nothing_without_sample_model():
    part = SampleModel(Session())
    spies = all_signals(part)

    part.name = 'vesicles'
    part.shape = 'Ball'
    part.lattice = True

    assert (part.name, part.shape, part.lattice) == ('', '', False)
    assert [spy.count() for spy in spies] == [0, 0, 0, 0]


def test_create_makes_a_sample_model_only_when_there_is_none():
    session = Session()
    part = SampleModel(session)
    spies = all_signals(part)

    part.create()
    first = session.sample_model
    part.create()

    assert session.sample_model is first
    assert (part.name, part.shape, part.lattice) == ('uid0002', 'Ring', False)
    assert [spy.count() for spy in spies] == [1, 1, 1, 1]


@pytest.mark.parametrize(
    ('field', 'value', 'external'),
    [('name', 'vesicles', 0), ('shape', 'Ball', 1), ('lattice', True, 1)],
)
def test_setters_emit_only_on_change(field, value, external):
    part = SampleModel(Session(sample_model=FakeSampleModel()))
    changed = QSignalSpy(getattr(part, f'{field}Changed'))
    structure_replaced = QSignalSpy(part.externalStructureChanged)

    setattr(part, field, value)
    setattr(part, field, value)

    assert getattr(part, field) == value
    assert (changed.count(), structure_replaced.count()) == (1, external)
