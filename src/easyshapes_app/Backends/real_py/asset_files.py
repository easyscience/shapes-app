# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project import Library

from .library_assets import FilesModel
from .library_assets import open_file
from .logic.files import export_taken
from .logic.session import Session


class AssetFiles(QObject):
    """
    One library asset of the session's equilibration for QML: its
    configuration (.mdp files) or its force field (.itp). The root
    builds one of each.

    Its name, its files, a load from the library, and Save to lib and
    Export, as the Sample Model Files group. Fields read '' and the
    files list is empty while the session holds no analysis. Save to lib
    and Export ask first when they would replace something: the page
    checks nameTaken or exportTaken.
    """

    nameChanged = Signal()

    # A save changed what the library holds: the root makes the
    # catalogs read it again
    externalAssetsChanged = Signal()

    # Where a name is checked; tests swap in a fake
    _library_class = Library

    def __init__(self, session: Session, attribute, asset_class, parent=None):
        super().__init__(parent)
        self._session = session
        # The equilibration's attribute that holds the asset, and the
        # asset's library class, which load reads
        self._attribute = attribute
        self._asset_class = asset_class
        self._files = FilesModel(self)

    ##########################
    # GUI accessible variables
    ##########################

    @Property(str, notify=nameChanged)
    def name(self):
        asset = self._asset()
        return asset.name if asset else ''

    @name.setter
    def name(self, value):
        asset = self._asset()
        if asset is None or asset.name == value:
            return
        asset.name = value
        # A rename moves the files in the asset's working folder
        self._files.reset(asset.paths)
        self.nameChanged.emit()

    @Property('QVariant', constant=True)
    def files(self):
        return self._files

    ##########################
    # GUI accessible functions
    ##########################

    @Slot(str)
    def load(self, name):
        """
        Replace the equilibration's asset with the library's of that
        name.
        """
        setattr(
            self._session.analysis.equilibration, self._attribute, self._asset_class.load(name)
        )
        self.refresh()

    @Slot(str)
    def appendFile(self, path):
        """
        Add a file to the asset.
        """
        asset = self._asset()
        asset.add_new_files([path])
        self._files.reset(asset.paths)

    @Slot(int)
    def removeFile(self, row):
        """
        Remove the file in a row from the asset.
        """
        asset = self._asset()
        asset.remove_files([self._files.paths[row]])
        self._files.reset(asset.paths)

    @Slot(int)
    def editFile(self, row):
        """
        Open the file in a row in the system's default app for its type.
        """
        # Opened where it lies, as in Sample Model Files
        open_file(self._files.paths[row])

    @Slot(result=bool)
    def nameTaken(self):
        """
        Whether the library holds an asset of this class and name.
        """
        return self._library_class().has_entry(self._asset_class.__name__, self._asset().name)

    @Slot(bool)
    def save(self, overwrite):
        """
        Save the asset to the library; overwrite replaces an entry of
        the same name.
        """
        self._asset().save(overwrite=overwrite)
        self.externalAssetsChanged.emit()

    @Slot(str, result=bool)
    def exportTaken(self, folder):
        """
        Whether an export to a folder would replace files: anything
        there.
        """
        return export_taken(folder)

    @Slot(str, bool)
    def exportTo(self, folder, overwrite):
        """
        Export the asset to a folder; overwrite replaces an earlier
        export.
        """
        self._asset().export_to(folder, overwrite=overwrite)

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the session holds another analysis, and show its
        asset's files.
        """
        asset = self._asset()
        self._files.reset(asset.paths if asset else ())
        self.nameChanged.emit()

    def _asset(self):
        analysis = self._session.analysis
        return getattr(analysis.equilibration, self._attribute) if analysis else None
