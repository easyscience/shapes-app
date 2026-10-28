# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest
from shapes.project import Surfactant
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_generated_surfactant_joins_the_sample_with_its_structure_file(
    qcore_application, tmp_path
):
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('smiles', '', str(tmp_path / 'smiles'))
    generator = backend.smilesGenerator
    generator.name = 'SDS'
    generator.smiles = 'CCCCCCCCCCCCOS(=O)(=O)[O-]'
    generator.componentType = 'Surfactant'
    generator.boxX = 3.0
    generator.boxY = 3.0
    generator.boxZ = 3.0

    generator.generate()

    (sds,) = session.sample_model.structure.components
    assert type(sds) is Surfactant
    # Atoms keep the SMILES order: the tail's first carbon is Mint, the
    # last oxygen Mext
    assert (sds.mint, sds.mext) == (0, sds.number_of_atoms - 1)
    assert backend.componentsFiles.selectedComponent == 'SDS'
    assert [Path(path).name for path in backend.componentsFiles.files.paths] == ['SDS.gro']
    assert generator.nameTaken

    # A string the library can't build is refused; nothing is added
    generator.name = 'BAD'
    generator.smiles = 'C='
    with pytest.raises(ValueError):
        generator.generate()
    assert session.sample_model.structure.components.names == ('SDS',)
