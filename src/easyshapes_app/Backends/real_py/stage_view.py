# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot

from .equilibration import FINISHED
from .equilibration import EntriesModel
from .logic.analysis import stage_statuses
from .logic.session import Session
from .structure_view import StructureView


class StageView(StructureView):
    """
    The Analysis page's structure viewer: the equilibration's initial
    structure, its copy of the model that stage 0 starts from, or a
    finished stage's final .gro, read as the Structure viewer reads the
    sample model's.

    The picker lists Initial, once the equilibration holds its copy, and
    the finished stages. Until a row is picked by hand, the newest
    shows. A pick stays by name; while it is missing from the list, as
    when its stage runs again, the newest shows.
    """

    selectedStageChanged = Signal()

    def __init__(self, session: Session, parent=None):
        super().__init__(session, parent)
        self._stages = EntriesModel(self)
        # Each row's file, in the order of stages
        self._files = []
        # Row of stages shown; -1 with none
        self._selected_stage = -1
        # The row picked by hand, by name; '' until one is
        self._picked = ''

    @Property('QVariant', constant=True)
    def stages(self):
        return self._stages

    @Property(int, notify=selectedStageChanged)
    def selectedStage(self):
        return self._selected_stage

    @Slot(int)
    def selectStage(self, index):
        """
        Show the row picked: it stays while it is listed.
        """
        self._picked = self._stages.get(index)['name']
        self._select(index)

    def refresh(self):
        """
        List the rows again, after another analysis, a run's start or a
        finished stage, and show the pick while it is listed, else the
        newest row.
        """
        rows, self._files = self._rows()
        self._stages.update(rows)
        names = [name for name, _ in rows]
        self._select(names.index(self._picked) if self._picked in names else len(rows) - 1)

    def _gro(self):
        return self._files[self._selected_stage] if self._selected_stage >= 0 else None

    def _select(self, index):
        self._selected_stage = index
        self.selectedStageChanged.emit()
        # Shows the row's file, if the tab is shown
        super().refresh()

    def _rows(self):
        """
        The rows, (name, status), and each row's file: Initial when the
        equilibration's own files hold a .gro, then each finished stage
        with its final -eq<k>.gro.
        """
        analysis = self._session.analysis
        equilibration = analysis.equilibration if analysis else None
        if equilibration is None:
            return [], []
        rows = []
        files = []
        # Its copy of the model, which stage 0 starts from: the one .gro
        # among the equilibration's own files
        initial = next((path for path in equilibration.paths if path.suffix == '.gro'), None)
        if initial:
            rows.append(('Initial', ''))
            files.append(initial)
        stages = equilibration.stages
        statuses = stage_statuses([stage.paths for stage in stages], equilibration.stage)
        # A stage running again is left out: its file is about to be
        # replaced
        for k, (stage, status) in enumerate(zip(stages, statuses, strict=True)):
            if status in FINISHED:
                rows.append((stage.name, status))
                files.append(
                    next(path for path in stage.paths if path.name.endswith(f'-eq{k}.gro'))
                )
        return rows, files
