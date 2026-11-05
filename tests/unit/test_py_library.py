# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest

from easyshapes_app.Backends.real_py.library import Library
from tests.unit.factories import SAVED_AT

pytestmark = pytest.mark.usefixtures('qcore_application')


class FakeLibraryLib:
    """
    Stands in for shapes.project.Library: a saved project, an example,
    and one asset of each catalog's type.
    """

    available_projects = [(Path('Projects/ring1'), SAVED_AT)]
    available_examples = [Path('examples/micelle')]
    available_assets = {
        'Ion': ['NA'],
        'Solvent': ['TIP3'],
        'Salt': ['NaCl'],
        'AnalysisConfiguration': ['CHARMM36'],
        'ForceField': ['CHARMM36'],
    }


class EmptyLibraryLib(FakeLibraryLib):
    """
    Holds no asset of any type.
    """

    available_assets = {}


def catalogs(part):
    return (
        part.availableIons,
        part.availableSolvents,
        part.availableSalts,
        part.availableAnalysisConfigurations,
        part.availableForceFields,
    )


def test_lists_read_the_library(monkeypatch):
    monkeypatch.setattr('easyshapes_app.Backends.real_py.library.LibraryLib', FakeLibraryLib)
    part = Library()

    assert part.availableProjects == [
        {
            'name': 'ring1',
            'path': str(Path('Projects/ring1')),
            'modified': SAVED_AT.astimezone().strftime('%d %b %Y %H:%M'),
        }
    ]
    assert part.availableExamples == [{'name': 'micelle', 'path': str(Path('examples/micelle'))}]
    assert part.availableAssets == FakeLibraryLib.available_assets
    assert catalogs(part) == (['NA'], ['TIP3'], ['NaCl'], ['CHARMM36'], ['CHARMM36'])


def test_a_type_the_library_holds_none_of_lists_nothing(monkeypatch):
    monkeypatch.setattr('easyshapes_app.Backends.real_py.library.LibraryLib', EmptyLibraryLib)

    assert catalogs(Library()) == ([], [], [], [], [])
