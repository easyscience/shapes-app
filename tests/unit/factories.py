# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from datetime import UTC
from datetime import datetime
from pathlib import Path
from types import SimpleNamespace

SAVED_AT = datetime(2026, 10, 13, 9, 30, tzinfo=UTC)
LOADED_AT = datetime(2026, 10, 1, 12, 0, tzinfo=UTC)


class FakeProject:
    """
    Stands in for shapes.project.Project: keeps its arguments, counts
    saves.
    """

    def __init__(self, name=None, description='', sample_model=None, analysis=None, path=None):
        self.init_args = {
            'name': name,
            'sample_model': sample_model,
            'analysis': analysis,
            'path': path,
        }
        self.name = name if name is not None else 'uid0001'
        self.description = description
        self.sample_model = sample_model or object()
        self.analysis = analysis or object()
        self.path = Path(path) if path else Path.home() / 'Projects' / f'{self.name}-uid0001'
        self.modified = None
        self.save_calls = 0

    @classmethod
    def load(cls, path):
        project = cls(name='Loaded', path=path)
        project.modified = LOADED_AT
        return project

    def save(self):
        self.save_calls += 1
        self.modified = SAVED_AT


class FakeSampleModel:
    """
    Stands in for shapes.project.SampleModel. Shape and lattice are
    plain attributes, which FakeStructureLogic reads and writes.
    """

    def __init__(self):
        self.name = 'uid0002'
        self.shape = 'Ring'
        self.lattice = False
        # The current structure's fields, set by each shape's test
        self.structure = SimpleNamespace()


class FakeStructureLogic:
    """
    Stands in for real_py/logic/structure.py on a FakeSampleModel.
    """

    # Only the names are read
    SHAPES = {'Ring': None, 'Ball': None}

    @staticmethod
    def shape(sample_model):
        return sample_model.shape

    @staticmethod
    def set_shape(sample_model, name):
        sample_model.shape = name

    @staticmethod
    def is_lattice(sample_model):
        return sample_model.lattice

    @staticmethod
    def set_lattice(sample_model, lattice):
        sample_model.lattice = lattice

    @staticmethod
    def shaped(sample_model, name):
        if sample_model is None or sample_model.shape != name:
            return None
        return sample_model.structure
