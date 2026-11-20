# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import os
from types import SimpleNamespace

import numpy as np
import pytest
from PySide6.QtTest import QSignalSpy
from shapes.project.analysis import SansCurve

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.scattering import Scattering
from tests.unit.factories import REFUSED
from tests.unit.factories import FakeAsset
from tests.unit.factories import FakeEquilibration
from tests.unit.factories import FakeJob
from tests.unit.factories import FakeSampleModel
from tests.unit.factories import FakeStage
from tests.unit.factories import refusals


class FakeCurve(FakeAsset):
    """
    Stands in for a SansCurve: calculate starts a FakeJob, or raises its
    refusal, as a check before the start does; data is what a test sets.
    """

    def __init__(self, name, *paths):
        super().__init__(name, *paths)
        self.job = None
        self.refusal = None
        self.data = None

    @property
    def files_locked(self):
        return self.job is not None and self.job.running

    def check_files_unlocked(self):
        if self.files_locked:
            raise RuntimeError(f'Files of {self.name} are being written by a run')

    def calculate(self, sample_model, *, background=False):
        if self.refusal:
            raise ValueError(self.refusal)
        self.job = FakeJob()


def touched(path, time):
    """
    An empty file at a path, last written at a time.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.touch()
    os.utime(path, (time, time))
    return path


def stage(folder, k, time):
    """
    Stage eq<k> once finished: its final .gro written at a time.
    """
    return FakeStage(f'eq{k}', touched(folder / f'eq{k}' / f'model-eq{k}.gro', time))


def curve(name, source, dat=None, **settings):
    """
    A SansCurve of a source with SansCurve's default settings but the
    given ones, holding a .dat or none yet.
    """
    fake = FakeCurve(name, *([dat] if dat else []))
    fake.source = source
    fake.rg = 24.1
    fake.q_min = SansCurve.DEFAULT_Q_MIN
    fake.q_max = SansCurve.DEFAULT_Q_MAX
    fake.q_points = SansCurve.DEFAULT_Q_POINTS
    fake.solvent_sld = SansCurve.DEFAULT_SOLVENT_SLD
    fake.deuterated = ()
    fake.size_spread = SansCurve.DEFAULT_SIZE_SPREAD
    fake.kernel = SansCurve.DEFAULT_KERNEL
    for key, value in settings.items():
        setattr(fake, key, value)
    return fake


def analysis_of(*curves, equilibration=None):
    """
    An analysis holding the curves, and an equilibration with no stage
    unless given.
    """
    return SimpleNamespace(
        equilibration=equilibration or FakeEquilibration('equil0.mdp'), sans=list(curves)
    )


def rows(model):
    return [model.get(row) for row in range(model.count)]


def on_cta60(tmp_path):
    """
    The model CTA60, assembled, of the component CTA, and its finished
    stage eq5, the newest row and so the pick, with a Scattering on
    them, its lists read.
    """
    model = FakeSampleModel(SimpleNamespace(components=[SimpleNamespace(name='CTA')]))
    model.name = 'CTA60'
    model.add_new_files([touched(tmp_path / 'CTA60.gro', 50)])
    equilibration = FakeEquilibration('equil0.mdp')
    eq5 = stage(tmp_path, 5, 100)
    equilibration.stages = [eq5]
    analysis = analysis_of(equilibration=equilibration)
    scattering = Scattering(Session(sample_model=model, analysis=analysis))
    scattering.refresh()
    return SimpleNamespace(model=model, eq5=eq5, analysis=analysis, scattering=scattering)


def test_settings_come_from_the_newest_curve_once_per_analysis():
    model = FakeSampleModel()
    analysis = analysis_of(
        curve('old', model, q_points=100), curve('new', model, solvent_sld=6.36, q_points=128)
    )
    session = Session(sample_model=model, analysis=analysis)
    scattering = Scattering(session)

    filled = (scattering.solventSld, scattering.qPoints)
    scattering.solventSld = 1.0
    scattering.refresh()
    typed = scattering.solventSld
    session.analysis = analysis_of()
    scattering.refresh()

    assert (filled, typed, scattering.solventSld, scattering.qPoints) == (
        (6.36, 128),
        1.0,
        SansCurve.DEFAULT_SOLVENT_SLD,
        SansCurve.DEFAULT_Q_POINTS,
    )


@pytest.mark.parametrize(
    ('name', 'value'),
    [('qMin', 0.005), ('qMax', 0.5), ('qPoints', 128), ('sizeSpread', 0.1), ('kernel', 'average')],
)
def test_each_setting_reaches_the_next_curve(qcore_application, name, value):
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis_of()))
    changed = QSignalSpy(getattr(scattering, f'{name}Changed'))

    setattr(scattering, name, value)
    setattr(scattering, name, value)

    assert getattr(scattering, name) == value
    assert changed.count() == 1


def test_structures_are_the_model_then_the_finished_stages(tmp_path):
    model = FakeSampleModel()
    model.add_new_files([touched(tmp_path / 'model.gro', 50)])
    equilibration = FakeEquilibration('equil0.mdp')
    # eq1 runs again; eq2 has not run
    equilibration.stages = [stage(tmp_path, 0, 100), stage(tmp_path, 1, 200), FakeStage('eq2')]
    equilibration.stage = 1
    session = Session(sample_model=model, analysis=analysis_of(equilibration=equilibration))
    scattering = Scattering(session)

    scattering.refresh()

    assert rows(scattering.structures) == [
        {'name': model.name, 'status': ''},
        {'name': 'eq0', 'status': 'done'},
    ]


def test_a_pick_stays_until_a_stage_finishes(tmp_path):
    model = FakeSampleModel()
    model.add_new_files([touched(tmp_path / 'model.gro', 50)])
    equilibration = FakeEquilibration('equil0.mdp')
    equilibration.stages = [stage(tmp_path, 0, 100)]
    session = Session(sample_model=model, analysis=analysis_of(equilibration=equilibration))
    scattering = Scattering(session)

    scattering.refresh()
    newest = scattering.selectedStructure
    scattering.selectStructure(0)
    scattering.refresh()
    kept = scattering.selectedStructure
    equilibration.stages.append(stage(tmp_path, 1, 200))
    scattering.refresh()

    assert (newest, kept, scattering.selectedStructure) == (1, 0, 2)


def test_a_curve_is_outdated_once_its_structure_is_newer_or_gone(tmp_path):
    eq0 = stage(tmp_path, 0, 100)
    model = FakeSampleModel()
    model.add_new_files([touched(tmp_path / 'model.gro', 100)])
    analysis = analysis_of(
        curve('newer', eq0, touched(tmp_path / 'newer.dat', 200)),
        curve('older', eq0, touched(tmp_path / 'older.dat', 50)),
        curve('gone', FakeStage('eq1'), touched(tmp_path / 'gone.dat', 200)),
        curve('no data', eq0),
        # Read from the model's own .gro
        curve('of model', model, touched(tmp_path / 'of model.dat', 200)),
    )
    scattering = Scattering(Session(sample_model=model, analysis=analysis))

    scattering.refresh()

    assert [(row['name'], row['source'], row['status']) for row in rows(scattering.curves)] == [
        ('newer', 'eq0', 'done'),
        ('older', 'eq0', 'outdated'),
        ('gone', 'eq1', 'outdated'),
        ('of model', model.name, 'done'),
    ]


def test_a_hidden_curve_stays_hidden_and_a_new_one_shows(tmp_path):
    eq0 = stage(tmp_path, 0, 100)
    analysis = analysis_of(curve('first', eq0, touched(tmp_path / 'first.dat', 200)))
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis))
    scattering.refresh()

    scattering.setCurveShown(0, False)
    analysis.sans.append(curve('second', eq0, touched(tmp_path / 'second.dat', 200)))
    scattering.refresh()

    assert [row['shown'] for row in rows(scattering.curves)] == [False, True]


def test_a_hidden_curve_shows_again(tmp_path):
    eq0 = stage(tmp_path, 0, 100)
    analysis = analysis_of(curve('first', eq0, touched(tmp_path / 'first.dat', 200)))
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis))
    scattering.refresh()
    scattering.setCurveShown(0, False)

    scattering.setCurveShown(0, True)

    assert scattering.curves.get(0)['shown']


def test_curve_rows_by_role_match_get(qcore_application, tmp_path):
    eq0 = stage(tmp_path, 0, 100)
    analysis = analysis_of(curve('first', eq0, touched(tmp_path / 'first.dat', 200)))
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis))
    scattering.refresh()
    curves = scattering.curves

    # As QML reads a row: each role through data
    by_role = {
        name.decode(): curves.data(curves.index(0), role)
        for role, name in curves.roleNames().items()
    }

    assert by_role == curves.get(0)
    assert refusals(curves) == REFUSED


def test_ticks_keep_the_components_order_and_leave_with_their_component():
    components = [SimpleNamespace(name=name) for name in ('CTA', 'SDS', 'CHL')]
    model = FakeSampleModel(SimpleNamespace(components=components))
    scattering = Scattering(Session(sample_model=model, analysis=analysis_of()))
    scattering.refresh()

    scattering.setDeuterated('CHL', True)
    scattering.setDeuterated('CTA', True)
    ordered = scattering.deuterated
    components.pop(0)
    scattering.refresh()

    assert (ordered, scattering.deuterated, scattering.components) == (
        ['CTA', 'CHL'],
        ['CHL'],
        ['SDS', 'CHL'],
    )


def test_an_untick_drops_the_component():
    components = [SimpleNamespace(name=name) for name in ('CTA', 'SDS')]
    model = FakeSampleModel(SimpleNamespace(components=components))
    scattering = Scattering(Session(sample_model=model, analysis=analysis_of()))
    scattering.refresh()
    scattering.setDeuterated('CTA', True)
    scattering.setDeuterated('SDS', True)

    scattering.setDeuterated('CTA', False)

    assert scattering.deuterated == ['SDS']


def test_a_new_curve_is_named_after_its_structure_and_settings(tmp_path):
    cta60 = on_cta60(tmp_path)
    scattering = cta60.scattering
    scattering.solventSld = 6.36
    scattering.setDeuterated('CTA', True)

    of_stage = scattering._curve().name
    scattering.selectStructure(0)
    of_model = scattering._curve().name
    # A curve with another q range holds the model's name
    cta60.analysis.sans.append(
        curve(of_model, cta60.model, q_points=100, solvent_sld=6.36, deuterated=('CTA',))
    )
    taken = scattering._curve().name

    assert (of_stage, of_model, taken) == (
        'CTA60-eq5-sld6.36-dCTA-pd0.25',
        'CTA60-sld6.36-dCTA-pd0.25',
        'CTA60-sld6.36-dCTA-pd0.25-2',
    )


@pytest.mark.parametrize(
    ('error', 'shown'), [(None, ''), ('SincCity failed', 'SincCity failed'), ('Cancelled', '')]
)
def test_the_curve_with_these_settings_runs_again(qcore_application, tmp_path, error, shown):
    cta60 = on_cta60(tmp_path)
    again = curve('eq5 curve', cta60.eq5)
    cta60.analysis.sans.append(again)
    scattering = cta60.scattering
    ended = QSignalSpy(scattering.externalCalculated)

    scattering.calculate()
    running = (scattering.runningCurve, scattering.filesLocked)
    again.job.end(error)
    ended.wait(1000)

    assert running == ('eq5 curve', True)
    assert (scattering.runningCurve, scattering.filesLocked) == ('', False)
    assert cta60.analysis.sans == [again]
    assert ended.at(0) == [shown]


def test_a_new_curve_that_succeeds_joins_the_list_shown(qcore_application, tmp_path):
    cta60 = on_cta60(tmp_path)
    new = curve('new', cta60.eq5, touched(tmp_path / 'new.dat', 200))
    scattering = cta60.scattering
    ended = QSignalSpy(scattering.externalCalculated)

    scattering._start(new)
    listed = scattering.curves.count
    new.job.end()
    ended.wait(1000)

    assert (listed, cta60.analysis.sans) == (0, [new])
    assert [(row['name'], row['shown']) for row in rows(scattering.curves)] == [('new', True)]


def test_cancel_ends_the_run_at_once(qcore_application, tmp_path):
    cta60 = on_cta60(tmp_path)
    again = curve('eq5 curve', cta60.eq5)
    cta60.analysis.sans.append(again)
    scattering = cta60.scattering
    ended = QSignalSpy(scattering.externalCalculated)

    scattering.calculate()
    scattering.cancel()

    assert again.job.error == 'Cancelled'
    assert not scattering.filesLocked
    assert ended.at(0) == ['']


def test_a_check_during_the_run_keeps_watching(qcore_application, tmp_path):
    cta60 = on_cta60(tmp_path)
    again = curve('eq5 curve', cta60.eq5)
    cta60.analysis.sans.append(again)
    scattering = cta60.scattering
    ended = QSignalSpy(scattering.externalCalculated)
    scattering.calculate()

    # As the watch's timer does while the run goes on
    scattering._check()

    assert (scattering.runningCurve, scattering.filesLocked) == ('eq5 curve', True)
    assert ended.count() == 0


def test_calculate_without_a_structure_is_refused(qcore_application):
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis_of()))
    scattering.refresh()

    with pytest.raises(ValueError, match='assemble the sample model first'):
        scattering.calculate()

    assert not scattering.filesLocked


def test_a_check_failing_before_the_start_starts_no_run(qcore_application, tmp_path):
    cta60 = on_cta60(tmp_path)
    cta60.analysis.sans.append(curve('eq5 curve', cta60.eq5, refusal='eq5 holds no .gro'))
    scattering = cta60.scattering
    locked = QSignalSpy(scattering.filesLockedChanged)

    with pytest.raises(ValueError, match='holds no .gro'):
        scattering.calculate()

    assert (scattering.filesLocked, scattering.runningCurve, locked.count()) == (False, '', 0)


def test_points_and_ranges_are_log10_over_the_shown_curves(tmp_path):
    eq0 = stage(tmp_path, 0, 100)
    # An I of 0 has no log: its point is left out
    first = curve(
        'first',
        eq0,
        touched(tmp_path / 'first.dat', 200),
        data=SimpleNamespace(x=np.array([0.01, 0.1, 1.0]), y=np.array([100.0, 1.0, 0.0])),
    )
    second = curve(
        'second',
        eq0,
        touched(tmp_path / 'second.dat', 200),
        data=SimpleNamespace(x=np.array([0.001, 10.0]), y=np.array([1000.0, 0.001])),
    )
    scattering = Scattering(
        Session(sample_model=FakeSampleModel(), analysis=analysis_of(first, second))
    )
    scattering.refresh()

    points = [value for point in scattering.curvePoints(0) for value in (point.x(), point.y())]
    both = scattering.ranges
    scattering.setCurveShown(1, False)

    assert points == pytest.approx([-2, 2, -1, 0])
    assert both == pytest.approx({'xmin': -3, 'xmax': 1, 'ymin': -3, 'ymax': 3})
    assert scattering.ranges == pytest.approx({'xmin': -2, 'xmax': -1, 'ymin': 0, 'ymax': 2})


def test_ranges_without_a_shown_curve_are_0_to_1(tmp_path):
    eq0 = stage(tmp_path, 0, 100)
    analysis = analysis_of(curve('hidden', eq0, touched(tmp_path / 'hidden.dat', 200)))
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis))
    scattering.refresh()

    scattering.setCurveShown(0, False)

    assert scattering.ranges == {'xmin': 0, 'xmax': 1, 'ymin': 0, 'ymax': 1}


def test_export_copies_the_shown_curves_and_asks_before_replacing(tmp_path):
    eq0 = stage(tmp_path, 0, 100)
    analysis = analysis_of(
        curve('shown', eq0, touched(tmp_path / 'curves' / 'shown.dat', 200)),
        curve('hidden', eq0, touched(tmp_path / 'curves' / 'hidden.dat', 200)),
    )
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis))
    scattering.refresh()
    scattering.setCurveShown(1, False)
    export = tmp_path / 'export'
    export.mkdir()

    free = scattering.exportTaken(str(export))
    scattering.exportTo(str(export), False)
    taken = scattering.exportTaken(str(export))
    with pytest.raises(FileExistsError, match='already holds'):
        scattering.exportTo(str(export), False)
    scattering.exportTo(str(export), True)

    assert (free, taken) == (False, True)
    assert [path.name for path in export.iterdir()] == ['shown.dat']


def test_a_curve_being_written_is_not_removed(tmp_path):
    busy = curve('busy', stage(tmp_path, 0, 100), touched(tmp_path / 'busy.dat', 200))
    busy.job = FakeJob()
    analysis = analysis_of(busy)
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis))
    scattering.refresh()

    with pytest.raises(RuntimeError, match='being written'):
        scattering.removeCurve(0)

    assert (scattering.curves.count, analysis.sans) == (1, [busy])
