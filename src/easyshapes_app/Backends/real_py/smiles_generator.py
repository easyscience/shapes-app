# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project import Component
from shapes.project import Lipid
from shapes.project import Surfactant

from .logic.session import Session


class SmilesGenerator(QObject):
    """
    The SMILES generator for QML: a draft of from_smiles arguments, and
    Generate, which builds a component of them for the root to add to
    the sample.

    The draft keeps plain fields; the component is built only on
    Generate. A name the sample holds shows in nameTaken but does not
    stop Generate: adding the component then refuses it, and so does a
    SMILES string the library can't build, in the error dialog.
    """

    nameChanged = Signal()
    formulaChanged = Signal()
    smilesChanged = Signal()
    boxXChanged = Signal()
    boxYChanged = Signal()
    boxZChanged = Signal()
    extensionChanged = Signal()
    componentTypeChanged = Signal()
    cisChanged = Signal()
    alignZChanged = Signal()
    flattenXzChanged = Signal()
    readyChanged = Signal()
    nameTakenChanged = Signal()
    # A component Generate built, for the root to add to the sample
    externalComponentCreated = Signal(object)

    # The classes a component is built as, by library class name; tests
    # swap in fakes
    _types = {cls.__name__: cls for cls in (Lipid, Surfactant, Component)}

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        self._name = ''
        self._formula = ''
        self._smiles = ''
        # Box lengths in nm
        self._box_x = 1.0
        self._box_y = 1.0
        self._box_z = 1.0
        self._extension = '.gro'
        self._component_type = 'Component'
        self._cis = False
        self._align_z = False
        self._flatten_xz = False
        # ready reads the name and the SMILES string; nameTaken the name
        self.nameChanged.connect(self.readyChanged)
        self.smilesChanged.connect(self.readyChanged)
        self.nameChanged.connect(self.nameTakenChanged)

    @Property(str, notify=nameChanged)
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        if self._name == value:
            return
        self._name = value
        self.nameChanged.emit()

    @Property(str, notify=formulaChanged)
    def formula(self):
        return self._formula

    @formula.setter
    def formula(self, value):
        if self._formula == value:
            return
        self._formula = value
        self.formulaChanged.emit()

    @Property(str, notify=smilesChanged)
    def smiles(self):
        return self._smiles

    @smiles.setter
    def smiles(self, value):
        if self._smiles == value:
            return
        self._smiles = value
        self.smilesChanged.emit()

    @Property(float, notify=boxXChanged)
    def boxX(self):
        return self._box_x

    @boxX.setter
    def boxX(self, value):
        if self._box_x == value:
            return
        self._box_x = value
        self.boxXChanged.emit()

    @Property(float, notify=boxYChanged)
    def boxY(self):
        return self._box_y

    @boxY.setter
    def boxY(self, value):
        if self._box_y == value:
            return
        self._box_y = value
        self.boxYChanged.emit()

    @Property(float, notify=boxZChanged)
    def boxZ(self):
        return self._box_z

    @boxZ.setter
    def boxZ(self, value):
        if self._box_z == value:
            return
        self._box_z = value
        self.boxZChanged.emit()

    @Property(str, notify=extensionChanged)
    def extension(self):
        return self._extension

    @extension.setter
    def extension(self, value):
        if self._extension == value:
            return
        self._extension = value
        self.extensionChanged.emit()

    @Property(str, notify=componentTypeChanged)
    def componentType(self):
        return self._component_type

    @componentType.setter
    def componentType(self, value):
        if self._component_type == value:
            return
        self._component_type = value
        self.componentTypeChanged.emit()

    @Property(bool, notify=cisChanged)
    def cis(self):
        return self._cis

    @cis.setter
    def cis(self, value):
        if self._cis == value:
            return
        self._cis = value
        self.cisChanged.emit()

    @Property(bool, notify=alignZChanged)
    def alignZ(self):
        return self._align_z

    @alignZ.setter
    def alignZ(self, value):
        if self._align_z == value:
            return
        self._align_z = value
        self.alignZChanged.emit()

    @Property(bool, notify=flattenXzChanged)
    def flattenXz(self):
        return self._flatten_xz

    @flattenXz.setter
    def flattenXz(self, value):
        if self._flatten_xz == value:
            return
        self._flatten_xz = value
        self.flattenXzChanged.emit()

    @Property('QVariant', constant=True)
    def extensions(self):
        """
        The structure file formats from_smiles writes.
        """
        return ['.gro', '.pdb']

    @Property('QVariant', constant=True)
    def componentTypes(self):
        """
        The library class names a component is built as.
        """
        return list(self._types)

    @Property(bool, notify=readyChanged)
    def ready(self):
        """
        Whether Generate has what it needs: a name and a SMILES string.
        """
        return bool(self._name) and bool(self._smiles)

    @Property(bool, notify=nameTakenChanged)
    def nameTaken(self):
        """
        Whether the sample already holds a component of the draft's
        name.
        """
        return self._name in self._session.components

    @Slot()
    def generate(self):
        """
        Build a component of the draft and hand it to the root for the
        sample.
        """
        component = self._types[self._component_type].from_smiles(
            self._name,
            self._smiles,
            (self._box_x, self._box_y, self._box_z),
            formula=self._formula or None,
            cis=self._cis,
            align_z=self._align_z,
            flatten_xz=self._flatten_xz,
            extension=self._extension,
        )
        self.externalComponentCreated.emit(component)

    def refresh(self):
        """
        Follow the components list: a component added, renamed or
        removed may take or free the draft's name.
        """
        self.nameTakenChanged.emit()
