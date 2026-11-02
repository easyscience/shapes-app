# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import math

import pytest
from shapes.project import Ion
from shapes.project import Lipid
from shapes.project import Surfactant
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.components import ComponentsModel as Model
from easyshapes_app.Backends.real_py.logic.session import Session


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_component_edits_survive_project_save_and_load(qcore_application, tmp_path):
    # In the offline library, where the counter-ion picker and the Load
    # popup find them
    Ion(name='NA').save()
    Lipid(name='DPPC').save()
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('lipids', '', str(tmp_path / 'lipids'))
    backend.components.append('Lipid', 'DPPC')
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


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_loaded_and_imported_components_join_the_composition(qcore_application, tmp_path):
    Lipid(name='DPPC').save()
    Lipid(name='POPC').export_to(tmp_path / 'POPC')
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('lipids', '', str(tmp_path / 'lipids'))

    (lipid,) = backend.library.availableAssets['Lipid']
    backend.components.append('Lipid', lipid)
    backend.components.importFrom(str(tmp_path / 'POPC'))

    assert session.sample_model.structure.components.names == ('DPPC', 'POPC')
    composition = backend.composition
    assert [composition.get(row)['name'] for row in range(composition.count)] == ['DPPC', 'POPC']


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_viewer_reads_the_structure_file_the_bone_is_measured_on(qcore_application, tmp_path):
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('smiles', '', str(tmp_path / 'smiles'))
    sds = Surfactant.from_smiles('SDS', 'CCCCCCCCCCCCOS(=O)(=O)[O-]', (3.0, 3.0, 3.0))
    backend.components.loaded.append(sds)

    atoms = backend.components.structureAtoms(0)

    assert len(atoms) == sds.number_of_atoms
    assert {atom['element'] for atom in atoms} <= {'C', 'H', 'O', 'S'}
    for axis in 'xyz':
        assert sum(atom[axis] for atom in atoms) == pytest.approx(0, abs=1e-6)
    # Å on screen, nm in the library
    ends = [[atoms[row][axis] for axis in 'xyz'] for row in (sds.mint, sds.mext)]
    assert math.dist(*ends) / 10 == pytest.approx(backend.components.boneLength(0))
    assert backend.components.boneLength(0) > 0
