# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
Shape and lattice switches of a sample model's structure.

The library holds one structure per sample model, one class per shape. A
switch builds a new structure over the same components.
"""

from shapes.project import Ball
from shapes.project import Bilayer
from shapes.project import Lattice
from shapes.project import Monolayer
from shapes.project import Ring
from shapes.project import Rod
from shapes.project import Vesicle

# GUI name of each shape, in the order the shape list shows them
SHAPES = {
    'Ring': Ring,
    'Ball': Ball,
    'Vesicle': Vesicle,
    'Rod': Rod,
    'Bilayer': Bilayer,
    'Monolayer': Monolayer,
}


def shaped(sample_model, name):
    """
    The discrete structure while it has the named shape, else None. No
    sample model gives None too.
    """
    if sample_model is None:
        return None
    structure = sample_model.structure
    unit = structure.unit if isinstance(structure, Lattice) else structure
    return unit if type(unit) is SHAPES[name] else None
