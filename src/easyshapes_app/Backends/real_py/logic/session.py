# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from dataclasses import dataclass

from shapes.project import Project
from shapes.project import SampleModel
from shapes.project.analysis import Analysis


@dataclass
class Session:
    """
    What the app works on, shared by the root and all logic.

    A sample model and an analysis can exist before a project. Creating
    the first project takes them in; loading a project replaces all
    three. Parts read them here every time and never keep their own
    reference.
    """

    project: Project | None = None
    sample_model: SampleModel | None = None
    analysis: Analysis | None = None
