# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import re
import shutil

from PySide6.QtCore import Property
from PySide6.QtCore import QAbstractListModel
from PySide6.QtCore import QModelIndex
from PySide6.QtCore import QObject
from PySide6.QtCore import Qt
from PySide6.QtCore import QTimer
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project.files import AppFileManager

from .library_assets import FilesModel
from .library_assets import open_file
from .logic.analysis import LogReader
from .logic.analysis import stage_statuses
from .logic.files import export_taken
from .logic.session import Session

# Suffixes of the text files the pencil opens. Of the equilibration's
# own files only its log: its .itp, .gro and .top are copies each run
# makes again
STAGE_TEXT = frozenset({'.mdp', '.gro', '.log'})
EQUILIBRATION_TEXT = frozenset({'.log'})
# A stage that holds its files: the next stage may start from it
FINISHED = ('done', 'outdated')


class EntriesModel(QAbstractListModel):
    """
    Whose files the Equilibration Files group shows, and whose log
    Engine output shows, as rows of their pickers: the equilibration,
    then each stage run so far, each with a name and a status ('' for
    the equilibration).
    """

    NameRole = Qt.UserRole + 1
    StatusRole = Qt.UserRole + 2

    countChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rows = []

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        return {self.NameRole: b'name', self.StatusRole: b'status'}

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        name, status = self._rows[index.row()]
        match role:
            case self.NameRole:
                return name
            case self.StatusRole:
                return status
            case _:
                return None

    ############
    # QML access
    ############

    @Property(int, notify=countChanged)
    def count(self):
        return self.rowCount()

    @Slot(int, result='QVariant')
    def get(self, row):
        """
        A row's name and status.
        """
        name, status = self._rows[row]
        return {'name': name, 'status': status}

    #########
    # Changes
    #########

    def update(self, rows):
        """
        Show these (name, status) rows.
        """
        # A status change in place, so the picker keeps its state; a new
        # stage or another equilibration anew
        if len(rows) == len(self._rows):
            self._rows = rows
            if rows:
                self.dataChanged.emit(self.index(0), self.index(len(rows) - 1))
            return
        self.beginResetModel()
        self._rows = rows
        self.endResetModel()
        self.countChanged.emit()


class EquilibrationFilesModel(FilesModel):
    """
    The files of the equilibration or of one stage: a path, a size, and
    whether the pencil opens the file.
    """

    EditableRole = Qt.UserRole + 3

    def __init__(self, parent=None):
        super().__init__(parent)
        # Suffixes of the files the pencil opens
        self._text = frozenset()

    def roleNames(self):
        return {**super().roleNames(), self.EditableRole: b'editable'}

    def data(self, index, role=Qt.DisplayRole):
        if role == self.EditableRole and index.isValid():
            return self.paths[index.row()].suffix in self._text
        return super().data(index, role)

    def show(self, paths, text):
        """
        Replace every row with these files, the pencil opening those
        with a suffix in text.
        """
        self._text = text
        self.reset(paths)


class Equilibration(QObject):
    """
    The session's equilibration for QML: its setup, the files of the
    equilibration and of each stage run so far, and a log: the run's, or
    a finished stage's mdrun log.

    Stage k runs the configuration's equil<k>.mdp. Fields read their
    defaults and the lists are empty while the session holds no
    analysis. Export asks first when it would replace something: the
    page checks exportTaken.

    Equilibrate runs in the background, watched as Assemble is. A
    replacement of the project waits for it: it cancels the run as soon
    as Cancel may, then replaces.
    """

    firstStageChanged = Signal()
    lastStageChanged = Signal()
    threadsChanged = Signal()
    restrainToBoxCenterChanged = Signal()
    # The configuration's stages, or those a run can start from, may
    # have changed
    stagesChanged = Signal()
    selectedEntryChanged = Signal()
    selectedLogChanged = Signal()
    filesLockedChanged = Signal()
    cancelableChanged = Signal()
    stageChanged = Signal()
    logChanged = Signal()

    # A run ended, with its error ('' after success or a cancel): the
    # root shows the error
    externalEquilibrated = Signal(str)

    # Cancel waits this long after Equilibrate, ms, as for Assemble.
    # Tests shorten it
    _cancel_delay = 3000
    # How often a running equilibration is checked, ms
    _watch_interval = 500

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        self._entries = EntriesModel(self)
        self._files = EquilibrationFilesModel(self)
        # Row of entries whose files show: 0 is the equilibration
        self._selected_entry = 0
        # Row of entries whose log shows: 0 is the run's
        self._selected_log = 0
        # The statuses the entries show, None to read them anew
        self._shown_statuses = None
        # The stage a run is on, -1 without a run
        self._stage = -1
        self._log = ''
        # Reads the picked log; None without one
        self._reader = None
        self._cancelable = False
        # A replacement of the project, waiting for the run to stop
        self._pending = None
        # Reads files_locked while a run goes on
        self._watch = QTimer(self)
        self._watch.setInterval(self._watch_interval)
        self._watch.timeout.connect(self._check)
        # Lets Cancel in, a while after Equilibrate
        self._delay = QTimer(self)
        self._delay.setSingleShot(True)
        self._delay.setInterval(self._cancel_delay)
        self._delay.timeout.connect(self._allow_cancel)

    ##########################
    # GUI accessible variables
    ##########################

    @Property(int, notify=firstStageChanged)
    def firstStage(self):
        equilibration = self._equilibration()
        return equilibration.first_stage if equilibration else 0

    @firstStage.setter
    def firstStage(self, value):
        equilibration = self._equilibration()
        if equilibration is None or equilibration.first_stage == value:
            return
        equilibration.first_stage = value
        self.firstStageChanged.emit()
        # The last stage is never before the first
        if self.lastStage < value:
            self.lastStage = value

    @Property(int, notify=lastStageChanged)
    def lastStage(self):
        equilibration = self._equilibration()
        if equilibration is None:
            return 0
        if equilibration.last_stage is not None:
            return equilibration.last_stage
        # None runs to the configuration's last stage
        return max(self.availableStages, default=0)

    @lastStage.setter
    def lastStage(self, value):
        equilibration = self._equilibration()
        if equilibration is None or self.lastStage == value:
            return
        equilibration.last_stage = value
        self.lastStageChanged.emit()

    @Property(str, notify=threadsChanged)
    def threads(self):
        equilibration = self._equilibration()
        if equilibration is None or equilibration.threads is None:
            return ''
        return str(equilibration.threads)

    @threads.setter
    def threads(self, value):
        equilibration = self._equilibration()
        if equilibration is None or self.threads == value:
            return
        # Empty is Auto: mdrun picks
        equilibration.threads = int(value) if value else None
        self.threadsChanged.emit()

    @Property(bool, notify=restrainToBoxCenterChanged)
    def restrainToBoxCenter(self):
        equilibration = self._equilibration()
        return equilibration.restrain_to_box_center if equilibration else False

    @restrainToBoxCenter.setter
    def restrainToBoxCenter(self, value):
        equilibration = self._equilibration()
        if equilibration is None or equilibration.restrain_to_box_center == value:
            return
        equilibration.restrain_to_box_center = value
        self.restrainToBoxCenterChanged.emit()

    @Property('QVariant', notify=stagesChanged)
    def availableStages(self):
        """
        The stages the configuration holds an equil<k>.mdp for, in
        order.
        """
        equilibration = self._equilibration()
        if equilibration is None:
            return []
        # As the library finds them: equil<k>.mdp runs as stage k
        return sorted(
            int(match.group(1))
            for path in equilibration.configuration.paths
            if (match := re.fullmatch(r'equil(\d+)\.mdp', path.name))
        )

    @Property('QVariant', notify=stagesChanged)
    def startableStages(self):
        """
        The stages a run can start from: eq0, and each stage after a
        finished one, that the configuration holds.
        """
        after = [k + 1 for k, status in enumerate(self._statuses()) if status in FINISHED]
        return [k for k in [0, *after] if k in self.availableStages]

    @Property('QVariant', constant=True)
    def entries(self):
        return self._entries

    @Property(int, notify=selectedEntryChanged)
    def selectedEntry(self):
        return self._selected_entry

    @Property('QVariant', constant=True)
    def files(self):
        return self._files

    @Property(bool, notify=filesLockedChanged)
    def filesLocked(self):
        # True until the check takes the ended run in
        return self._watch.isActive()

    @Property(bool, notify=cancelableChanged)
    def cancelable(self):
        return self._cancelable

    @Property(int, notify=stageChanged)
    def stage(self):
        return self._stage

    @Property(int, notify=selectedLogChanged)
    def selectedLog(self):
        return self._selected_log

    @Property(str, notify=logChanged)
    def log(self):
        """
        The picked log as a terminal shows it; '' for a stage running or
        not run.
        """
        return self._log

    ##########################
    # GUI accessible functions
    ##########################

    @Slot()
    def run(self):
        """
        Run the stages from the first to the last in the background. A
        check that fails before the start raises, for the error dialog.
        """
        self._equilibration().run(self._session.sample_model, background=True)
        self._watch.start()
        self._delay.start()
        self.filesLockedChanged.emit()
        # The run emptied its log and writes it anew: shown from its
        # start
        self.selectLog(0)
        # The run's stages and the one it is on show at once
        self._check()

    @Slot()
    def cancel(self):
        """
        Stop the running equilibration; it ends at once, and the stages
        it finished keep their files.
        """
        self._equilibration().job.cancel()
        self._check()

    @Slot(int)
    def selectEntry(self, index):
        """
        Show the files of the entry in a row: 0 for the equilibration, k
        + 1 for stage k.
        """
        self._selected_entry = index
        self._show_files()
        self.selectedEntryChanged.emit()

    @Slot(int)
    def selectLog(self, index):
        """
        Show the log of the entry in a row: 0 for the run's, which grows
        while a run goes on; k + 1 for stage k's mdrun log, once the
        stage has finished.
        """
        self._selected_log = index
        self._open_log()
        self.selectedLogChanged.emit()

    @Slot(int)
    def editFile(self, row):
        """
        Open the file in a row in the system's default app for its type.
        """
        open_file(self._files.paths[row])

    @Slot(str, int, result=bool)
    def exportTaken(self, folder, row):
        """
        Whether an export to a folder would replace files: the row's
        namesake, or for the whole entry (row -1) anything there.
        """
        return export_taken(folder, self._files.paths[row] if row >= 0 else None)

    @Slot(str, int, bool)
    def exportTo(self, folder, row, overwrite):
        """
        Copy a row's file into a folder, or export the whole entry (row
        -1) there, the equilibration with its nested assets; overwrite
        replaces an earlier export.
        """
        if row >= 0:
            # One file, copied as it is; the page has asked before
            # replacing its namesake
            shutil.copy(self._files.paths[row], folder)
        else:
            self._picked(self._selected_entry).export_to(folder, overwrite=overwrite)

    @Slot()
    def openFolder(self):
        """
        Open the folder of the picked entry in the system file browser.
        """
        open_file(AppFileManager().locate_asset_dir(self._picked(self._selected_entry)))

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Read everything again: the session holds another analysis, or
        the configuration's files changed.
        """
        # _show_stages emits stagesChanged and reads the picked log: no
        # statuses are shown now
        self._shown_statuses = None
        self._show_stages()
        self.firstStageChanged.emit()
        self.lastStageChanged.emit()
        self.threadsChanged.emit()
        self.restrainToBoxCenterChanged.emit()
        self.selectedEntryChanged.emit()
        self.selectedLogChanged.emit()

    def after_equilibration(self, then):
        """
        Call then once no run goes on: at once, or after cancelling the
        running one as soon as Cancel may.
        """
        if not self._watch.isActive():
            then()
            return
        # A later request replaces an earlier one
        self._pending = then
        if self._cancelable:
            self.cancel()

    def _allow_cancel(self):
        self._cancelable = True
        self.cancelableChanged.emit()
        if self._pending:
            self.cancel()

    def _check(self):
        """
        Show what the run has done; once it has stopped, end the watch,
        report its error, and run what waited.
        """
        equilibration = self._equilibration()
        # The read registers the stages finished since, and takes an
        # ended run in
        locked = equilibration.files_locked
        self._show_log()
        self._show_stages()
        if locked:
            return
        self._watch.stop()
        self._delay.stop()
        self._cancelable = False
        then, self._pending = self._pending, None
        self.filesLockedChanged.emit()
        self.cancelableChanged.emit()
        error = equilibration.job.error
        # A cancel was the user's own: no dialog
        self.externalEquilibrated.emit('' if error in (None, 'Cancelled') else error)
        if then:
            then()

    def _show_log(self):
        log = self._reader.read() if self._reader else ''
        if log != self._log:
            self._log = log
            self.logChanged.emit()

    def _show_stages(self):
        equilibration = self._equilibration()
        running = equilibration.stage if equilibration else None
        stage = -1 if running is None else running
        if stage != self._stage:
            self._stage = stage
            self.stageChanged.emit()
        statuses = self._statuses()
        if statuses == self._shown_statuses:
            return
        self._shown_statuses = statuses
        stages = equilibration.stages if equilibration else ()
        self._entries.update([
            ('Equilibration', ''),
            *((stage.name, status) for stage, status in zip(stages, statuses, strict=True)),
        ])
        if self._selected_entry >= self._entries.rowCount():
            self._selected_entry = 0
            self.selectedEntryChanged.emit()
        if self._selected_log >= self._entries.rowCount():
            self._selected_log = 0
            self.selectedLogChanged.emit()
        # A finished stage now holds its files and its log; a run's
        # start brings the equilibration its copies
        self._show_files()
        self._open_log()
        self.stagesChanged.emit()

    def _equilibration(self):
        analysis = self._session.analysis
        return analysis.equilibration if analysis else None

    def _statuses(self):
        equilibration = self._equilibration()
        if equilibration is None:
            return []
        return stage_statuses([stage.paths for stage in equilibration.stages], equilibration.stage)

    def _picked(self, row):
        """
        The equilibration (row 0) or stage row - 1 of entries; None
        without analysis.
        """
        equilibration = self._equilibration()
        if equilibration is None or row == 0:
            return equilibration
        return equilibration.stages[row - 1]

    def _show_files(self):
        picked = self._picked(self._selected_entry)
        text = EQUILIBRATION_TEXT if self._selected_entry == 0 else STAGE_TEXT
        self._files.show(picked.paths if picked else (), text)

    def _open_log(self):
        """
        Read the picked log from its start: the run's equilibration.log,
        or a finished stage's mdrun log. A stage running or not run
        shows none: it holds an earlier run's files, or none.
        """
        k = self._selected_log - 1
        statuses = self._shown_statuses or []
        finished = k < 0 or (k < len(statuses) and statuses[k] in FINISHED)
        picked = self._picked(self._selected_log) if finished else None
        # The run's log by its name; a stage holds one .log, mdrun's.
        # ponytail: a stage's whole log goes to the text area; if a long
        # run's MBs lag, show its tail
        log = next(
            (
                path
                for path in (picked.paths if picked else ())
                if (path.name == 'equilibration.log' if k < 0 else path.suffix == '.log')
            ),
            None,
        )
        self._reader = LogReader(log) if log else None
        self._show_log()
