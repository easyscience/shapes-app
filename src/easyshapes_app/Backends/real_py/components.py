# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

from PySide6.QtCore import Property
from PySide6.QtCore import QAbstractListModel
from PySide6.QtCore import QModelIndex
from PySide6.QtCore import QObject
from PySide6.QtCore import Qt
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project import Component
from shapes.project import Ion
from shapes.project import Lattice
from shapes.project import Lipid
from shapes.project import Surfactant
from shapes.project.files.records import read_ser_data

from .logic.session import Session


class ComponentsModel(QAbstractListModel):
    """
    The current structure's components as rows of an editable ListView.

    The rows are the library's own collection, read from the session
    each time. componentType is the library class name: Lipid,
    Surfactant or Component.

    A name the library refuses stays on screen, its reason in nameError,
    until the next accepted name for that row. Every other library error
    goes to the error dialog: an unknown counter ion, or a rename while
    a run writes the component's files (RuntimeError).
    """

    NameRole = Qt.UserRole + 1
    ComponentTypeRole = Qt.UserRole + 2
    CounterIonRole = Qt.UserRole + 3
    MintRole = Qt.UserRole + 4
    MextRole = Qt.UserRole + 5
    NameErrorRole = Qt.UserRole + 6

    countChanged = Signal()
    errorsChanged = Signal()

    # The library class counter ions load from; tests swap in a fake
    _ion_class = Ion

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session
        # Reasons of refused names, by component
        self._name_errors = {}

    ####################
    # Qt model overrides
    ####################

    def roleNames(self):
        return {
            self.NameRole: b'name',
            self.ComponentTypeRole: b'componentType',
            self.CounterIonRole: b'counterIon',
            self.MintRole: b'mint',
            self.MextRole: b'mext',
            self.NameErrorRole: b'nameError',
        }

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._components())

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        component = self._components()[index.row()]
        match role:
            case self.NameRole:
                return component.name
            case self.ComponentTypeRole:
                return type(component).__name__
            case self.CounterIonRole:
                return component.counter_ion.name if component.counter_ion else ''
            case self.MintRole:
                return component.mint
            case self.MextRole:
                return component.mext
            case self.NameErrorRole:
                return self._name_errors.get(component, '')
            case _:
                return None

    def setData(self, index, value, role=Qt.EditRole):
        if not index.isValid():
            return False
        component = self._components()[index.row()]
        match role:
            case self.NameRole:
                return self._set_name(index, component, value)
            case self.CounterIonRole:
                held = component.counter_ion.name if component.counter_ion else ''
                if held != value:
                    # An unknown name goes to the error dialog: the
                    # picker offers library ions only
                    component.counter_ion = self._ion_class.load(value) if value else None
                    self.dataChanged.emit(index, index, [role])
                return True
            case self.MintRole:
                if component.mint != value:
                    component.mint = value
                    self.dataChanged.emit(index, index, [role])
                return True
            case self.MextRole:
                if component.mext != value:
                    component.mext = value
                    self.dataChanged.emit(index, index, [role])
                return True
            case _:
                return False

    ############
    # QML access
    ############

    @Property(int, notify=countChanged)
    def count(self):
        return self.rowCount()

    @Property(str, notify=errorsChanged)
    def errors(self):
        """
        Every standing refusal, one line each, in row order.
        """
        return '\n'.join(
            f'Row {row + 1}: {self._name_errors[component]}'
            for row, component in enumerate(self._components())
            if component in self._name_errors
        )

    @Slot(int, result='QVariant')
    def get(self, row):
        """
        One row's roles by name, as ListModel.get gives them.
        """
        index = self.index(row)
        return {name.decode(): self.data(index, role) for role, name in self.roleNames().items()}

    #########
    # Changes
    #########

    def append(self, component):
        """
        Add a component as a new row; a held name is refused first.
        """
        components = self._components()
        # The library refuses a held name only inside append, after the
        # model has opened the new row: refuse before
        if component.name in components:
            raise ValueError(f'The structure already holds {component.name}')
        row = len(components)
        self.beginInsertRows(QModelIndex(), row, row)
        components.append(component)
        self.endInsertRows()
        self.countChanged.emit()

    def remove(self, row):
        """
        Remove the component in a row, and its refusals.
        """
        components = self._components()
        component = components[row]
        self.beginRemoveRows(QModelIndex(), row, row)
        components.remove(row)
        self.endRemoveRows()
        self.countChanged.emit()
        if self._name_errors.pop(component, None) is not None:
            self.errorsChanged.emit()

    def reset(self):
        """
        Show the rows of a new structure or sample model.
        """
        self.beginResetModel()
        self._name_errors.clear()
        self.endResetModel()
        self.countChanged.emit()
        self.errorsChanged.emit()

    #########
    # Helpers
    #########

    def _set_name(self, index, component, name):
        """
        Rename a component, or keep the typed name and the reason why
        not, until the next accepted name.
        """
        held = component.name
        error = ''
        if name != held:
            if name in self._components().names:
                # The library would rename first and refuse after,
                # keeping the clash: refuse here instead
                error = f'Another component is already named {name}'
            else:
                try:
                    component.name = name
                except ValueError as err:
                    # A folder clash; the library keeps the old name
                    error = str(err)
        if error:
            self._name_errors[component] = error
            self.dataChanged.emit(index, index, [self.NameErrorRole])
            self.errorsChanged.emit()
            return False
        roles = [self.NameRole] if name != held else []
        if self._name_errors.pop(component, None) is not None:
            roles.append(self.NameErrorRole)
            self.errorsChanged.emit()
        if roles:
            self.dataChanged.emit(index, index, roles)
        return True

    def _components(self):
        sample_model = self._session.sample_model
        if sample_model is None:
            return ()
        current = sample_model.structure
        return (current.unit if isinstance(current, Lattice) else current).components


class Components(QObject):
    """
    The components list for QML: its rows, adding a component from the
    library or from an export folder, and removing one.
    """

    # The library classes components load from, by class name; tests
    # swap in fakes
    _types = {cls.__name__: cls for cls in (Lipid, Surfactant, Component)}

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._model = ComponentsModel(session, self)

    @Property('QVariant', constant=True)
    def loaded(self):
        return self._model

    @Slot(str, str)
    def append(self, component_type, name):
        """
        Load a component from the library by type and name and add it as
        a new row.
        """
        self._model.append(self._types[component_type].load(name))

    @Slot(str)
    def importFrom(self, folder):
        """
        Add the component an export folder holds, of the class its
        record names.
        """
        # The record names the class the folder was exported from
        component_type = read_ser_data(Path(folder))['dtype']
        if component_type not in self._types:
            raise ValueError(f'{folder} holds a {component_type}, not a component')
        self._model.append(self._types[component_type].import_from(folder))

    @Slot(int)
    def remove(self, row):
        self._model.remove(row)

    @Slot(int, result='QVariant')
    def structureAtoms(self, row):
        # ponytail: atoms for the component viewer come with the visuals
        # phase; until then the viewer and vector lengths stay empty
        return []

    def refresh(self):
        """
        Show the rows of a new structure or sample model.
        """
        self._model.reset()
