# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project import Lipid
from shapes.project import Surfactant
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.composition import CompositionModel
from easyshapes_app.Backends.real_py.lamellae import LamellaeModel
from easyshapes_app.Backends.real_py.layers import LayersModel
from easyshapes_app.Backends.real_py.logic.session import Session


def shaped_backend(shape, path):
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('mix', '', str(path))
    backend.sampleModel.shape = shape
    # ponytail: added through the library until the GUI can (step 5)
    components = session.sample_model.structure.components
    components.append(Lipid(name='DPPC'))
    components.append(Lipid(name='CHOL'))
    backend.sampleModel.refresh()
    return backend


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_layer_edits_survive_save_and_load_and_follow_removals(qcore_application, tmp_path):
    backend = shaped_backend('Ball', tmp_path / 'ball')
    layers = backend.layers
    layers.add()
    assert layers.setData(layers.index(1), 1.5, LayersModel.RminRole)
    composition = layers.compositions[1]
    assert composition.setData(composition.index(0), 2.5, CompositionModel.MolRatioRole)
    backend.project.save()

    backend.project.load(str(tmp_path / 'ball'))
    layers = backend.layers
    first, second = layers.compositions

    assert [layers.get(row) for row in range(layers.count)] == [
        # DPPC and CHOL have no structure files: no bone to measure
        {'dmin': 0.5, 'rmin': 1.2, 'thickness': None},
        {'dmin': 0.5, 'rmin': 1.5, 'thickness': None},
    ]
    # Each row's model reads its own layer's composition
    assert [first.get(row)['molRatio'] for row in range(first.count)] == [1.0, 1.0]
    assert [second.get(row)['molRatio'] for row in range(second.count)] == [2.5, 1.0]

    backend.components.remove(0)

    assert [second.get(row)['name'] for row in range(second.count)] == ['CHOL']


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_thickness_and_full_radius_follow_bones_and_compositions(qcore_application, tmp_path):
    backend = shaped_backend('Ball', tmp_path / 'ball')
    layers = backend.layers
    sds = Surfactant.from_smiles('SDS', 'CCCCCCCCCCCCOS(=O)(=O)[O-]', (3.0, 3.0, 3.0))
    radius = QSignalSpy(layers.fullRadiusChanged)

    # SDS joins the layer: its bone is the only one measured
    backend.components.loaded.append(sds)

    assert layers.get(0)['thickness'] == pytest.approx(sds.bone_length)
    assert layers.fullRadius == pytest.approx(layers.get(0)['rmin'] + sds.bone_length)
    assert radius.count() > 0

    # Unticked, SDS is not placed; DPPC and CHOL have no bones
    composition = layers.compositions[0]
    names = [composition.get(row)['name'] for row in range(composition.count)]
    sds_row = composition.index(names.index('SDS'))
    radius = QSignalSpy(layers.fullRadiusChanged)
    assert composition.setData(sds_row, False, CompositionModel.PresentRole)

    assert (layers.get(0)['thickness'], layers.fullRadius) == (None, None)
    assert radius.count() > 0

    # Ticked again, then its structure file goes: no bone to measure
    assert composition.setData(sds_row, True, CompositionModel.PresentRole)
    files = backend.componentsFiles
    files.selectComponent('SDS')
    radius = QSignalSpy(layers.fullRadiusChanged)
    files.removeFile([path.suffix for path in files.files.paths].index('.gro'))

    assert (layers.get(0)['thickness'], layers.fullRadius) == (None, None)
    assert radius.count() > 0


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_ring_outer_radius_follows_bones_and_compositions(qcore_application, tmp_path):
    backend = shaped_backend('Ring', tmp_path / 'ring')
    ring = backend.ringStructure
    sds = Surfactant.from_smiles('SDS', 'CCCCCCCCCCCCOS(=O)(=O)[O-]', (3.0, 3.0, 3.0))
    sizes = QSignalSpy(ring.sizesChanged)

    # SDS joins the ring: its bone is the only one measured
    backend.components.loaded.append(sds)

    assert ring.outerRadius == pytest.approx(ring.rmin + sds.bone_length)
    assert sizes.count() > 0

    # Unticked, SDS is not placed; DPPC and CHOL have no bones
    composition = backend.composition
    names = [composition.get(row)['name'] for row in range(composition.count)]
    sizes = QSignalSpy(ring.sizesChanged)
    sds_row = composition.index(names.index('SDS'))
    assert composition.setData(sds_row, False, CompositionModel.PresentRole)

    assert ring.outerRadius is None
    assert sizes.count() > 0


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_vesicle_shell_and_full_radius_follow_bones(qcore_application, tmp_path):
    backend = shaped_backend('Vesicle', tmp_path / 'vesicle')
    lamellae = backend.lamellae
    sds = Surfactant.from_smiles('SDS', 'CCCCCCCCCCCCOS(=O)(=O)[O-]', (3.0, 3.0, 3.0))
    radius = QSignalSpy(lamellae.fullRadiusChanged)

    # SDS joins both leaflets: the shell is worked out from its bone
    backend.components.loaded.append(sds)

    first = lamellae.get(0)
    shell = 2 * sds.bone_length + first['outerLeafletDmin']
    assert first['shellThickness'] == pytest.approx(shell)
    assert lamellae.fullRadius == pytest.approx(first['rmin'] + shell)
    assert radius.count() > 0


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_split_lamella_survives_save_and_load_and_follows_removals(qcore_application, tmp_path):
    backend = shaped_backend('Vesicle', tmp_path / 'vesicle')
    lamellae = backend.lamellae
    lamellae.add()
    assert lamellae.setData(lamellae.index(1), False, LamellaeModel.SymmetricRole)
    assert lamellae.setData(lamellae.index(1), 2.0, LamellaeModel.ShellThicknessRole)
    outer = lamellae.outerLeafletCompositions[1]
    assert outer.setData(outer.index(1), False, CompositionModel.PresentRole)
    backend.project.save()

    backend.project.load(str(tmp_path / 'vesicle'))
    lamellae = backend.lamellae
    inner = lamellae.innerLeafletCompositions[1]
    outer = lamellae.outerLeafletCompositions[1]

    assert lamellae.get(1) == {
        'rmin': 1.2,
        'shellThickness': 2.0,
        'innerLeafletDmin': 0.5,
        'outerLeafletDmin': 0.5,
        'symmetric': False,
    }
    assert lamellae.outerLeafletCompositions[0] is None
    # The split outer model reads the copy, not the inner composition
    assert [inner.get(row)['present'] for row in range(inner.count)] == [True, True]
    assert [outer.get(row)['present'] for row in range(outer.count)] == [True, False]

    backend.components.remove(0)

    assert [outer.get(row)['name'] for row in range(outer.count)] == ['CHOL']
