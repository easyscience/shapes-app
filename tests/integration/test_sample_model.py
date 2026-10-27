# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_structure_survives_project_save_and_load(qcore_application, tmp_path):
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)

    backend.project.create('rods', '', str(tmp_path / 'rods'))
    backend.sampleModel.shape = 'Rod'
    backend.sampleModel.lattice = True
    backend.rodStructure.turns = 3
    backend.rodStructure.dmin = 0.7
    backend.latticeStructure.nlatx = 2
    backend.latticeStructure.latticeType = 'LFCC'
    backend.project.save()
    saved = session.sample_model

    backend.project.load(str(tmp_path / 'rods'))

    assert session.sample_model is not saved
    assert (backend.sampleModel.shape, backend.sampleModel.lattice) == ('Rod', True)
    assert (backend.rodStructure.turns, backend.rodStructure.dmin) == (3, 0.7)
    assert (backend.latticeStructure.nlatx, backend.latticeStructure.latticeType) == (2, 'LFCC')


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_sample_model_saved_exported_loaded_and_imported_stays_one_model(
    qcore_application, tmp_path
):
    gro = tmp_path / 'model.gro'
    gro.write_text('model\n')
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('models', '', str(tmp_path / 'models'))
    part = backend.sampleModel

    part.name = 'TstModel'
    part.shape = 'Rod'
    part.appendFile(str(gro))
    assert not part.nameTaken()
    part.save(False)
    part.exportTo(str(tmp_path / 'export'), False)
    saved = session.sample_model
    part.load('TstModel')
    loaded = session.sample_model
    part.importFrom(str(tmp_path / 'export'))
    imported = session.sample_model
    backend.project.save()
    backend.project.load(str(tmp_path / 'models'))

    assert backend.library.availableAssets['SampleModel'] == ['TstModel']
    assert part.nameTaken()
    assert saved is not loaded is not imported
    assert (loaded.name, imported.name) == ('TstModel', 'TstModel')
    # The saved project holds one model, the analysis's too
    assert session.project.analysis.sample_model is session.project.sample_model
    assert (part.name, part.shape) == ('TstModel', 'Rod')
    assert [Path(path).name for path in part.files.paths] == ['model.gro']
