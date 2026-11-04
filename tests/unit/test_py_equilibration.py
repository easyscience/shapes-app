# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import os
from pathlib import Path
from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.equilibration import Equilibration
from easyshapes_app.Backends.real_py.logic.session import Session
from tests.unit.factories import FakeAsset
from tests.unit.factories import FakeEquilibration

pytestmark = pytest.mark.usefixtures('qcore_application')


class QuickEquilibration(Equilibration):
    """
    Checks a running equilibration every 10 ms and lets Cancel in after
    50 ms.
    """

    _watch_interval = 10
    _cancel_delay = 50


class Unrunnable(FakeEquilibration):
    """
    Fails the checks run makes before it starts.
    """

    def run(self, sample_model, *, background=False):
        raise ValueError('model holds no assembled .gro and .top; assemble it with a buffer first')


def stage(folder, k, time):
    """
    Stage eq<k> as the library holds it once finished: its files, the
    final .gro written at a time.
    """
    folder = folder / f'eq{k}'
    folder.mkdir()
    gro = folder / f'model-eq{k}.gro'
    gro.write_text('')
    os.utime(gro, (time, time))
    return FakeAsset(f'eq{k}', gro, folder / f'model-eq{k}.mdp', folder / f'model-eq{k}.tpr')


def part_on(equilibration):
    """
    A part on a session whose analysis holds the equilibration, read.
    """
    session = Session(sample_model=object(), analysis=SimpleNamespace(equilibration=equilibration))
    part = QuickEquilibration(session)
    part.refresh()
    return part


def three_stages():
    """
    An equilibration whose configuration holds stages 0 to 2, and a file
    that is no stage.
    """
    return FakeEquilibration('equil0.mdp', 'equil1.mdp', 'equil2.mdp', 'notes.txt')


def editable_files(part):
    """
    The files shown, by name, and whether the pencil opens each.
    """
    files = part.files
    return {
        Path(files.data(files.index(row), files.PathRole)).name: files.data(
            files.index(row), files.EditableRole
        )
        for row in range(files.count)
    }


def test_fields_are_empty_without_analysis():
    part = Equilibration(Session())

    part.refresh()
    part.firstStage = 2
    part.threads = '4'

    assert (part.firstStage, part.lastStage, part.threads, part.restrainToBoxCenter) == (
        0,
        0,
        '',
        False,
    )
    assert (part.availableStages, part.startableStages) == ([], [])
    assert (part.entries.count, part.files.count, part.log) == (1, 0, '')


def test_the_last_stage_shows_the_configurations_last_and_follows_the_first():
    equilibration = three_stages()
    part = part_on(equilibration)

    shown = part.lastStage
    part.lastStage = 0
    part.firstStage = 1

    assert shown == 2
    assert (part.firstStage, part.lastStage) == (1, 1)
    assert (equilibration.first_stage, equilibration.last_stage) == (1, 1)


def test_empty_threads_are_auto():
    equilibration = three_stages()
    part = part_on(equilibration)
    changed = QSignalSpy(part.threadsChanged)

    part.threads = '4'
    four = equilibration.threads
    part.threads = '4'
    part.threads = ''

    assert (four, equilibration.threads, part.threads) == (4, None, '')
    assert changed.count() == 2


def test_restraints_go_to_the_equilibration_and_emit_only_on_change():
    equilibration = three_stages()
    part = part_on(equilibration)
    changed = QSignalSpy(part.restrainToBoxCenterChanged)

    part.restrainToBoxCenter = True
    part.restrainToBoxCenter = True

    assert equilibration.restrain_to_box_center
    assert changed.count() == 1


def test_available_stages_are_the_configurations_equil_mdp_files():
    part = part_on(FakeEquilibration('equil2.mdp', 'equil0.mdp', 'equil1.mdp.bak', 'notes.txt'))

    assert part.availableStages == [0, 2]


def test_entries_and_startable_stages_follow_the_stages_files(tmp_path):
    equilibration = three_stages()
    # eq1 ran again after eq2: eq2 started from older files
    equilibration.stages = [
        stage(tmp_path, 0, 100),
        stage(tmp_path, 1, 300),
        stage(tmp_path, 2, 200),
    ]

    part = part_on(equilibration)

    assert [part.entries.get(row) for row in range(part.entries.count)] == [
        {'name': 'Equilibration', 'status': ''},
        {'name': 'eq0', 'status': 'done'},
        {'name': 'eq1', 'status': 'done'},
        {'name': 'eq2', 'status': 'outdated'},
    ]
    # Stage 3 could follow eq2, but the configuration holds no
    # equil3.mdp
    assert part.startableStages == [0, 1, 2]


def test_picked_files_show_with_the_pencil_on_text_files_only(tmp_path):
    equilibration = three_stages()
    equilibration.add_new_files([
        tmp_path / 'toppar' / 'SDS.itp',
        tmp_path / 'model.top',
        tmp_path / 'equilibration.log',
    ])
    equilibration.stages = [stage(tmp_path, 0, 100)]
    part = part_on(equilibration)
    picked = QSignalSpy(part.selectedEntryChanged)

    copies = editable_files(part)
    part.selectEntry(1)

    assert copies == {'SDS.itp': False, 'model.top': False, 'equilibration.log': True}
    assert editable_files(part) == {
        'model-eq0.gro': True,
        'model-eq0.mdp': True,
        'model-eq0.tpr': False,
    }
    assert (part.selectedEntry, picked.count()) == (1, 1)


def test_export_copies_a_row_or_exports_the_whole_entry(tmp_path):
    equilibration = three_stages()
    equilibration.stages = [stage(tmp_path, 0, 100)]
    part = part_on(equilibration)
    export = tmp_path / 'export'
    export.mkdir()

    part.selectEntry(1)
    free = part.exportTaken(str(export), 0)
    # Rows are sorted: model-eq0.gro first
    part.exportTo(str(export), 0, False)
    taken = part.exportTaken(str(export), 0)
    part.exportTo(str(export), -1, True)

    assert (free, taken) == (False, True)
    assert (export / 'model-eq0.gro').is_file()
    assert equilibration.stages[0].calls == [('export_to', str(export), True)]


@pytest.mark.parametrize(
    ('error', 'shown'), [(None, ''), ('gmx failed', 'gmx failed'), ('Cancelled', '')]
)
def test_a_run_shows_its_stage_and_log_until_its_job_ends(tmp_path, error, shown):
    log = tmp_path / 'equilibration.log'
    log.write_text('$ gmx grompp\n')
    equilibration = FakeEquilibration('equil0.mdp', log=log)
    part = part_on(equilibration)
    locked = QSignalSpy(part.filesLockedChanged)
    ended = QSignalSpy(part.externalEquilibrated)

    # As the library does at the start: the stage joins, and runs
    equilibration.stages = [FakeAsset('eq0')]
    equilibration.stage = 0
    part.run()
    running = (part.filesLocked, part.stage, part.entries.get(1)['status'], part.log)
    equilibration.stage = None
    equilibration.job.end(error)
    ended.wait(1000)

    assert running == (True, 0, 'running', '$ gmx grompp\n')
    assert [background for _, background in equilibration.runs] == [True]
    assert (part.filesLocked, part.stage) == (False, -1)
    assert locked.count() == 2
    assert ended.at(0) == [shown]


def test_a_check_failing_before_the_start_starts_no_run():
    part = part_on(Unrunnable('equil0.mdp'))
    locked = QSignalSpy(part.filesLockedChanged)

    with pytest.raises(ValueError, match='assemble it with a buffer first'):
        part.run()

    assert not part.filesLocked
    assert locked.count() == 0


def test_cancel_comes_in_after_the_delay_and_ends_the_run_at_once():
    equilibration = FakeEquilibration('equil0.mdp')
    part = part_on(equilibration)
    cancelable = QSignalSpy(part.cancelableChanged)
    ended = QSignalSpy(part.externalEquilibrated)

    part.run()
    early = part.cancelable
    cancelable.wait(1000)
    late = part.cancelable
    part.cancel()

    assert (early, late) == (False, True)
    assert equilibration.job.error == 'Cancelled'
    assert (part.filesLocked, part.cancelable) == (False, False)
    assert ended.at(0) == ['']


def test_a_replacement_waits_for_the_run_then_cancels_it():
    equilibration = FakeEquilibration('equil0.mdp')
    part = part_on(equilibration)
    replaced = []
    ended = QSignalSpy(part.externalEquilibrated)

    part.run()
    part.after_equilibration(lambda: replaced.append('replaced'))
    held = list(replaced)
    ended.wait(1000)

    assert held == []
    assert replaced == ['replaced']
    assert equilibration.job.error == 'Cancelled'
