# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import os
from types import SimpleNamespace

from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.stage_view import StageView
from tests.unit.factories import GRO_ATOMS
from tests.unit.factories import FakeAsset
from tests.unit.factories import FakeEquilibration
from tests.unit.factories import FakeSampleModel
from tests.unit.factories import arrived
from tests.unit.factories import gro_text


def gro(path, time, atoms=GRO_ATOMS):
    """
    A .gro of the atoms at a path, written at a time.
    """
    path.parent.mkdir(exist_ok=True)
    path.write_text(gro_text(atoms=atoms))
    os.utime(path, (time, time))
    return path


def stage(folder, k, time):
    """
    Stage eq<k> as the library holds it once finished: its final .gro,
    of two atoms, written at a time.
    """
    return FakeAsset(f'eq{k}', gro(folder / f'eq{k}' / f'model-eq{k}.gro', time, GRO_ATOMS[:2]))


def equilibration_with_initial(folder):
    """
    An equilibration that holds its copy of the model, of three atoms.
    """
    equilibration = FakeEquilibration('equil0.mdp')
    equilibration.add_new_files([gro(folder / 'model.gro', 50)])
    return equilibration


def viewer_of(equilibration):
    """
    A stage viewer on a session whose analysis holds the equilibration,
    its rows read.
    """
    analysis = SimpleNamespace(equilibration=equilibration)
    view = StageView(Session(sample_model=FakeSampleModel(), analysis=analysis))
    view.refresh()
    return view


def rows(view):
    return [view.stages.get(row) for row in range(view.stages.count)]


def test_without_analysis_or_files_nothing_is_listed():
    empty = FakeEquilibration('equil0.mdp')
    empty.stages = [FakeAsset('eq0')]

    for view in (viewer_of(empty), StageView(Session())):
        view.refresh()
        assert (view.stages.count, view.selectedStage, view.hasStructure) == (0, -1, False)


def test_rows_are_initial_then_the_finished_stages(tmp_path):
    equilibration = equilibration_with_initial(tmp_path)
    # eq1 ran again after eq2, so eq2 is outdated; eq3 runs; eq4 has not
    # finished yet
    equilibration.stages = [
        stage(tmp_path, 0, 100),
        stage(tmp_path, 1, 400),
        stage(tmp_path, 2, 300),
        stage(tmp_path, 3, 500),
        FakeAsset('eq4'),
    ]
    equilibration.stage = 3

    view = viewer_of(equilibration)

    assert rows(view) == [
        {'name': 'Initial', 'status': ''},
        {'name': 'eq0', 'status': 'done'},
        {'name': 'eq1', 'status': 'done'},
        {'name': 'eq2', 'status': 'outdated'},
    ]


def test_the_newest_row_shows_until_a_pick_which_stays_while_listed(tmp_path):
    equilibration = equilibration_with_initial(tmp_path)
    equilibration.stages = [stage(tmp_path, 0, 100)]
    view = viewer_of(equilibration)

    newest = view.selectedStage
    view.selectStage(0)
    equilibration.stages.append(stage(tmp_path, 1, 200))
    view.refresh()
    kept = view.selectedStage
    view.selectStage(2)
    # eq1 runs again: it leaves the list, and the newest shows
    equilibration.stage = 1
    view.refresh()
    away = view.selectedStage
    equilibration.stage = None
    view.refresh()

    assert (newest, kept, away, view.selectedStage) == (1, 0, 1, 2)


def test_the_picked_rows_file_is_read(qcore_application, tmp_path):
    equilibration = equilibration_with_initial(tmp_path)
    equilibration.stages = [stage(tmp_path, 0, 100)]
    view = viewer_of(equilibration)

    # The newest row, eq0, shows first
    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    stage_atoms = view.instancing.atomCount
    view.selectStage(0)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))

    assert (stage_atoms, view.instancing.atomCount) == (2, 3)
