# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from types import SimpleNamespace

import pytest

from easyshapes_app.Backends.real_py.config import Config

pytestmark = pytest.mark.usefixtures('qcore_application')


@pytest.mark.parametrize(
    ('version', 'problem', 'shown'),
    [
        ('2025.3', None, ('2025.3', '')),
        (None, 'gmx was not found on PATH', ('', 'gmx was not found on PATH')),
    ],
    ids=['runs', "can't run"],
)
def test_gromacs_status_reads_the_file_managers_config(monkeypatch, version, problem, shown):
    config = SimpleNamespace(gmx_version=version, gmx_problem=problem)
    monkeypatch.setattr(
        'easyshapes_app.Backends.real_py.config.AppFileManager',
        lambda: SimpleNamespace(config=config),
    )
    part = Config()

    assert (part.gmxVersion, part.gmxProblem) == shown
