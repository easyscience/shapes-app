# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project import Ball
from shapes.project import Lattice
from shapes.project import Lipid
from shapes.project import Rod
from shapes.project import SampleModel

from easyshapes_app.Backends.real_py.logic.structure import discrete
from easyshapes_app.Backends.real_py.logic.structure import set_lattice
from easyshapes_app.Backends.real_py.logic.structure import set_shape
from easyshapes_app.Backends.real_py.logic.structure import shape
from easyshapes_app.Backends.real_py.logic.structure import shaped


@pytest.mark.fast
def test_shape_switch_keeps_components_and_detaches_old_composition():
    sample_model = SampleModel()
    components = sample_model.structure.components
    old = sample_model.structure.composition

    set_shape(sample_model, 'Ball')
    components.append(Lipid(name='POPC'))

    assert type(sample_model.structure) is Ball
    assert sample_model.structure.components is components
    assert shape(sample_model) == 'Ball'
    assert len(old) == 0
    assert len(sample_model.structure.layers[0].composition) == 1


@pytest.mark.fast
def test_vesicle_switch_detaches_each_leaflet_composition_once():
    sample_model = SampleModel()
    set_shape(sample_model, 'Vesicle')
    vesicle = sample_model.structure
    vesicle.lamellae.add()
    vesicle.lamellae[0].symmetric = False
    leaflets = [
        vesicle.lamellae[0].inner_leaflet_composition,
        vesicle.lamellae[0].outer_leaflet_composition,
        vesicle.lamellae[1].inner_leaflet_composition,  # shared with its outer leaflet
    ]

    set_shape(sample_model, 'Ring')
    vesicle.components.append(Lipid(name='POPC'))

    assert [len(composition) for composition in leaflets] == [0, 0, 0]


@pytest.mark.fast
def test_lattice_wraps_and_unwraps_the_discrete_structure():
    sample_model = SampleModel()
    ring = sample_model.structure

    set_lattice(sample_model, True)
    assert isinstance(sample_model.structure, Lattice)
    assert discrete(sample_model) is ring
    assert shaped(sample_model, 'Ring') is ring
    assert shaped(sample_model, 'Ball') is None

    set_shape(sample_model, 'Rod')
    assert isinstance(sample_model.structure, Lattice)
    assert shape(sample_model) == 'Rod'

    set_lattice(sample_model, False)
    assert type(sample_model.structure) is Rod
