# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.project import Project
from tests.unit.factories import LOADED_AT
from tests.unit.factories import SAVED_AT
from tests.unit.factories import FakeProject

pytestmark = pytest.mark.usefixtures('qcore_application')


class OfflineProject(Project):
    """
    Builds and loads FakeProjects, not library ones.
    """

    _project_class = FakeProject


def local_text(moment):
    return moment.astimezone().strftime('%d %b %Y %H:%M')


def test_fields_are_empty_without_project():
    part = OfflineProject(Session())

    assert part.created is False
    assert (part.name, part.description, part.path, part.pathParentUrl, part.modified) == (
        '',
        '',
        '',
        '',
        '',
    )


def test_setters_do_nothing_without_project():
    part = OfflineProject(Session())
    spy = QSignalSpy(part.nameChanged)

    part.name = 'ring'

    assert part.name == ''
    assert spy.count() == 0


def test_name_setter_emits_only_on_change():
    part = OfflineProject(Session())
    part.create('ring', '', '')
    spy = QSignalSpy(part.nameChanged)

    part.name = 'rod'
    part.name = 'rod'

    assert part.name == 'rod'
    assert spy.count() == 1


def test_description_setter_emits_only_on_change():
    part = OfflineProject(Session())
    part.create('ring', 'a ring', '')
    spy = QSignalSpy(part.descriptionChanged)

    part.description = 'a rod'
    part.description = 'a rod'

    assert part.description == 'a rod'
    assert spy.count() == 1


def test_first_create_takes_in_session_sample_model_and_analysis():
    sample_model, analysis = object(), object()
    session = Session(sample_model=sample_model, analysis=analysis)

    OfflineProject(session).create('ring', 'a ring', '')

    assert session.project.init_args == {
        'name': 'ring',
        'sample_model': sample_model,
        'analysis': analysis,
        'path': None,
    }
    assert session.sample_model is sample_model
    assert session.analysis is analysis


def test_create_with_a_project_starts_fresh():
    session = Session()
    part = OfflineProject(session)
    part.create('first', '', '')
    first_model = session.sample_model

    part.create('second', '', '')

    assert session.project.init_args['sample_model'] is None
    assert session.sample_model is not first_model


def test_create_passes_empty_name_and_path_as_none():
    session = Session()

    OfflineProject(session).create('', '', '')

    assert session.project.init_args['name'] is None
    assert session.project.init_args['path'] is None


def test_create_with_path_gives_path_and_parent_url(tmp_path):
    part = OfflineProject(Session())

    part.create('ring', '', str(tmp_path / 'ring1'))

    assert part.path == str(tmp_path / 'ring1')
    assert part.pathParentUrl == tmp_path.as_uri()


@pytest.mark.parametrize('action', ['create', 'load'])
def test_create_and_load_emit_every_signal_once(action):
    part = OfflineProject(Session())
    spies = [
        QSignalSpy(signal)
        for signal in (
            part.createdChanged,
            part.nameChanged,
            part.descriptionChanged,
            part.pathChanged,
            part.modifiedChanged,
            part.externalProjectChanged,
        )
    ]

    if action == 'create':
        part.create('ring', '', '')
    else:
        part.load(str(Path.home() / 'Projects' / 'ring1'))

    assert [spy.count() for spy in spies] == [1, 1, 1, 1, 1, 1]


def test_load_replaces_project_sample_model_and_analysis():
    session = Session(sample_model=object(), analysis=object())
    part = OfflineProject(session)

    part.load(str(Path.home() / 'Projects' / 'ring1'))

    assert part.name == 'Loaded'
    assert session.sample_model is session.project.sample_model
    assert session.analysis is session.project.analysis
    assert part.modified == local_text(LOADED_AT)


def test_save_updates_modified_and_tells_the_root():
    session = Session()
    part = OfflineProject(session)
    part.create('ring', '', '')
    modified = QSignalSpy(part.modifiedChanged)
    external = QSignalSpy(part.externalProjectChanged)

    part.save()

    assert session.project.save_calls == 1
    assert part.modified == local_text(SAVED_AT)
    assert (modified.count(), external.count()) == (1, 1)


def test_location_is_taken_only_when_something_is_there(tmp_path):
    part = OfflineProject(Session())
    empty = tmp_path / 'empty'
    empty.mkdir()
    full = tmp_path / 'full'
    full.mkdir()
    (full / 'notes.txt').touch()
    a_file = tmp_path / 'a_file'
    a_file.touch()

    assert part.locationTaken('') is False
    assert part.locationTaken(str(tmp_path / 'missing')) is False
    assert part.locationTaken(str(empty)) is False
    assert part.locationTaken(str(full)) is True
    assert part.locationTaken(str(a_file)) is True
