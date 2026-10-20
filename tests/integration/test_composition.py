# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project import Lipid
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.composition import CompositionModel as Model
from easyshapes_app.Backends.real_py.logic.session import Session


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_composition_edits_survive_save_and_load_and_follow_removals(qcore_application, tmp_path):
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('mix', '', str(tmp_path / 'mix'))
    # ponytail: added through the library until the GUI can (step 5)
    components = session.sample_model.structure.components
    components.append(Lipid(name='DPPC'))
    components.append(Lipid(name='CHOL'))
    backend.sampleModel.refresh()
    model = backend.composition

    assert model.setData(model.index(0), 2.5, Model.MolRatioRole)
    assert model.setData(model.index(1), False, Model.PresentRole)
    backend.project.save()

    backend.project.load(str(tmp_path / 'mix'))
    model = backend.composition

    assert [model.get(row) for row in range(model.count)] == [
        {'name': 'DPPC', 'present': True, 'molRatio': 2.5},
        {'name': 'CHOL', 'present': False, 'molRatio': 1.0},
    ]

    backend.components.remove(0)

    assert [model.get(row)['name'] for row in range(model.count)] == ['CHOL']
