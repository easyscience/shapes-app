# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path
from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.sample_model import SampleModel
from tests.unit.factories import FakeAnalysis
from tests.unit.factories import FakeProject
from tests.unit.factories import FakeSampleModel

pytestmark = pytest.mark.usefixtures('qcore_application')


class FakeLibrary:
    """
    Holds a FakeSampleModel named DemoSavedModel.
    """

    def has_entry(self, asset_type, name):
        return (asset_type, name) == ('FakeSampleModel', 'DemoSavedModel')


class OfflineSampleModel(SampleModel):
    """
    Creates FakeSampleModels and FakeAnalyses, and checks names in
    FakeLibrary, not in the library.
    """

    _sample_model_class = FakeSampleModel
    _library_class = FakeLibrary
    _analysis_class = FakeAnalysis


class NoAnalysis:
    """
    An analysis the library can't give, as without CHARMM36.
    """

    def __init__(self, sample_model):
        raise ValueError('The library holds no ForceField CHARMM36')


class UnanalysableSampleModel(OfflineSampleModel):
    """
    Builds analyses the library can't give.
    """

    _analysis_class = NoAnalysis


def all_signals(part):
    return [
        QSignalSpy(signal)
        for signal in (
            part.nameChanged,
            part.shapeChanged,
            part.latticeChanged,
            part.externalStructureChanged,
        )
    ]


def test_fields_are_empty_and_setters_do_nothing_without_sample_model():
    part = SampleModel(Session())
    spies = all_signals(part)

    part.name = 'vesicles'
    part.shape = 'Ball'
    part.lattice = True

    assert (part.name, part.shape, part.lattice) == ('', '', False)
    assert [spy.count() for spy in spies] == [0, 0, 0, 0]


def test_create_makes_a_sample_model_only_when_there_is_none():
    # An analysis held before a project takes the new model too
    session = Session(analysis=SimpleNamespace(sample_model=None))
    part = OfflineSampleModel(session)
    spies = all_signals(part)

    part.create()
    first = session.sample_model
    part.create()

    assert session.sample_model is first
    assert session.analysis.sample_model is first
    assert (part.name, part.shape, part.lattice) == ('uid0002', 'Ring', False)
    assert [spy.count() for spy in spies] == [1, 1, 1, 1]


def test_the_first_model_brings_the_session_its_analysis():
    session = Session()

    OfflineSampleModel(session).create()

    assert isinstance(session.analysis, FakeAnalysis)
    assert session.analysis.sample_model is session.sample_model


def test_an_analysis_the_library_cant_give_leaves_the_session_as_it_was():
    session = Session()
    part = UnanalysableSampleModel(session)
    spies = all_signals(part)

    with pytest.raises(ValueError, match='CHARMM36'):
        part.create()

    assert (session.sample_model, session.analysis) == (None, None)
    assert [spy.count() for spy in spies] == [0, 0, 0, 0]


@pytest.mark.parametrize(
    ('slot', 'argument', 'name'),
    [('load', 'DemoSavedModel', 'DemoSavedModel'), ('importFrom', '/exports/Demo', 'Demo')],
)
def test_load_and_import_give_session_analysis_and_project_one_new_model(slot, argument, name):
    old = FakeSampleModel()
    analysis = SimpleNamespace(sample_model=old)
    session = Session(
        project=FakeProject(sample_model=old, analysis=analysis),
        sample_model=old,
        analysis=analysis,
    )
    part = OfflineSampleModel(session)
    spies = all_signals(part)

    getattr(part, slot)(argument)

    new = session.sample_model
    assert new is not old
    assert session.project.sample_model is new
    assert session.analysis.sample_model is new
    assert part.name == name
    assert [spy.count() for spy in spies] == [1, 1, 1, 1]


@pytest.mark.parametrize(
    ('field', 'value', 'external'),
    [('name', 'vesicles', 0), ('shape', 'Ball', 1), ('lattice', True, 1)],
)
def test_setters_emit_only_on_change(field, value, external):
    part = SampleModel(Session(sample_model=FakeSampleModel()))
    changed = QSignalSpy(getattr(part, f'{field}Changed'))
    structure_replaced = QSignalSpy(part.externalStructureChanged)

    setattr(part, field, value)
    setattr(part, field, value)

    assert getattr(part, field) == value
    assert (changed.count(), structure_replaced.count()) == (1, external)


def test_file_changes_go_to_the_sample_model():
    sample_model = FakeSampleModel()
    part = SampleModel(Session(sample_model=sample_model))

    part.appendFile('model.top')
    part.appendFile('model.gro')
    # Rows are sorted: model.gro, then model.top
    part.removeFile(1)

    assert sample_model.paths == (Path('model.gro'),)
    assert part.files.paths == sample_model.paths


def test_edit_file_opens_the_rows_file(opened):
    part = SampleModel(Session(sample_model=FakeSampleModel()))
    part.appendFile('model.gro')

    part.editFile(0)

    assert opened == [Path('model.gro')]


def test_shapes_are_the_libraries_shape_names():
    assert SampleModel(Session()).shapes == [
        'Ring',
        'Ball',
        'Vesicle',
        'Rod',
        'Bilayer',
        'Monolayer',
    ]


def test_rename_reads_the_files_again():
    sample_model = FakeSampleModel()
    part = SampleModel(Session(sample_model=sample_model))
    # A real rename moves the files of the model's working folder;
    # the list, not filled yet, must read them
    sample_model.add_new_files(['vesicles/model.gro'])

    part.name = 'vesicles'

    assert part.files.paths == (Path('vesicles/model.gro'),)


def test_refresh_shows_the_files_of_the_new_model_or_none():
    sample_model = FakeSampleModel()
    sample_model.add_new_files(['model.gro'])
    session = Session(sample_model=sample_model)
    part = SampleModel(session)

    part.refresh()
    shown = part.files.paths
    session.sample_model = None
    part.refresh()

    assert shown == (Path('model.gro'),)
    assert part.files.paths == ()


def test_name_is_taken_by_a_library_entry_of_its_class():
    part = OfflineSampleModel(Session(sample_model=FakeSampleModel()))

    free = part.nameTaken()
    part.name = 'DemoSavedModel'

    assert not free
    assert part.nameTaken()


def test_save_writes_the_model_and_refreshes_the_catalogs():
    sample_model = FakeSampleModel()
    part = SampleModel(Session(sample_model=sample_model))
    saved = QSignalSpy(part.externalAssetsChanged)

    part.save(True)

    assert sample_model.calls == [('save', True)]
    assert saved.count() == 1


def test_export_taken_checks_the_whole_folder(tmp_path):
    part = SampleModel(Session(sample_model=FakeSampleModel()))
    (tmp_path / 'model.gro').write_text('')

    assert part.exportTaken(str(tmp_path))
    assert not part.exportTaken(str(tmp_path / 'empty'))


def test_export_to_exports_the_whole_model():
    sample_model = FakeSampleModel()
    part = SampleModel(Session(sample_model=sample_model))

    part.exportTo('export', True)

    assert sample_model.calls == [('export_to', 'export', True)]


class QuickSampleModel(OfflineSampleModel):
    """
    Checks a running assembly every 10 ms.
    """

    _watch_interval = 10


class Unassemblable(FakeSampleModel):
    """
    Fails the checks assemble makes before it starts.
    """

    def assemble(self, *, background=False):
        raise ValueError('Ring has no components')


@pytest.mark.parametrize(
    ('error', 'shown'), [(None, ''), ('gmx failed', 'gmx failed'), ('Cancelled', '')]
)
def test_assembly_runs_until_its_job_ends_and_reports_an_error(error, shown):
    sample_model = FakeSampleModel()
    part = QuickSampleModel(Session(sample_model=sample_model))
    locked = QSignalSpy(part.filesLockedChanged)
    assembled = QSignalSpy(part.externalAssembled)

    part.assemble()
    running = part.filesLocked
    # As the library registers the run's output and log
    sample_model.add_new_files(['uid0002.gro', 'assembly.log'])
    sample_model.job.end(error)
    assembled.wait(1000)

    assert running
    assert not part.filesLocked
    assert locked.count() == 2
    assert assembled.at(0) == [shown]
    # Rows are sorted: assembly.log, then uid0002.gro
    assert part.files.paths == (Path('assembly.log'), Path('uid0002.gro'))


def test_a_check_failing_before_the_start_starts_no_run():
    part = QuickSampleModel(Session(sample_model=Unassemblable()))
    locked = QSignalSpy(part.filesLockedChanged)

    with pytest.raises(ValueError):
        part.assemble()

    assert not part.filesLocked
    assert locked.count() == 0


def test_cancel_ends_the_run_at_once():
    sample_model = FakeSampleModel()
    part = QuickSampleModel(Session(sample_model=sample_model))
    assembled = QSignalSpy(part.externalAssembled)

    part.assemble()
    part.cancel()

    assert sample_model.job.error == 'Cancelled'
    assert not part.filesLocked
    assert assembled.at(0) == ['']


def test_a_replacement_cancels_the_run_at_once():
    sample_model = FakeSampleModel()
    part = QuickSampleModel(Session(sample_model=sample_model))
    replaced = []

    part.assemble()
    part.after_assembly(lambda: replaced.append('replaced'))

    assert replaced == ['replaced']
    assert sample_model.job.error == 'Cancelled'


@pytest.mark.parametrize('slot', ['load', 'importFrom'])
def test_load_and_import_cancel_the_run_then_replace(slot):
    old = FakeSampleModel()
    session = Session(sample_model=old)
    part = QuickSampleModel(session)

    part.assemble()
    getattr(part, slot)('DemoSavedModel')

    assert old.job.error == 'Cancelled'
    assert session.sample_model is not old


def test_a_replacement_that_raises_still_ends_the_run():
    part = QuickSampleModel(Session(sample_model=FakeSampleModel()))

    def fail():
        raise KeyError('ring')

    part.assemble()
    # Raised to the caller: from a slot, the app's hook shows it in the
    # error dialog
    with pytest.raises(KeyError):
        part.after_assembly(fail)

    assert not part.filesLocked
