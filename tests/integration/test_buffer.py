# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField
from shapes.project.species import Salt
from shapes.project.species import Solvent

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.buffer import BufferComponentsModel
from easyshapes_app.Backends.real_py.logic.session import Session


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_buffer_picked_from_the_catalogs_survives_save_and_load(qcore_application, tmp_path):
    # In the offline library, where the solvent picker and the Load
    # popup find them
    Solvent(name='TIP3').save()
    Salt(name='NaCl').save()
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('buffered', '', str(tmp_path / 'buffered'))
    (solvent,) = backend.library.availableSolvents
    (salt,) = backend.library.availableSalts
    backend.buffer.solvent = solvent
    backend.buffer.appendComponent(salt)
    components = backend.buffer.components
    assert components.setData(components.index(0), 150.0, BufferComponentsModel.ConcentrationRole)
    backend.project.save()

    backend.project.load(str(tmp_path / 'buffered'))
    components = backend.buffer.components

    assert backend.buffer.solvent == 'TIP3'
    assert [components.get(row) for row in range(components.count)] == [
        {'name': 'NaCl', 'concentration': 150.0}
    ]
    # The library holds mol/L
    assert session.sample_model.buffer.components[0].concentration == 0.15
