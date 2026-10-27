# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import QUrl
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from PySide6.QtGui import QDesktopServices
from shapes.project import Ball
from shapes.project import Bilayer
from shapes.project import Lattice
from shapes.project import Library
from shapes.project import Monolayer
from shapes.project import Ring
from shapes.project import Rod
from shapes.project import SampleModel as SampleModelLib
from shapes.project import Vesicle

from .library_assets import FilesModel
from .logic.files import export_taken
from .logic.session import Session

# GUI name of each shape, in the order the shape list shows them
SHAPES = {
    'Ring': Ring,
    'Ball': Ball,
    'Vesicle': Vesicle,
    'Rod': Rod,
    'Bilayer': Bilayer,
    'Monolayer': Monolayer,
}


class SampleModel(QObject):
    """
    The session's sample model for QML: its name, the shape of its
    structure, whether a lattice repeats it, and its own files.

    Fields read '' or False while there is no sample model. Continue on
    the Project page creates one; a project create or load brings its
    own, and Load model or Import model replaces it. Save to lib and
    Export ask first when they would replace something: the page checks
    nameTaken or exportTaken.
    """

    nameChanged = Signal()
    shapeChanged = Signal()
    latticeChanged = Signal()

    # The structure was replaced: the root builds new structure adapters
    # and refreshes the components list
    externalStructureChanged = Signal()
    # A save changed what the library holds: the root makes the
    # catalogs read it again
    externalAssetsChanged = Signal()

    # The library classes create builds and a name is checked in;
    # tests swap in fakes
    _sample_model_class = SampleModelLib
    _library_class = Library

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        self._files = FilesModel(self)

    ##########################
    # GUI accessible variables
    ##########################

    @Property(str, notify=nameChanged)
    def name(self):
        sample_model = self._session.sample_model
        return sample_model.name if sample_model else ''

    @name.setter
    def name(self, value):
        sample_model = self._session.sample_model
        if sample_model is None or sample_model.name == value:
            return
        sample_model.name = value
        # A rename moves the files in the model's working folder
        self._files.reset(sample_model.paths)
        self.nameChanged.emit()

    @Property('QVariant', constant=True)
    def shapes(self):
        return list(SHAPES)

    @Property(str, notify=shapeChanged)
    def shape(self):
        sample_model = self._session.sample_model
        if sample_model is None:
            return ''
        # The lattice's unit, or the structure itself
        current = sample_model.structure
        unit = current.unit if isinstance(current, Lattice) else current
        return next(name for name, cls in SHAPES.items() if type(unit) is cls)

    @shape.setter
    def shape(self, value):
        sample_model = self._session.sample_model
        if sample_model is None or self.shape == value:
            return
        lattice = isinstance(sample_model.structure, Lattice)
        old = sample_model.structure.unit if lattice else sample_model.structure
        # The old compositions stop following the components
        if isinstance(old, Ball):
            for layer in old.layers:
                layer.composition.detach()
        elif isinstance(old, Vesicle):
            for lamella in old.lamellae:
                lamella.inner_leaflet_composition.detach()
                # Symmetric leaflets share one composition: detach once
                if not lamella.symmetric:
                    lamella.outer_leaflet_composition.detach()
        else:
            old.composition.detach()
        new = SHAPES[value](components=old.components)
        if lattice:
            sample_model.structure.unit = new
        else:
            sample_model.structure = new
        self.shapeChanged.emit()
        self.externalStructureChanged.emit()

    @Property(bool, notify=latticeChanged)
    def lattice(self):
        sample_model = self._session.sample_model
        return isinstance(sample_model.structure, Lattice) if sample_model else False

    @lattice.setter
    def lattice(self, value):
        sample_model = self._session.sample_model
        if sample_model is None or self.lattice == value:
            return
        structure = sample_model.structure
        # Unwrapping drops the lattice settings
        sample_model.structure = Lattice(unit=structure) if value else structure.unit
        self.latticeChanged.emit()
        self.externalStructureChanged.emit()

    @Property('QVariant', constant=True)
    def files(self):
        return self._files

    ##########################
    # GUI accessible functions
    ##########################

    @Slot()
    def create(self):
        """
        Give the session a new sample model, unless it has one.
        """
        if self._session.sample_model is not None:
            return
        self._replace(self._sample_model_class())

    @Slot(str)
    def load(self, name):
        """
        Replace the sample model with the library's model of that name.
        """
        self._replace(self._sample_model_class.load(name))

    @Slot(str)
    def importFrom(self, folder):
        """
        Replace the sample model with the one an export folder holds.
        """
        self._replace(self._sample_model_class.import_from(folder))

    @Slot(str)
    def appendFile(self, path):
        """
        Add a file to the sample model.
        """
        sample_model = self._session.sample_model
        sample_model.add_new_files([path])
        self._files.reset(sample_model.paths)

    @Slot(int)
    def removeFile(self, row):
        """
        Remove the file in a row from the sample model.
        """
        sample_model = self._session.sample_model
        sample_model.remove_files([self._files.paths[row]])
        self._files.reset(sample_model.paths)

    @Slot(int)
    def editFile(self, row):
        """
        Open the file in a row in the system's default app for its type.
        """
        # Opened where it lies, as in Components Files
        path = self._files.paths[row]
        if not QDesktopServices.openUrl(QUrl.fromLocalFile(str(path))):
            raise RuntimeError(f'No app on this system opens {path}')

    @Slot(result=bool)
    def nameTaken(self):
        """
        Whether the library holds a sample model of this name.
        """
        sample_model = self._session.sample_model
        return self._library_class().has_entry(type(sample_model).__name__, sample_model.name)

    @Slot(bool)
    def save(self, overwrite):
        """
        Save the sample model, with its nested assets, to the library;
        overwrite replaces an entry of the same name.
        """
        self._session.sample_model.save(overwrite=overwrite)
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
        Export the sample model, with its nested assets, to a folder;
        overwrite replaces an earlier export.
        """
        self._session.sample_model.export_to(folder, overwrite=overwrite)

    #########
    # Helpers
    #########

    def refresh(self):
        """
        Tell QML that the session holds another sample model, and show
        its files.
        """
        sample_model = self._session.sample_model
        self._files.reset(sample_model.paths if sample_model else ())
        self.nameChanged.emit()
        self.shapeChanged.emit()
        self.latticeChanged.emit()
        self.externalStructureChanged.emit()

    def _replace(self, sample_model):
        # The analysis and the project save the model they hold: all
        # three must hold the same one
        self._session.sample_model = sample_model
        if self._session.analysis is not None:
            self._session.analysis.sample_model = sample_model
        if self._session.project is not None:
            self._session.project.sample_model = sample_model
        self.refresh()
