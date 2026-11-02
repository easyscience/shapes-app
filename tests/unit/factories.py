# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from datetime import UTC
from datetime import datetime
from pathlib import Path
from types import SimpleNamespace

from shapes.project import Ring

SAVED_AT = datetime(2026, 10, 13, 9, 30, tzinfo=UTC)
LOADED_AT = datetime(2026, 10, 1, 12, 0, tzinfo=UTC)
# Atom name and position in nm
GRO_ATOMS = [('C1', 0.1, 0.2, 0.3), ('S1', -1.0, 0.0, 12.345), ('H1', 0.0, 0.0, 0.0)]


def gro_text(newline='\n', atoms=GRO_ATOMS):
    """
    A GRO file of the atoms, written as the library writes them.
    """
    lines = ['title', f'{len(atoms):5d}']
    lines += [
        '{:>5}{:<5}{:>5}{:>5}'.format(1, 'SDS', name, number)
        + '{:>8.3f}{:>8.3f}{:>8.3f}'.format(x, y, z)
        for number, (name, x, y, z) in enumerate(atoms, start=1)
    ]
    lines.append('   1.00000   1.00000   1.00000')
    return newline.join(lines) + newline


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


class FakeAsset:
    """
    Holds its files as the library does: sorted, each once, added and
    removed by path. Logs saves and exports in calls.
    """

    def __init__(self, name, *paths):
        self.name = name
        self._paths = {Path(path) for path in paths}
        self.calls = []

    @property
    def paths(self):
        return tuple(sorted(self._paths))

    def add_new_files(self, paths):
        self._paths.update(Path(path) for path in paths)

    def remove_files(self, paths):
        self._paths.difference_update(Path(path) for path in paths)

    def save(self, *, overwrite=False):
        self.calls.append(('save', overwrite))

    def export_to(self, folder, *, overwrite=False):
        self.calls.append(('export_to', folder, overwrite))


class FakeJob:
    """
    Stands in for the library's Job: runs until a test ends it, or a
    cancel does.
    """

    def __init__(self):
        self.running = True
        self.error = None

    def end(self, error=None):
        self.running = False
        self.error = error

    def cancel(self):
        if self.running:
            self.end('Cancelled')


class FakeSampleModel(FakeAsset):
    """
    Stands in for shapes.project.SampleModel, a library asset. It holds
    a real structure, a ring unless given, for the real structure logic
    to read and switch. Assemble starts a FakeJob.
    """

    def __init__(self, structure=None):
        super().__init__('uid0002')
        self.structure = structure or Ring()
        # Empty; the real Buffer is a library asset, which needs the
        # AppFileManager
        self.buffer = SimpleNamespace(solvent=None, components=[])
        self.job = None

    @property
    def files_locked(self):
        return self.job is not None and self.job.running

    def assemble(self, *, background=False):
        self.job = FakeJob()

    @classmethod
    def load(cls, name):
        model = cls()
        model.name = name
        return model

    @classmethod
    def import_from(cls, folder):
        model = cls()
        model.name = Path(folder).name
        return model
