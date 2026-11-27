# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
Builders for the example projects the Project page lists.
"""

import math
import shutil
from pathlib import Path

from shapes.project import Ball
from shapes.project import Ion
from shapes.project import Lipid
from shapes.project import Project
from shapes.project import SampleModel
from shapes.project import Surfactant
from shapes.project import Vesicle
from shapes.project.species import Buffer
from shapes.project.species import Components
from shapes.project.species import Solvent

# The lamellae repeat every 6.6 nm, as in POPC multilamellar vesicles:
# 6.4 nm (Holme et al. 2018), plus 0.23 nm for 30 mol% cholesterol
# (Utterström et al. 2022). That is a bilayer of about 4 nm and 2.6 nm
# of water. The first lamella at 3 nm keeps the vesicle small
MLV_RMINS = (3.0, 9.6)
# The bilayer after equilibration. The straight library molecules
# don't fit in it, so the two leaflets start overlapping
MLV_SHELL = 4.0
# Inner and outer leaflet dmin, from the vesicle in the Shapespyer
# workshop. Two-tail lipids need more room than the default 0.5 nm
MLV_DMINS = (0.65, 0.85)


def build_mlv(path):
    """
    Save the example of tutorial 1 to a folder, not assembled.

    It is a dry vesicle of POPC and cholesterol (70 : 30) with two
    lamellae. It is never solvated, so it assembles without GROMACS.
    """
    components = Components(items=[Lipid.load('POPC'), Lipid.load('CHL')])
    vesicle = Vesicle(name='MLV', components=components)
    vesicle.lamellae.add()
    for lamella, rmin in zip(vesicle.lamellae, MLV_RMINS, strict=True):
        lamella.rmin = rmin
        lamella.shell_thickness = MLV_SHELL
        lamella.inner_leaflet_dmin, lamella.outer_leaflet_dmin = MLV_DMINS
        lamella.inner_leaflet_composition.set_mol_ratio('POPC', 70)
        lamella.inner_leaflet_composition.set_mol_ratio('CHL', 30)
    project = Project(
        name='MLV',
        path=path,
        title='Multilamellar vesicle',
        description='Dry POPC and cholesterol (70 : 30), two lamellae 6.6 nm apart.',
        sample_model=SampleModel(name='MLV', structure=vesicle),
        is_example=True,
    )
    project.save()
    return project


def build_sds_ball(path):
    """
    Save the example of tutorial 2 to a folder, not assembled.

    It is a ball of SDS with its sodium counter ions, in water. Its
    first layer is the one of the Shapespyer SDS ball tutorial: 16
    molecules on the equator, 0.4 nm apart.
    """
    sds = Surfactant.load('SDS')
    sds.counter_ion = Ion.load('NAT')
    ball = Ball(name='SDSBall', components=Components(items=[sds]))
    ball.layers[0].dmin = 0.4
    ball.layers[0].rmin = round(16 * 0.4 / (2 * math.pi), 2)
    project = Project(
        name='SDSBall',
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


# The examples, by the folder each is saved in: Project › Examples
# lists those folders by name
EXAMPLES = {'MLV': build_mlv, 'SDSBall': build_sds_ball}


def make_examples(folder, names=tuple(EXAMPLES), *, assemble=False):
    """
    Save examples into a folder, each in a subfolder of its name.

    The folder can be the app's Examples folder. Skip the examples the
    folder holds already. assemble=True also assembles each one, which
    takes minutes, and needs GROMACS for an example with a buffer.
    """
    for name in names:
        path = Path(folder) / name
        if path.exists():
            continue
        partial = path.with_name(f'{name}.partial')
        # Left by a run that failed
        shutil.rmtree(partial, ignore_errors=True)
        project = EXAMPLES[name](partial)
        if assemble:
            project.sample_model.assemble()
            # Keeps the assembled files in the folder, not in Temp
            project.save()
        # Renamed once complete: a failed run leaves no half example
        partial.rename(path)
