# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

import shutil

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import QUrl
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from PySide6.QtGui import QDesktopServices
from shapes.project import Component
from shapes.project import Lattice
from shapes.project import Library

from .library_assets import FilesModel
from .logic.files import export_taken
from .logic.session import Session


class ComponentsFiles(QObject):
    """
    The Components Files group for QML: the files of one component of
    the sample, the live object, picked from the components list.

    Create new clears the group, and create(name) makes an empty
    Component that the root adds to the sample. Files change on the
    component itself. Save to lib and Export ask first when they would
    replace something: the page checks nameTaken or exportTaken.
    """

    selectedComponentChanged = Signal()
    # A component Create new made, for the root to add to the sample
    # through the components list, which opens its row
    externalComponentCreated = Signal(object)
    # A save changed what the library holds: the root makes the
    # catalogs read it again
    externalAssetsChanged = Signal()

    # The class Create new makes, and the library a name is checked in;
    # tests swap in fakes
    _component_class = Component
    _library_class = Library

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        # The live component of the sample the group shows; None while
        # none is picked, or after Create new until a name is given
        self._component = None
        self._files = FilesModel(self)

    @Property(str, notify=selectedComponentChanged)
    def selectedComponent(self):
        """
        The picked component's name, '' for none.
        """
        return self._component.name if self._component else ''

    @Property('QVariant', constant=True)
    def files(self):
        return self._files

    @Slot(str)
    def selectComponent(self, name):
        """
        Pick the sample's component of that name.
        """
        self._select(self._components()[name])

    @Slot()
    def createNew(self):
        """
        Clear the pick, for a new component's name.
        """
        self._select(None)

    @Slot(str)
    def appendFile(self, path):
        """
        Add a file to the picked component.
        """
        self._component.add_new_files([path])
        self._files.reset(self._component.paths)

    @Slot(int)
    def removeFile(self, row):
        """
        Remove the file in a row from the picked component.
        """
        self._component.remove_files([self._files.paths[row]])
        self._files.reset(self._component.paths)

    @Slot(int)
    def editFile(self, row):
        """
        Open the file in a row in the system's default app for its type.
        """
        # Opened where it lies, as in Library assets
        path = self._files.paths[row]
        if not QDesktopServices.openUrl(QUrl.fromLocalFile(str(path))):
            raise RuntimeError(f'No app on this system opens {path}')

    @Slot(str)
    def create(self, name):
        """
        Make an empty component of that name, hand it to the root for
        the sample, and pick it.
        """
        # Refused here: the components list would refuse it only inside
        # the root's slot, where the error can't stop this method
        if name in self._components():
            raise ValueError(f'The structure already holds {name}')
        component = self._component_class(name=name)
        self.externalComponentCreated.emit(component)
        self._select(component)

    @Slot(result=bool)
    def nameTaken(self):
        """
        Whether the library holds an entry of the picked component's
        class and name.
        """
        return self._library_class().has_entry(
            type(self._component).__name__, self._component.name
        )

    @Slot(bool)
    def save(self, overwrite):
        """
        Save the picked component to the library; overwrite replaces an
        entry of the same name.
        """
        self._component.save(overwrite=overwrite)
        self.externalAssetsChanged.emit()

    @Slot(str, int, result=bool)
    def exportTaken(self, folder, row):
        """
        Whether an export to a folder would replace files: the row's
        namesake, or for the whole component (row -1) anything there.
        """
        return export_taken(folder, self._files.paths[row] if row >= 0 else None)

    @Slot(str, int, bool)
    def exportTo(self, folder, row, overwrite):
        """
        Copy a row's file into a folder, or export the whole component
        (row -1) there; overwrite replaces an earlier export.
        """
        if row >= 0:
            # One file, copied as it is; the page has asked before
            # replacing its namesake
            shutil.copy(self._files.paths[row], folder)
        else:
            self._component.export_to(folder, overwrite=overwrite)

    def refresh(self):
        """
        Follow the components list: keep a renamed pick, drop a removed
        one.
        """
        # The pick stays while the structure holds it, and a rename
        # shows its new name; a removal or a new sample model drops it
        if self._component is not None and not any(
            component is self._component for component in self._components()
        ):
            self._select(None)
        else:
            self.selectedComponentChanged.emit()

    def _select(self, component):
        self._component = component
        self._files.reset(component.paths if component else ())
        self.selectedComponentChanged.emit()

    def _components(self):
        sample_model = self._session.sample_model
        if sample_model is None:
            return ()
        current = sample_model.structure
        return (current.unit if isinstance(current, Lattice) else current).components
