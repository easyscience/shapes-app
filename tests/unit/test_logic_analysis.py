# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import os
from pathlib import Path
from types import SimpleNamespace

from easyshapes_app.Backends.real_py.logic import analysis as logic
from easyshapes_app.Backends.real_py.logic.analysis import LogReader
from easyshapes_app.Backends.real_py.logic.analysis import fill_configuration
from easyshapes_app.Backends.real_py.logic.analysis import stage_statuses
from tests.unit.factories import FakeAnalysis
from tests.unit.factories import FakeAsset


def library_configurations(monkeypatch):
    """
    Put a stand-in for the library's AnalysisConfiguration into the
    logic: load gives a FakeAsset of the name, holding equil0.mdp.
    Returns the names loaded.
    """
    loaded = []

    def load(name):
        loaded.append(name)
        return FakeAsset(name, 'equil0.mdp')

    monkeypatch.setattr(logic, 'AnalysisConfiguration', SimpleNamespace(load=load))
    return loaded


def test_an_empty_configuration_gets_the_librarys_charmm36(monkeypatch):
    loaded = library_configurations(monkeypatch)
    analysis = FakeAnalysis(empty=True)

    fill_configuration(analysis)

    assert loaded == ['CHARMM36']
    assert analysis.equilibration.configuration.paths == (Path('equil0.mdp'),)


def test_a_configuration_with_files_stays(monkeypatch):
    loaded = library_configurations(monkeypatch)
    analysis = FakeAnalysis()
    held = analysis.equilibration.configuration

    fill_configuration(analysis)

    assert loaded == []
    assert analysis.equilibration.configuration is held


def final_gro(folder, k, time):
    """
    Stage k's final .gro, as gmx writes it, finished at a time.
    """
    path = folder / f'model-eq{k}.gro'
    path.write_text('')
    os.utime(path, (time, time))
    return path


def test_finished_stages_are_done_and_the_others_not_run(tmp_path):
    stages = [
        [final_gro(tmp_path, 0, 100)],
        [final_gro(tmp_path, 1, 200)],
        [Path('model-eq2.mdp')],
    ]

    assert stage_statuses(stages) == ['done', 'done', 'not run']


def test_a_stage_after_a_newer_one_is_outdated_and_so_are_the_stages_after_it(tmp_path):
    # eq1 ran again after eq2 and eq3
    times = [100, 400, 200, 300]
    stages = [[final_gro(tmp_path, k, time)] for k, time in enumerate(times)]

    assert stage_statuses(stages) == ['done', 'done', 'outdated', 'outdated']


def test_the_stage_a_run_is_on_is_running(tmp_path):
    stages = [[final_gro(tmp_path, 0, 100)], [final_gro(tmp_path, 1, 200)]]

    assert stage_statuses(stages, running=1) == ['done', 'running']


def test_a_posres_gro_is_not_the_final_gro(tmp_path):
    posres = tmp_path / 'model-eq0-posres.gro'
    posres.write_text('')

    assert stage_statuses([[posres]]) == ['not run']


def test_log_reader_takes_in_new_text_and_keeps_the_last_progress(tmp_path):
    log = tmp_path / 'equilibration.log'
    reader = LogReader(log)

    unwritten = reader.read()
    log.write_bytes(b'$ gmx mdrun -v\n\rstep 100')
    progress = reader.read()
    # Windows lines end in \r\n
    with log.open('ab') as stream:
        stream.write(b'\rstep 200\r\nWriting final coordinates.\r\n')

    assert unwritten == ''
    assert progress == '$ gmx mdrun -v\nstep 100'
    assert reader.read() == '$ gmx mdrun -v\nstep 200\nWriting final coordinates.\n'


def test_log_reader_keeps_a_character_split_between_reads_whole(tmp_path):
    log = tmp_path / 'equilibration.log'
    text = 'rmin 1 Å'.encode()
    log.write_bytes(text[:-1])
    reader = LogReader(log)

    first = reader.read()
    with log.open('ab') as stream:
        stream.write(text[-1:] + b'\n')

    assert first == 'rmin 1 '
    assert reader.read() == 'rmin 1 Å\n'
