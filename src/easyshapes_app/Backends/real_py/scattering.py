# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
The analysis's SANS curves for QML.
"""

import shutil

import numpy as np
from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import QPointF
from PySide6.QtCore import Qt
from PySide6.QtCore import QTimer
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project.analysis import SansCurve
from shapes.project.analysis import Stage
from shapes.project.files import AppFileManager

from .equilibration import FINISHED
from .equilibration import EntriesModel
from .logic.analysis import stage_statuses
from .logic.files import export_taken
from .logic.session import Session


class CurvesModel(EntriesModel):
    """
    The analysis's SANS curves that hold data, as Scattering view lists
    them and the chart draws them. A row is a dict of the roles: the
    curve's name, its source's name and its settings, as SansCurve holds
    them; its Rg in Å; its status, 'done' or 'outdated' once its
    structure changed after it; and shown, whether the chart draws it.
    """

    # The role of each key of a row
    _ROLES = dict(
        enumerate(
            (
                'name',
                'source',
                'qMin',
                'qMax',
                'qPoints',
                'solventSld',
                'deuterated',
                'sizeSpread',
                'kernel',
                'rg',
                'status',
                'shown',
            ),
            start=Qt.UserRole + 1,
        )
    )

    def roleNames(self):
        """
        Map each role to the name QML reads it by.
        """
        return {role: key.encode() for role, key in self._ROLES.items()}

    def data(self, index, role=Qt.DisplayRole):
        """
        Return a row's value for a role, or None for another role.
        """
        key = self._ROLES.get(role)
        return self._rows[index.row()][key] if index.isValid() and key else None

    @Slot(int, result='QVariant')
    def get(self, row):
        """
        Return a row's roles.
        """
        return self._rows[row]


class Scattering(QObject):
    """
    The analysis's SANS curves for QML: the settings of the next one,
    the structures it can be calculated from, the components that can be
    deuterated, and the curves the analysis holds.

    The settings are a SansCurve's, under its parameter names. They are
    filled from the analysis's newest curve, or SansCurve's defaults
    without one, when the session holds another analysis; any other
    refresh keeps what was typed.
    """

    solventSldChanged = Signal()
    deuteratedChanged = Signal()
    qMinChanged = Signal()
    qMaxChanged = Signal()
    qPointsChanged = Signal()
    sizeSpreadChanged = Signal()
    kernelChanged = Signal()
    componentsChanged = Signal()
    selectedStructureChanged = Signal()
    filesLockedChanged = Signal()
    runningCurveChanged = Signal()
    rangesChanged = Signal()

    # A calculation ended, with its error ('' after success or a
    # cancel): the root shows the error
    externalCalculated = Signal(str)

    # How often a running calculation is checked, ms
    _watch_interval = 500

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        # What a curve can be calculated from: the rows, (name,
        # status), and each row's source, the sample model or a stage
        self._structures = EntriesModel(self)
        self._sources = []
        # Row of structures shown, -1 with none, and the row picked by
        # hand, by name, '' until one is
        self._selected_structure = -1
        self._picked = ''
        # The structure's components, by name: the ones that can be
        # deuterated
        self._components = []
        # The curves with data, and the names of those the chart leaves
        # out: page state, kept by name, so a new curve shows
        self._curves = CurvesModel(self)
        # The curve behind each row of curves
        self._listed = []
        self._hidden = set()
        # The curve being calculated, None without a run
        self._running = None
        # Reads files_locked while a run goes on
        self._watch = QTimer(self)
        self._watch.setInterval(self._watch_interval)
        self._watch.timeout.connect(self._check)
        # The next curve's settings, under SansCurve's parameter names,
        # and the analysis they were filled from
        self._settings = {}
        self._filled_from = None
        self._fill()

    ##########################
    # GUI accessible variables
    ##########################

    @Property('QVariant', constant=True)
    def structures(self):
        """
        The structures a curve can be calculated from.
        """
        return self._structures

    @Property(int, notify=selectedStructureChanged)
    def selectedStructure(self):
        """
        The row picked in the structures.
        """
        return self._selected_structure

    @Property(float, notify=solventSldChanged)
    def solventSld(self):
        """
        The next curve's solvent SLD.
        """
        return self._settings['solvent_sld']

    @solventSld.setter
    def solventSld(self, value):
        self._set('solvent_sld', value, self.solventSldChanged)

    @Property('QVariant', notify=deuteratedChanged)
    def deuterated(self):
        """
        The next curve's deuterated components.
        """
        return list(self._settings['deuterated'])

    @Property(float, notify=qMinChanged)
    def qMin(self):
        """
        The next curve's lowest q.
        """
        return self._settings['q_min']

    @qMin.setter
    def qMin(self, value):
        self._set('q_min', value, self.qMinChanged)

    @Property(float, notify=qMaxChanged)
    def qMax(self):
        """
        The next curve's highest q.
        """
        return self._settings['q_max']

    @qMax.setter
    def qMax(self, value):
        self._set('q_max', value, self.qMaxChanged)

    @Property(int, notify=qPointsChanged)
    def qPoints(self):
        """
        The next curve's number of q points.
        """
        return self._settings['q_points']

    @qPoints.setter
    def qPoints(self, value):
        self._set('q_points', value, self.qPointsChanged)

    @Property(float, notify=sizeSpreadChanged)
    def sizeSpread(self):
        """
        The next curve's size spread.
        """
        return self._settings['size_spread']

    @sizeSpread.setter
    def sizeSpread(self, value):
        self._set('size_spread', value, self.sizeSpreadChanged)

    @Property(str, notify=kernelChanged)
    def kernel(self):
        """
        The next curve's kernel.
        """
        return self._settings['kernel']

    @kernel.setter
    def kernel(self, value):
        self._set('kernel', value, self.kernelChanged)

    @Property('QVariant', notify=componentsChanged)
    def components(self):
        """
        The components that can be deuterated.
        """
        return self._components

    @Property('QVariant', constant=True)
    def curves(self):
        """
        The curves model.
        """
        return self._curves

    @Property(bool, notify=filesLockedChanged)
    def filesLocked(self):
        """
        True while a run writes the files.
        """
        # True until the check takes the ended run in
        return self._watch.isActive()

    @Property(str, notify=runningCurveChanged)
    def runningCurve(self):
        """
        The name of the curve being calculated, '' for none.
        """
        return self._running.name if self._running else ''

    @Property('QVariant', notify=rangesChanged)
    def ranges(self):
        """
        Over the shown curves, the smallest and largest log10 of q and
        I: xmin, xmax, ymin, ymax; 0 to 1 on both without one.
        """
        points = [
            point
            for row, curve in enumerate(self._listed)
            if curve.name not in self._hidden
            for point in self.curvePoints(row)
        ]
        if not points:
            return {'xmin': 0, 'xmax': 1, 'ymin': 0, 'ymax': 1}
        xs = [point.x() for point in points]
        ys = [point.y() for point in points]
        return {'xmin': min(xs), 'xmax': max(xs), 'ymin': min(ys), 'ymax': max(ys)}

    ##########################
    # GUI accessible functions
    ##########################

    @Slot(int)
    def selectStructure(self, index):
        """
        Show the row picked: it stays while it is listed.
        """
        self._picked = self._structures.get(index)['name']
        self._selected_structure = index
        self.selectedStructureChanged.emit()

    @Slot(str, bool)
    def setDeuterated(self, name, on):
        """
        Tick or untick a component. The ticked ones stay in the
        components' order, so the same ticks give the same settings.
        """
        ticked = set(self._settings['deuterated']) - {name}
        if on:
            ticked.add(name)
        deuterated = tuple(component for component in self._components if component in ticked)
        self._set('deuterated', deuterated, self.deuteratedChanged)

    @Slot(int, bool)
    def setCurveShown(self, row, on):
        """
        Draw a curve on the chart, or leave it out.
        """
        name = self._curves.get(row)['name']
        if on:
            self._hidden.discard(name)
        else:
            self._hidden.add(name)
        self._show_curves()

    @Slot()
    def calculate(self):
        """
        Calculate a curve of the picked structure with the settings, in
        the background: the curve with these settings again, or a new
        one, which joins the list once its run succeeds. A check that
        fails before the start raises, for the error dialog.
        """
        if self._selected_structure < 0:
            raise ValueError('No structure to calculate from: assemble the sample model first')
        self._start(self._curve())

    @Slot()
    def cancel(self):
        """
        Stop the running calculation; it ends at once. A new curve is
        dropped, and a curve calculated again keeps its old data.
        """
        self._running.job.cancel()
        self._check()

    @Slot(int, result='QVariant')
    def curvePoints(self, row):
        """
        Return a curve as points, log10 of q and I.

        They feed the chart's LineSeries.replace. A point whose q or I
        is not above 0 has no log and is left out.
        """
        data = self._listed[row].data
        keep = (data.x > 0) & (data.y > 0)
        q, intensity = data.x[keep], data.y[keep]
        return [QPointF(x, y) for x, y in zip(np.log10(q), np.log10(intensity), strict=True)]

    @Slot(str, result=bool)
    def exportTaken(self, folder):
        """
        Whether exporting the shown curves to a folder would replace a
        file: a .dat of the same name there.
        """
        shown = (curve for curve in self._listed if curve.name not in self._hidden)
        return any(export_taken(folder, curve.file_with_suffix('.dat')) for curve in shown)

    @Slot(str, bool)
    def exportTo(self, folder, overwrite):
        """
        Copy the .dat of each shown curve into a folder, as SasView
        reads it. Without overwrite, a folder holding one of them is
        refused: the page asks first.
        """
        if not overwrite and self.exportTaken(folder):
            raise FileExistsError(f'{folder} already holds .dat files of these curves')
        for curve in self._listed:
            if curve.name not in self._hidden:
                shutil.copy(curve.file_with_suffix('.dat'), folder)

    @Slot(int)
    def removeCurve(self, row):
        """
        Remove a curve and its files, after the page's dialog. A file a
        saved project lists goes at its next save, so a reload still
        finds it.
        """
        curve = self._listed[row]
        curve.check_files_unlocked()
        AppFileManager().discard_asset_paths(curve, curve.paths)
        self._session.analysis.sans.remove(curve)
        # A later curve of this name starts shown
        self._hidden.discard(curve.name)
        self._show_curves()

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Read everything again: another analysis or sample model, an
        assembly's start or end, a run's start or a finished stage, or a
        component added, renamed or removed. Another analysis refills
        the settings and forgets the pick and the hidden curves.
        """
        if self._session.analysis is not self._filled_from:
            self._fill()
            self._picked = ''
            self._hidden.clear()
        components = [component.name for component in self._session.components]
        if components != self._components:
            self._components = components
            self.componentsChanged.emit()
        # A ticked component that left the model is unticked
        ticked = self._settings['deuterated']
        deuterated = tuple(name for name in components if name in ticked)
        self._set('deuterated', deuterated, self.deuteratedChanged)
        self._show_structures()
        self._show_curves()

    def _set(self, key, value, changed):
        """
        Set one of the next curve's settings, announcing a change.
        """
        if self._settings[key] == value:
            return
        self._settings[key] = value
        changed.emit()

    def _fill(self):
        """
        Take the settings of the analysis's newest curve, the last one
        added, or SansCurve's defaults without one, and keep the
        analysis they came from.
        """
        analysis = self._session.analysis
        defaults = {
            'q_min': SansCurve.DEFAULT_Q_MIN,
            'q_max': SansCurve.DEFAULT_Q_MAX,
            'q_points': SansCurve.DEFAULT_Q_POINTS,
            'solvent_sld': SansCurve.DEFAULT_SOLVENT_SLD,
            'deuterated': (),
            'size_spread': SansCurve.DEFAULT_SIZE_SPREAD,
            'kernel': SansCurve.DEFAULT_KERNEL,
        }
        newest = analysis.sans[-1] if analysis and analysis.sans else None
        self._settings = {key: getattr(newest, key) for key in defaults} if newest else defaults
        self._filled_from = analysis
        for changed in (
            self.solventSldChanged,
            self.deuteratedChanged,
            self.qMinChanged,
            self.qMaxChanged,
            self.qPointsChanged,
            self.sizeSpreadChanged,
            self.kernelChanged,
        ):
            changed.emit()

    def _show_structures(self):
        """
        List the sample model, under its name, once its own .gro exists,
        then the equilibration's finished stages. Show the pick while it
        is listed, else the newest row; a stage listed for the first
        time becomes the pick.
        """
        sample_model = self._session.sample_model
        analysis = self._session.analysis
        rows = []
        sources = []
        # Its own .gro, not the equilibration's copy: a curve of the
        # model works before any Equilibrate
        if sample_model is not None and sample_model.file_with_suffix('.gro'):
            rows.append((sample_model.name, ''))
            sources.append(sample_model)
        if analysis is not None:
            equilibration = analysis.equilibration
            stages = equilibration.stages
            finals = [stage.final_structure for stage in stages]
            statuses = stage_statuses(finals, equilibration.stage)
            # A stage running again is left out: its files are about to
            # be replaced
            for stage, status in zip(stages, statuses, strict=True):
                if status in FINISHED:
                    rows.append((stage.name, status))
                    sources.append(stage)
        listed = {self._structures.get(row)['name'] for row in range(self._structures.rowCount())}
        # The newest stage just listed: one that has just finished
        self._picked = next(
            (name for name, status in reversed(rows) if status and name not in listed),
            self._picked,
        )
        self._structures.update(rows)
        self._sources = sources
        names = [name for name, _ in rows]
        self._selected_structure = (
            names.index(self._picked) if self._picked in names else len(rows) - 1
        )
        self.selectedStructureChanged.emit()

    def _show_curves(self):
        """
        List the analysis's curves that hold data, with their settings
        as SansCurve keeps them. A curve is outdated once its
        structure's .gro is newer than its .dat, or gone.
        """
        analysis = self._session.analysis
        rows = []
        listed = []
        for curve in analysis.sans if analysis else ():
            dat = curve.file_with_suffix('.dat')
            if dat is None:
                continue
            source = curve.source
            if isinstance(source, Stage):
                gro = source.final_structure
            else:
                gro = source.file_with_suffix('.gro') if source else None
            outdated = gro is None or gro.stat().st_mtime > dat.stat().st_mtime
            rows.append({
                'name': curve.name,
                'source': source.name if source else '',
                'qMin': curve.q_min,
                'qMax': curve.q_max,
                'qPoints': curve.q_points,
                'solventSld': curve.solvent_sld,
                'deuterated': list(curve.deuterated),
                'sizeSpread': curve.size_spread,
                'kernel': curve.kernel,
                'rg': curve.rg,
                'status': 'outdated' if outdated else 'done',
                'shown': curve.name not in self._hidden,
            })
            listed.append(curve)
        # Before the update: the chart reads the points of the rows it
        # announces
        self._listed = listed
        self._curves.update(rows)
        self.rangesChanged.emit()

    def _curve(self):
        """
        Return the curve to calculate from the picked structure.

        It is the one with these settings, to run again, or a new one,
        not in the list yet. A new one is named after the model, the
        stage, the SLD, the deuterated components and the size spread,
        with -2, -3 when a curve with other settings holds the name.
        """
        source = self._sources[self._selected_structure]
        settings = self._settings
        curves = self._session.analysis.sans
        for curve in curves:
            same = all(getattr(curve, key) == value for key, value in settings.items())
            if curve.source is source and same:
                return curve
        model = self._session.sample_model
        base = ''.join([
            model.name,
            '' if source is model else f'-{source.name}',
            f'-sld{settings["solvent_sld"]:g}',
            *(f'-d{name}' for name in settings['deuterated']),
            f'-pd{settings["size_spread"]:g}',
        ])
        taken = {curve.name for curve in curves}
        name, k = base, 2
        while name in taken:
            name, k = f'{base}-{k}', k + 1
        return SansCurve(source, name=name, **settings)

    def _start(self, curve):
        """
        Calculate a curve in the background, on the session's sample
        model, and watch the run.
        """
        curve.calculate(self._session.sample_model, background=True)
        self._running = curve
        self._watch.start()
        self.filesLockedChanged.emit()
        self.runningCurveChanged.emit()

    def _check(self):
        """
        Once the run has stopped: end the watch, keep a new curve that
        succeeded, drop one that failed or was cancelled, with its
        files, and report the error. A curve calculated again holds its
        new files, or keeps its old ones.
        """
        curve = self._running
        # The read takes an ended run's outputs in
        if curve.files_locked:
            return
        self._watch.stop()
        self._running = None
        error = curve.job.error
        sans = self._session.analysis.sans
        if curve not in sans:
            if error is None:
                sans.append(curve)
            else:
                AppFileManager().discard_asset_paths(curve, curve.paths)
        self.filesLockedChanged.emit()
        self.runningCurveChanged.emit()
        self._show_curves()
        # A cancel was the user's own: no dialog
        self.externalCalculated.emit('' if error in (None, 'Cancelled') else error)
