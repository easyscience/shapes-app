# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
What the app works on, shared by the backend root and its parts.
"""

from dataclasses import dataclass

from shapes.project import Lattice
from shapes.project import Project
from shapes.project import SampleModel
from shapes.project.analysis import Analysis


@dataclass
class Session:
    """
    What the app works on, shared by the root and the parts.

    A sample model and an analysis can exist before a project. Creating
    the first project takes them in; loading a project replaces all
    three. Parts read them here every time. Only a structure adapter
    keeps its object, and the root replaces the adapter whenever the
    structure is replaced.
    """

    project: Project | None = None
    sample_model: SampleModel | None = None
    analysis: Analysis | None = None

    @property
    def components(self):
        """
        The components of the current structure, a lattice's from its
        motif; empty before the first sample model.
        """
        if self.sample_model is None:
            return ()
        structure = self.sample_model.structure
        return (structure.motif if isinstance(structure, Lattice) else structure).components
