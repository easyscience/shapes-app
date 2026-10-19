# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_py.lattice_structure import LatticeStructure
from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.project import Project
from easyshapes_app.Backends.real_py.rod_structure import RodStructure
from easyshapes_app.Backends.real_py.sample_model import SampleModel


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_structure_survives_project_save_and_load(qcore_application, tmp_path):
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    project = Project(session)
    sample_model = SampleModel(session)
    rod = RodStructure(session)
    lattice = LatticeStructure(session)

    project.create('rods', '', str(tmp_path / 'rods'))
    sample_model.shape = 'Rod'
    sample_model.lattice = True
    rod.turns = 3
    rod.dmin = 0.7
    lattice.nlatx = 2
    lattice.latticeType = 'LFCC'
    project.save()
    saved = session.sample_model

    project.load(str(tmp_path / 'rods'))

    assert session.sample_model is not saved
    assert (sample_model.shape, sample_model.lattice) == ('Rod', True)
    assert (rod.turns, rod.dmin) == (3, 0.7)
    assert (lattice.nlatx, lattice.latticeType) == (2, 'LFCC')
