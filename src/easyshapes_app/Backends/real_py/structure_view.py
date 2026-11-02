# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import threading

import numpy as np
from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot

from .logic.gro import molecule_bonds
from .logic.gro import read_gro_atoms
from .logic.itp import read_bonds
from .logic.session import Session
from .structure_instancing import StructureInstancing


class StructureView(QObject):
    """
    The structure viewer's atoms: the sample model's .gro, read in a
    background thread while the Structure tab is shown.

    A file is read again when its path or modification time changed, or
    after the tab was hidden with keepLoaded off: hiding then drops the
    atoms and sets the slab back to its starting width. An error of the
    reading thread can't reach the error dialog, which catches calls
    from QML only: it goes to error, for the tab to show.

    With showBonds, the bonds of the components' topology files are read
    with the file: ticking or unticking it reads the file again.
    """

    hasStructureChanged = Signal()
    keepLoadedChanged = Signal()
    showBondsChanged = Signal()
    loadingChanged = Signal()
    errorChanged = Signal()
    # From the reading thread back to the GUI thread: the file's key,
    # names, positions, bonds (None without), and the error ('' when
    # read)
    _read = Signal(object, object, object, object, str)

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        # No parent: a Quick 3D object takes only a Quick 3D parent;
        # this reference keeps it alive
        self._instancing = StructureInstancing()
        self._active = False
        self._keep = False
        self._show_bonds = False
        self._loading = False
        self._error = ''
        # (path, modification time) of the file shown; None: none
        self._shown = None
        self._read.connect(self._on_read)

    @Property('QVariant', constant=True)
    def instancing(self):
        return self._instancing

    @Property(bool, notify=hasStructureChanged)
    def hasStructure(self):
        """
        Whether the sample model holds a .gro to show.
        """
        return self._key() is not None

    @Property(bool, notify=keepLoadedChanged)
    def keepLoaded(self):
        """
        Whether the atoms stay loaded while the tab is hidden.
        """
        return self._keep

    @keepLoaded.setter
    def keepLoaded(self, value):
        if self._keep == value:
            return
        self._keep = value
        self.keepLoadedChanged.emit()
        if not (self._active or value):
            self._shown = None
            self._instancing.clear()

    @Property(bool, notify=showBondsChanged)
    def showBonds(self):
        """
        Whether the bonds are read and drawn.
        """
        return self._show_bonds

    @showBonds.setter
    def showBonds(self, value):
        if self._show_bonds != value:
            self._show_bonds = value
            self.showBondsChanged.emit()
            # Part of the key: a shown tab reads the file again
            self._load()

    @Property(bool, notify=loadingChanged)
    def loading(self):
        return self._loading

    @Property(str, notify=errorChanged)
    def error(self):
        return self._error

    @Slot(bool)
    def setActive(self, active):
        """
        Whether the Structure tab is shown; atoms are read only then,
        and dropped on hiding unless kept.
        """
        self._active = active
        if not (active or self._keep):
            self._shown = None
            self._instancing.clear()
        self._load()

    def refresh(self):
        """
        Show the .gro of a new sample model or structure, if the tab is
        shown.
        """
        self.hasStructureChanged.emit()
        self._load()

    def _key(self):
        """
        The sample model's .gro, its modification time and whether the
        bonds are shown, or None.
        """
        model = self._session.sample_model
        paths = model.paths if model else ()
        path = next((path for path in paths if path.suffix == '.gro'), None)
        return (path, path.stat().st_mtime_ns, self._show_bonds) if path else None

    def _load(self):
        """
        Read the sample model's .gro in a background thread, unless the
        tab is hidden, a read runs, or the file is shown already.
        """
        key = self._key()
        if not self._active or self._loading or key == self._shown:
            return
        if key is None:
            self._show(None, np.zeros(0, 'S5'), np.zeros((0, 3), np.float32), None, '')
            return
        self._set_loading(True)
        # Taken here: the reading thread touches no library object
        topologies = {
            component.name: component.topology_file_path
            for component in self._session.components
            if key[2] and component.topology_file_path
        }
        threading.Thread(target=self._read_file, args=(key, topologies), daemon=True).start()

    def _read_file(self, key, topologies):
        # In the reading thread: no Qt object is touched, only the
        # signal, which Qt delivers in the GUI thread
        try:
            names, xyz, residues = read_gro_atoms(key[0])
            bonds = (
                molecule_bonds(
                    residues, {name: read_bonds(path, name) for name, path in topologies.items()}
                )
                if topologies
                else None
            )
            self._read.emit(key, names, xyz, bonds, '')
        # IndexError: a bond line of one field
        except (OSError, ValueError, IndexError) as err:
            self._read.emit(key, None, None, None, str(err))

    def _on_read(self, key, names, xyz, bonds, error):
        self._set_loading(False)
        # Hidden while read, and not kept: dropped unshown
        if self._active or self._keep:
            self._show(key, names, xyz, bonds, error)
        # The model may have moved on while the file was read
        self._load()

    def _show(self, key, names, xyz, bonds, error):
        """
        Show a file's atoms and bonds, or keep the shown ones and say
        why not.
        """
        self._shown = key
        if not error:
            self._instancing.set_atoms(names, xyz, bonds)
        if self._error != error:
            self._error = error
            self.errorChanged.emit()

    def _set_loading(self, value):
        if self._loading != value:
            self._loading = value
            self.loadingChanged.emit()
