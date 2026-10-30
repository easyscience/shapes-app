# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.smiles_generator import SmilesGenerator
from tests.unit.factories import FakeSampleModel

pytestmark = pytest.mark.usefixtures('qcore_application')


class FakeSurfactant:
    """
    Stands in for a library component class: from_smiles keeps its
    arguments.
    """

    @classmethod
    def from_smiles(cls, name, smiles, box, **options):
        component = cls()
        component.name = name
        component.args = (smiles, box, options)
        return component


class OfflineSmilesGenerator(SmilesGenerator):
    """
    Builds FakeSurfactants.
    """

    _types = {'Surfactant': FakeSurfactant}


def part_with(*names):
    # The names stand in for the components: a name is held when in
    # them, as in the library's collection
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=names)
    return OfflineSmilesGenerator(Session(sample_model=sample_model))


FIELDS = [
    ('name', 'SDS'),
    ('formula', 'C12SO4'),
    ('smiles', 'CCO'),
    ('boxX', 2.5),
    ('boxY', 2.5),
    ('boxZ', 2.5),
    ('extension', '.pdb'),
    ('componentType', 'Surfactant'),
    ('cis', True),
    ('alignZ', True),
    ('flattenXz', True),
]


@pytest.mark.parametrize(('field', 'value'), FIELDS, ids=[field for field, _ in FIELDS])
def test_setters_keep_the_draft_and_emit_only_on_change(field, value):
    part = part_with()
    spy = QSignalSpy(getattr(part, f'{field}Changed'))

    setattr(part, field, value)
    setattr(part, field, value)

    assert getattr(part, field) == value
    assert spy.count() == 1


def test_ready_needs_a_name_and_a_smiles_string():
    part = part_with()
    spy = QSignalSpy(part.readyChanged)

    part.name = 'SDS'
    assert not part.ready
    part.smiles = 'CCO'
    assert part.ready
    assert spy.count() == 2


def test_name_is_taken_by_a_component_of_the_sample():
    part = part_with('SDS')
    spy = QSignalSpy(part.nameTakenChanged)

    part.name = 'SDS'
    assert part.nameTaken
    part.name = 'DTA'
    assert not part.nameTaken
    part.refresh()
    assert spy.count() == 3


def test_no_name_is_taken_before_the_first_sample_model():
    part = OfflineSmilesGenerator(Session())

    part.name = 'SDS'

    assert not part.nameTaken


def test_generate_builds_the_draft_and_hands_it_to_the_root():
    part = part_with()
    created = []
    part.externalComponentCreated.connect(created.append)
    part.name = 'SDS'
    part.smiles = 'CCO'
    part.boxX = 2.0
    part.boxY = 3.0
    part.boxZ = 4.0
    part.extension = '.pdb'
    part.componentType = 'Surfactant'
    part.cis = True
    part.alignZ = True
    part.flattenXz = True

    part.generate()

    (component,) = created
    assert component.name == 'SDS'
    # An empty formula is None: the library takes the name for it
    assert component.args == (
        'CCO',
        (2.0, 3.0, 4.0),
        {'formula': None, 'cis': True, 'align_z': True, 'flatten_xz': True, 'extension': '.pdb'},
    )


@pytest.mark.parametrize(('field', 'value'), FIELDS, ids=[field for field, _ in FIELDS])
def test_a_draft_change_drops_the_generated_note(field, value):
    part = part_with()
    part.mark_generated()
    spy = QSignalSpy(part.generatedChanged)

    setattr(part, field, value)

    assert not part.generated
    assert spy.count() == 1


def test_generate_again_drops_the_generated_note():
    part = part_with()
    part.name = 'SDS'
    part.smiles = 'CCO'
    part.componentType = 'Surfactant'
    part.mark_generated()

    # No root adds the component, as when the sample refuses its name
    part.generate()

    assert not part.generated
