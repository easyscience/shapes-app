# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project import Ion
from shapes.project import Lipid
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.components import ComponentsModel as Model
from easyshapes_app.Backends.real_py.logic.session import Session


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_component_edits_survive_project_save_and_load(qcore_application, tmp_path):
    # In the offline library, where the counter-ion picker finds it
    Ion(name='NA').save()
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('lipids', '', str(tmp_path / 'lipids'))
    # ponytail: added through the library until the GUI can (step 5)
    session.sample_model.structure.components.append(Lipid(name='DPPC'))
    backend.components.refresh()
    model = backend.components.loaded
    row = model.index(0)
    (ion,) = backend.library.availableIons

    assert model.setData(row, 'POPC', Model.NameRole)
    assert model.setData(row, ion, Model.CounterIonRole)
    assert model.setData(row, 3, Model.MintRole)
    assert model.setData(row, 9, Model.MextRole)
    backend.project.save()

    backend.project.load(str(tmp_path / 'lipids'))

    assert model.get(0) == {
        'name': 'POPC',
        'componentType': 'Lipid',
        'counterIon': 'NA',
        'mint': 3,
        'mext': 9,
        'nameError': '',
    }
