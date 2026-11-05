# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import codecs
from pathlib import Path

from shapes.project.analysis import AnalysisConfiguration

# The library's configuration an analysis gets when it holds none
DEFAULT_CONFIGURATION = 'CHARMM36'


def fill_configuration(analysis):
    """
    Give an analysis whose configuration holds no files the library's
    CHARMM36: Equilibration() starts with an empty one, which run()
    refuses. A configuration that holds files stays.
    """
    equilibration = analysis.equilibration
    if not equilibration.configuration.paths:
        equilibration.configuration = AnalysisConfiguration.load(DEFAULT_CONFIGURATION)


def stage_statuses(stage_paths, running=None):
    """
    Each stage's status, from the files it holds: 'running' for the
    stage a run is on, 'done' once it holds its final .gro, 'outdated'
    when done but its stage before finished after it or is outdated
    itself (it started from older files), else 'not run'.

    stage_paths holds each stage's files, stage k's final .gro ending in
    -eq<k>.gro; running is the index of the stage a run is on.
    """
    statuses = []
    # The stage before: its final .gro's time, None without one, and
    # whether it is outdated
    before = None
    stale = False
    for k, paths in enumerate(stage_paths):
        final = next((path for path in paths if path.name.endswith(f'-eq{k}.gro')), None)
        time = final.stat().st_mtime if final else None
        stale = time is not None and (stale or (before is not None and before > time))
        if k == running:
            statuses.append('running')
        elif time is None:
            statuses.append('not run')
        else:
            statuses.append('outdated' if stale else 'done')
        before = time
    return statuses


class LogReader:
    """
    A growing log as a terminal shows it. Each read takes in only the
    bytes added since the last one, and a line keeps only its text after
    its last carriage return: mdrun -v rewrites its progress line that
    way, which then updates in place. The line still being written shows
    too. The file on disk stays as it is.
    """

    def __init__(self, path):
        self._path = Path(path)
        self._offset = 0
        # Keeps a character split between two reads whole
        self._decoder = codecs.getincrementaldecoder('utf-8')(errors='replace')
        # Finished lines, as shown, and the line still being written
        self._done = []
        self._tail = ''

    def read(self):
        """
        The log as shown now, with what was added since the last read. A
        file not written yet reads as empty.
        """
        try:
            with self._path.open('rb') as stream:
                stream.seek(self._offset)
                data = stream.read()
        except FileNotFoundError:
            data = b''
        self._offset += len(data)
        lines = (self._tail + self._decoder.decode(data)).split('\n')
        self._tail = lines.pop()
        self._done.extend(_shown(line) for line in lines)
        return '\n'.join([*self._done, _shown(self._tail)])


def _shown(line):
    # A trailing \r ends a Windows line; any other starts the line anew
    return line.removesuffix('\r').rsplit('\r', 1)[-1]
