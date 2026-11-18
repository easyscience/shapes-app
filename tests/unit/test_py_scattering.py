# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import os
from types import SimpleNamespace

from shapes.project.analysis import SansCurve

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.scattering import Scattering
from tests.unit.factories import FakeAsset
from tests.unit.factories import FakeEquilibration
from tests.unit.factories import FakeSampleModel
from tests.unit.factories import FakeStage


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
    fake = FakeAsset(name, *([dat] if dat else []))
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
    analysis = analysis_of(
        curve('newer', eq0, touched(tmp_path / 'newer.dat', 200)),
        curve('older', eq0, touched(tmp_path / 'older.dat', 50)),
        curve('gone', FakeStage('eq1'), touched(tmp_path / 'gone.dat', 200)),
        curve('no data', eq0),
    )
    scattering = Scattering(Session(sample_model=FakeSampleModel(), analysis=analysis))

    scattering.refresh()

    assert [(row['name'], row['source'], row['status']) for row in rows(scattering.curves)] == [
        ('newer', 'eq0', 'done'),
        ('older', 'eq0', 'outdated'),
        ('gone', 'eq1', 'outdated'),
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
