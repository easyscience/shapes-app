# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from shapes.project import Ion

from easyshapes_app.Backends.real_py.library import Library
from tests.integration.conftest import bare_project


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_saved_project_is_listed_for_recent(tmp_path):
    project = bare_project('Ring')
    project.save_as(tmp_path / 'ring1')

    assert Library().availableProjects == [
        {
            'name': 'ring1',
            'path': str((tmp_path / 'ring1').resolve()),
            'modified': project.modified.astimezone().strftime('%d %b %Y %H:%M'),
        }
    ]


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_saved_ion_is_listed_for_the_counter_ion_picker():
    Ion(name='NA').save()

    assert Library().availableIons == ['NA']
