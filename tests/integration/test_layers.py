# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project import Lipid
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
        {'dmin': 0.5, 'rmin': 0.25},
        {'dmin': 0.5, 'rmin': 1.5},
    ]
    # Each row's model reads its own layer's composition
    assert [first.get(row)['molRatio'] for row in range(first.count)] == [1.0, 1.0]
    assert [second.get(row)['molRatio'] for row in range(second.count)] == [2.5, 1.0]

    backend.components.remove(0)

    assert [second.get(row)['name'] for row in range(second.count)] == ['CHOL']


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
        'rmin': 0.25,
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
