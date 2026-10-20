# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project import Ball
from shapes.project import Lattice
from shapes.project import Lipid
from shapes.project import Rod
from shapes.project import SampleModel as SampleModelLib

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.logic.structure import shaped
from easyshapes_app.Backends.real_py.sample_model import SampleModel


@pytest.mark.fast
def test_shape_switch_keeps_components_and_detaches_old_composition(qcore_application):
    sample_model = SampleModelLib()
    part = SampleModel(Session(sample_model=sample_model))
    components = sample_model.structure.components
    old = sample_model.structure.composition

    part.shape = 'Ball'
    components.append(Lipid(name='POPC'))

    assert type(sample_model.structure) is Ball
    assert sample_model.structure.components is components
    assert part.shape == 'Ball'
    assert len(old) == 0
    assert len(sample_model.structure.layers[0].composition) == 1


@pytest.mark.fast
def test_vesicle_switch_detaches_each_leaflet_composition_once(qcore_application):
    sample_model = SampleModelLib()
    part = SampleModel(Session(sample_model=sample_model))
    part.shape = 'Vesicle'
    vesicle = sample_model.structure
    vesicle.lamellae.add()
    vesicle.lamellae[0].symmetric = False
    leaflets = [
        vesicle.lamellae[0].inner_leaflet_composition,
        vesicle.lamellae[0].outer_leaflet_composition,
        vesicle.lamellae[1].inner_leaflet_composition,  # shared with its outer leaflet
    ]

    part.shape = 'Ring'
    vesicle.components.append(Lipid(name='POPC'))

    assert [len(composition) for composition in leaflets] == [0, 0, 0]


@pytest.mark.fast
def test_lattice_wraps_and_unwraps_the_discrete_structure(qcore_application):
    sample_model = SampleModelLib()
    part = SampleModel(Session(sample_model=sample_model))
    ring = sample_model.structure

    part.lattice = True
    assert isinstance(sample_model.structure, Lattice)
    assert sample_model.structure.unit is ring
    assert shaped(sample_model, 'Ring') is ring
    assert shaped(sample_model, 'Ball') is None

    part.shape = 'Rod'
    assert isinstance(sample_model.structure, Lattice)
    assert part.shape == 'Rod'

    part.lattice = False
    assert type(sample_model.structure) is Rod
