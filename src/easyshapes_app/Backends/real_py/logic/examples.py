# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import math

from shapes.project import Ball, Ion, Lipid, Project, SampleModel, Surfactant, Vesicle
from shapes.project.species import Buffer, Components, Salt, Solvent

# T1's lamellae start 6.6 nm apart: the repeat distance of POPC
# multilamellar vesicles, 6.4 nm (Holme et al. 2018), plus 0.23 nm
# for 30 mol% cholesterol (Utterström et al. 2022)
MLV_RMINS = (5.0, 11.6)


def build_mlv(path):
    """
    Save the example of tutorial 1 to a folder: a vesicle of POPC and
    cholesterol (70 : 30) with two lamellae, in 0.15 M NaCl. Not
    assembled.
    """
    # Components first: a lamella works out its shell from the
    # molecules it holds when it is made
    components = Components([Lipid.load('POPC'), Lipid.load('CHL')])
    vesicle = Vesicle(name='MLV', components=components)
    vesicle.lamellae.add()
    for lamella, rmin in zip(vesicle.lamellae, MLV_RMINS, strict=True):
        lamella.rmin = rmin
        lamella.inner_leaflet_composition.set_mol_ratio('POPC', 70)
        lamella.inner_leaflet_composition.set_mol_ratio('CHL', 30)
    buffer = Buffer(name='NaCl', solvent=Solvent.load('TIP3'))
    buffer.components.append(
        Salt(name='NaCl', cation=Ion.load('NAT'), anion=Ion.load('CLA'), concentration=0.15)
    )
    project = Project(
        path=path,
        title='Multilamellar vesicle',
        description=(
            'POPC and cholesterol (70 : 30) in 0.15 M NaCl, '
            'two lamellae 6.6 nm apart.'
        ),
        sample_model=SampleModel(name='MLV', structure=vesicle, buffer=buffer),
        is_example=True,
    )
    project.save()
    return project


def build_sds_ball(path):
    """
    Save the example of tutorial 2 to a folder: a ball of SDS with its
    sodium counter ions, in water. Its first layer is the one of the
    Shapespyer SDS ball tutorial: 16 molecules on the equator, 0.4 nm
    apart. Not assembled.
    """
    sds = Surfactant.load('SDS')
    sds.counter_ion = Ion.load('NAT')
    ball = Ball(name='SDSBall', components=Components([sds]))
    ball.layers[0].dmin = 0.4
    ball.layers[0].rmin = 16 * 0.4 / (2 * math.pi)
    project = Project(
        path=path,
        title='SDS ball',
        description=(
            'A ball of SDS with sodium counter ions in water, as in the '
            'Shapespyer SDS ball tutorial.'
        ),
        sample_model=SampleModel(
            name='SDSBall',
            structure=ball,
            buffer=Buffer(name='Water', solvent=Solvent.load('TIP3')),
        ),
        is_example=True,
    )
    project.save()
    return project
