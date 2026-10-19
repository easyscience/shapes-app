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


def discrete(sample_model):
    """
    The discrete structure: the model's own, or the unit its lattice
    repeats.
    """
    structure = sample_model.structure
    return structure.unit if isinstance(structure, Lattice) else structure


def shape(sample_model):
    """
    GUI name of the discrete structure's shape.
    """
    structure = discrete(sample_model)
    return next(name for name, cls in SHAPES.items() if type(structure) is cls)


def is_lattice(sample_model):
    """
    Whether a lattice repeats the discrete structure.
    """
    return isinstance(sample_model.structure, Lattice)


def shaped(sample_model, name):
    """
    The discrete structure while it has the named shape, else None. No
    sample model gives None too.
    """
    if sample_model is None or shape(sample_model) != name:
        return None
    return discrete(sample_model)


def set_shape(sample_model, name):
    """
    Replace the discrete structure with a new one of another shape, over
    the same components and with the library defaults. The old
    compositions stop following the components.
    """
    old = discrete(sample_model)
    if type(old) is SHAPES[name]:
        return
    for composition in _compositions(old):
        composition.detach()
    new = SHAPES[name](components=old.components)
    if is_lattice(sample_model):
        sample_model.structure.unit = new
    else:
        sample_model.structure = new


def set_lattice(sample_model, lattice):
    """
    Wrap the discrete structure in a new lattice, or unwrap it. Unwrap
    drops the lattice settings.
    """
    structure = sample_model.structure
    if is_lattice(sample_model) == lattice:
        return
    sample_model.structure = Lattice(unit=structure) if lattice else structure.unit


def _compositions(structure):
    """
    Every composition a discrete structure holds, each once.
    """
    if isinstance(structure, Ball):
        return [layer.composition for layer in structure.layers]
    if isinstance(structure, Vesicle):
        compositions = []
        for lamella in structure.lamellae:
            compositions.append(lamella.inner_leaflet_composition)
            # Symmetric leaflets share one composition
            if not lamella.symmetric:
                compositions.append(lamella.outer_leaflet_composition)
        return compositions
    return [structure.composition]
