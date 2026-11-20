# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from types import SimpleNamespace

from shapes.project.analysis import SansCurve
from shapes.project.files import AppFileManager

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.scattering import Scattering


def test_a_removed_curve_goes_with_its_files(qcore_application):
    curve = SansCurve(name='removed-curve')
    dat = AppFileManager().locate_asset_dir(curve) / 'removed-curve.dat'
    dat.write_text('0.01,1.0\n0.1,0.5\n', encoding='utf-8')
    curve.paths = [dat]
    analysis = SimpleNamespace(equilibration=SimpleNamespace(stages=[], stage=None), sans=[curve])
    scattering = Scattering(Session(analysis=analysis))
    scattering.refresh()

    listed = scattering.curves.count
    scattering.removeCurve(0)

    assert (listed, scattering.curves.count, analysis.sans) == (1, 0, [])
    assert curve.paths == ()
    assert not dat.exists()
