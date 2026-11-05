# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import os
from types import SimpleNamespace

from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.logic.session import Session
from easyshapes_app.Backends.real_py.structure_view import StructureView
from tests.unit.factories import GRO_ATOMS
from tests.unit.factories import FakeSampleModel
from tests.unit.factories import arrived
from tests.unit.factories import gro_text


def viewer_of(tmp_path, text=None, itp=None):
    """
    A viewer of a sample model holding a .gro of the text, or none; with
    an itp text, its structure holds an SDS of that topology file.
    """
    model = FakeSampleModel()
    if itp is not None:
        topology = tmp_path / 'SDS.itp'
        topology.write_text(itp)
        sds = SimpleNamespace(name='SDS', topology_file_path=topology)
        model = FakeSampleModel(SimpleNamespace(components=[sds]))
    gro = tmp_path / 'model.gro'
    if text is not None:
        gro.write_text(text)
        model.add_new_files([gro])
    return StructureView(Session(sample_model=model)), gro


def test_atoms_are_read_only_while_the_tab_is_shown(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path, gro_text())
    atoms = QSignalSpy(view.instancing.atomsChanged)

    view.refresh()
    assert (view.hasStructure, view.loading, atoms.count()) == (True, False, 0)

    view.setActive(True)
    assert view.loading
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    assert (view.instancing.atomCount, view.loading, view.error) == (3, False, '')


def test_the_residues_of_the_file_are_listed(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path, gro_text())
    residues = view.instancing.residues

    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))

    first = residues.index(0)
    assert residues.count == 1
    assert (residues.data(first, residues.NameRole), residues.data(first, residues.CountRole)) == (
        'SDS',
        3,
    )


def test_the_shown_file_is_read_again_only_once_rewritten(qcore_application, tmp_path):
    view, gro = viewer_of(tmp_path, gro_text())
    view.keepLoaded = True
    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))

    view.setActive(False)
    view.setActive(True)
    view.refresh()
    assert not view.loading

    gro.write_text(gro_text(atoms=GRO_ATOMS[:2]))
    later = gro.stat().st_mtime_ns + 1_000_000_000
    os.utime(gro, ns=(later, later))
    view.refresh()
    assert view.loading
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    assert view.instancing.atomCount == 2


def test_hiding_the_tab_drops_the_atoms_unless_kept(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path, gro_text())
    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    view.instancing.slabFraction = 0.5

    view.setActive(False)
    assert (view.instancing.atomCount, view.instancing.slabFraction) == (0, 0.05)

    view.setActive(True)
    assert view.loading
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    assert view.instancing.atomCount == 3


def test_keep_loaded_and_show_bonds_read_back_and_emit_only_on_change(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path)
    kept = QSignalSpy(view.keepLoadedChanged)

    view.keepLoaded = True
    view.keepLoaded = True
    view.showBonds = True

    assert (view.keepLoaded, view.showBonds, kept.count()) == (True, True, 1)


def test_unticking_keep_loaded_while_hidden_drops_the_atoms(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path, gro_text())
    view.keepLoaded = True
    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))

    view.setActive(False)
    assert view.instancing.atomCount == 3

    view.keepLoaded = False
    assert view.instancing.atomCount == 0


def test_atoms_read_after_the_tab_hid_are_not_shown(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path, gro_text())
    view.setActive(True)
    # The read's result waits in the event queue until arrived()
    done = QSignalSpy(view.loadingChanged)
    view.setActive(False)

    assert arrived(done)
    assert (view.loading, view.instancing.atomCount) == (False, 0)

    view.setActive(True)
    assert view.loading
    assert arrived(QSignalSpy(view.instancing.atomsChanged))


def test_a_file_that_cant_be_read_says_why(qcore_application, tmp_path):
    lines = gro_text().split('\n')
    lines[3] += '  0.1000'
    view, _ = viewer_of(tmp_path, '\n'.join(lines))
    errors = QSignalSpy(view.errorChanged)

    view.setActive(True)

    assert arrived(errors)
    assert 'atom lines differ in length' in view.error
    assert (view.instancing.atomCount, view.loading) == (0, False)


def test_show_bonds_reads_the_file_again_with_or_without_bonds(qcore_application, tmp_path):
    # The factory's three atoms are one SDS: C1-S1, S1-H1
    view, _ = viewer_of(tmp_path, gro_text(), '[ moleculetype ]\nSDS  3\n\n[ bonds ]\n1 2\n2 3\n')
    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    view.instancing.slabFraction = 1.0
    bond_rows = view.instancing.bondInstancing.getInstanceBuffer

    for show, halves in ((True, 4), (False, 0)):
        view.showBonds = show
        assert view.loading
        assert arrived(QSignalSpy(view.instancing.atomsChanged))
        assert bond_rows()[1] == halves


def test_a_topology_that_cant_be_read_says_why(qcore_application, tmp_path):
    # A bond line of one field
    view, _ = viewer_of(tmp_path, gro_text(), '[ moleculetype ]\nSDS  3\n\n[ bonds ]\n1\n')
    view.showBonds = True
    errors = QSignalSpy(view.errorChanged)

    view.setActive(True)

    assert arrived(errors)
    assert (view.error, view.loading) == ('list index out of range', False)


def test_a_model_without_a_gro_has_no_structure(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path)

    view.setActive(True)

    assert (view.hasStructure, view.loading, view.instancing.atomCount) == (False, False, 0)


def test_a_read_drops_the_old_atoms_and_keeps_the_slab(qcore_application, tmp_path):
    view, _ = viewer_of(tmp_path, gro_text())
    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    view.instancing.slabFraction = 0.5

    view.showBonds = True

    assert (view.loading, view.instancing.atomCount, view.instancing.slabFraction) == (
        True,
        0,
        0.5,
    )
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    assert view.instancing.atomCount == 3


def test_an_assembly_drops_the_atoms_until_it_ends(qcore_application, tmp_path):
    model = FakeSampleModel()
    gro = tmp_path / 'model.gro'
    gro.write_text(gro_text())
    model.add_new_files([gro])
    view = StructureView(Session(sample_model=model))
    view.setActive(True)
    assert arrived(QSignalSpy(view.instancing.atomsChanged))

    model.assemble()
    view.refresh()
    assert (view.hasStructure, view.loading, view.instancing.atomCount) == (False, False, 0)

    model.job.end()
    view.refresh()
    assert view.loading
    assert arrived(QSignalSpy(view.instancing.atomsChanged))
    assert view.instancing.atomCount == 3
