# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session


def mdp_names(session):
    return [path.name for path in session.analysis.equilibration.configuration.paths]


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_the_first_model_brings_an_analysis_with_charmm36(qcore_application):
    session = Session()
    backend = Backend(session)

    backend.sampleModel.create()

    assert session.analysis.sample_model is session.sample_model
    assert session.analysis.equilibration.configuration.name == 'CHARMM36'
    assert mdp_names(session) == ['equil0.mdp']


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_a_later_project_fills_its_own_analysis_too(qcore_application, tmp_path):
    session = Session()
    backend = Backend(session)
    backend.sampleModel.create()
    backend.project.create('first', '', str(tmp_path / 'first'))
    first = session.analysis

    backend.project.create('second', '', str(tmp_path / 'second'))

    assert session.analysis is not first
    assert mdp_names(session) == ['equil0.mdp']


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_configuration_saved_under_a_new_name_joins_the_catalog_and_loads_back(
    qcore_application, tmp_path
):
    session = Session()
    backend = Backend(session)
    backend.sampleModel.create()
    part = backend.configuration

    part.load('CHARMM36')
    loaded = [Path(path).name for path in part.files.paths]
    part.name = 'Mine'
    assert not part.nameTaken()
    part.save(False)
    part.load('Mine')
    part.exportTo(str(tmp_path / 'export'), False)

    assert loaded == ['equil0.mdp']
    assert sorted(backend.library.availableAnalysisConfigurations) == ['CHARMM36', 'Mine']
    assert part.name == 'Mine'
    assert session.analysis.equilibration.configuration.name == 'Mine'
    assert [Path(path).name for path in part.files.paths] == ['equil0.mdp']
    assert part.exportTaken(str(tmp_path / 'export'))


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_equilibration_setup_survives_project_save_and_load(qcore_application, tmp_path):
    session = Session()
    backend = Backend(session)
    backend.sampleModel.create()
    backend.project.create('setup', '', str(tmp_path / 'setup'))
    part = backend.equilibration

    part.threads = '4'
    part.restrainToBoxCenter = True
    backend.project.save()
    saved = session.analysis
    backend.project.load(str(tmp_path / 'setup'))

    assert session.analysis is not saved
    assert (part.firstStage, part.lastStage, part.threads, part.restrainToBoxCenter) == (
        0,
        0,
        '4',
        True,
    )


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_equilibrate_on_a_model_not_assembled_is_refused(qcore_application):
    backend = Backend(Session())
    backend.sampleModel.create()

    with pytest.raises(ValueError, match='assemble it with a buffer first'):
        backend.equilibration.run()

    assert not backend.equilibration.filesLocked
