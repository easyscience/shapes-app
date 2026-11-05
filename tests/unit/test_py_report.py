# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.report import Report

pytestmark = pytest.mark.usefixtures('qcore_application')


def project_named(name):
    """
    A project whose to_dict holds only its name.
    """
    data = {'name': {'dtype': 'str', 'data': name, 'module': 'builtins'}}
    serialized = {'module': 'shapes.project', 'dtype': 'Project', 'data': data, 'id': 'uid'}
    return SimpleNamespace(to_dict=lambda: serialized)


def test_the_text_is_the_projects_outline_read_on_refresh():
    session = Session()
    part = Report(session)
    changed = QSignalSpy(part.textChanged)

    part.refresh()
    empty = part.text
    session.project = project_named('ring1')
    part.refresh()
    part.refresh()

    assert (empty, part.text, part.error) == ('', 'Project\n  name: ring1', '')
    # The second refresh found nothing new
    assert changed.count() == 1


def test_a_project_the_library_cant_serialize_shows_why_in_place_of_the_text():
    def refuse():
        raise ValueError('Unexpected type ndarray to serialize')

    session = Session(project=project_named('ring1'))
    part = Report(session)
    part.refresh()

    session.project = SimpleNamespace(to_dict=refuse)
    part.refresh()
    failed = (part.text, part.error)
    session.project = project_named('ring1')
    part.refresh()

    assert failed == ('', "The project can't be summarized: Unexpected type ndarray to serialize")
    assert (part.text, part.error) == ('Project\n  name: ring1', '')
