# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from types import SimpleNamespace

import pytest
from PySide6.QtCore import QModelIndex
from PySide6.QtTest import QSignalSpy
from shapes.project import Ball
from shapes.project import Bilayer
from shapes.project import Lattice
from shapes.project import Monolayer
from shapes.project import Ring
from shapes.project import Rod
from shapes.project import Vesicle

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session
from tests.unit.factories import FakeSampleModel


class ByName(list):
    """
    The library's collection as the parts read it: by row or by name,
    whether it holds a name, and its names.
    """

    def __getitem__(self, key):
        if isinstance(key, str):
            return next(item for item in self if item.name == key)
        return super().__getitem__(key)

    def __contains__(self, key):
        if isinstance(key, str):
            return key in self.names
        return super().__contains__(key)

    @property
    def names(self):
        return tuple(item.name for item in self)


def test_project_change_refreshes_recent(qcore_application):
    backend = Backend(Session())
    spy = QSignalSpy(backend.library.availableProjectsChanged)

    backend.project.externalProjectChanged.emit()

    assert spy.count() == 1


@pytest.mark.parametrize('part', ['libraryAssets', 'componentsFiles', 'sampleModel'])
def test_asset_save_refreshes_the_catalogs(qcore_application, part):
    backend = Backend(Session())
    spy = QSignalSpy(backend.library.availableAssetsChanged)

    getattr(backend, part).externalAssetsChanged.emit()

    assert spy.count() == 1


# Each shape adapter on the backend, and the class it adapts
SHAPE_ADAPTERS = {
    'ringStructure': Ring,
    'ballStructure': Ball,
    'vesicleStructure': Vesicle,
    'rodStructure': Rod,
    'bilayerStructure': Bilayer,
    'monolayerStructure': Monolayer,
}
ADAPTERS = [*SHAPE_ADAPTERS, 'latticeStructure']


def test_project_change_refreshes_sample_model_components_and_adapters(qcore_application):
    backend = Backend(Session())
    name = QSignalSpy(backend.sampleModel.nameChanged)
    components = QSignalSpy(backend.components.loaded.modelReset)
    swapped = [QSignalSpy(getattr(backend, f'{adapter}Changed')) for adapter in ADAPTERS]
    composition = QSignalSpy(backend.compositionChanged)
    layers = QSignalSpy(backend.layersChanged)
    lamellae = QSignalSpy(backend.lamellaeChanged)
    buffer = QSignalSpy(backend.bufferChanged)

    backend.project.externalProjectChanged.emit()

    assert name.count() == 1
    assert components.count() == 1
    assert [spy.count() for spy in swapped] == [1] * len(ADAPTERS)
    assert [getattr(backend, adapter) for adapter in ADAPTERS] == [None] * len(ADAPTERS)
    assert composition.count() == 1
    assert backend.composition is None
    assert layers.count() == 1
    assert backend.layers is None
    assert lamellae.count() == 1
    assert backend.lamellae is None
    assert buffer.count() == 1
    assert backend.buffer is None


def test_buffer_adapter_reads_the_sample_models_buffer(qcore_application):
    sample_model = FakeSampleModel()
    sample_model.buffer.solvent = SimpleNamespace(name='TIP3')
    backend = Backend(Session(sample_model=sample_model))
    swapped = QSignalSpy(backend.bufferChanged)

    backend.sampleModel.externalStructureChanged.emit()

    assert backend.buffer.solvent == 'TIP3'
    assert swapped.count() == 1


@pytest.mark.parametrize('lattice', [False, True], ids=['plain', 'lattice'])
@pytest.mark.parametrize('adapter', list(SHAPE_ADAPTERS))
def test_only_the_current_shape_and_its_lattice_are_adapted(qcore_application, adapter, lattice):
    unit = SHAPE_ADAPTERS[adapter]()
    sample_model = FakeSampleModel(Lattice(unit=unit) if lattice else unit)
    backend = Backend(Session(sample_model=sample_model))

    backend.sampleModel.externalStructureChanged.emit()

    adapted = {name for name in ADAPTERS if getattr(backend, name) is not None}
    assert adapted == ({adapter, 'latticeStructure'} if lattice else {adapter})


@pytest.mark.parametrize('lattice', [False, True], ids=['plain', 'lattice'])
def test_ring_adapter_follows_the_current_structure(qcore_application, lattice):
    ring = Ring()
    sample_model = FakeSampleModel(Lattice(unit=ring) if lattice else ring)
    backend = Backend(Session(sample_model=sample_model))
    swapped = QSignalSpy(backend.ringStructureChanged)

    backend.sampleModel.externalStructureChanged.emit()
    backend.ringStructure.dmin = 0.7

    assert ring.dmin == 0.7
    assert swapped.count() == 1

    backend.sampleModel.shape = 'Ball'

    assert backend.ringStructure is None
    assert swapped.count() == 2


@pytest.mark.parametrize('adapter', list(SHAPE_ADAPTERS))
def test_each_shape_gets_the_models_of_its_compositions(qcore_application, adapter):
    backend = Backend(Session(sample_model=FakeSampleModel(SHAPE_ADAPTERS[adapter]())))

    backend.sampleModel.externalStructureChanged.emit()

    owns = adapter not in ('ballStructure', 'vesicleStructure')
    assert (backend.composition is not None) == owns
    assert (backend.layers is not None) == (adapter == 'ballStructure')
    assert (backend.lamellae is not None) == (adapter == 'vesicleStructure')


# Each shape, and where its first composition's rows are
COMPOSITION_ROWS = [
    (Ring, lambda backend: backend.composition),
    (Ball, lambda backend: backend.layers.compositions[0]),
    (Vesicle, lambda backend: backend.lamellae.innerLeafletCompositions[0]),
]


@pytest.mark.parametrize(
    ('shape', 'rows'), COMPOSITION_ROWS, ids=['composition', 'layers', 'lamellae']
)
def test_component_changes_refresh_the_composition_rows(qcore_application, shape, rows):
    backend = Backend(Session(sample_model=FakeSampleModel(shape())))
    backend.sampleModel.externalStructureChanged.emit()
    reset = QSignalSpy(rows(backend).modelReset)

    backend.components.loaded.dataChanged.emit(QModelIndex(), QModelIndex(), [])

    assert reset.count() == 1


@pytest.mark.parametrize(
    ('shape', 'rows'), COMPOSITION_ROWS, ids=['composition', 'layers', 'lamellae']
)
def test_added_component_refreshes_the_composition_rows(qcore_application, shape, rows):
    backend = Backend(Session(sample_model=FakeSampleModel(shape())))
    backend.sampleModel.externalStructureChanged.emit()
    reset = QSignalSpy(rows(backend).modelReset)
    loaded = backend.components.loaded

    # The insert signals an append sends, without a library component
    loaded.beginInsertRows(QModelIndex(), 0, 0)
    loaded.endInsertRows()

    assert reset.count() == 1


def test_created_component_joins_the_components_list(qcore_application):
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=[])
    backend = Backend(Session(sample_model=sample_model))
    inserted = QSignalSpy(backend.components.loaded.rowsInserted)

    backend.componentsFiles.externalComponentCreated.emit(SimpleNamespace(name='DOPC'))

    assert [component.name for component in sample_model.structure.components] == ['DOPC']
    assert inserted.count() == 1


def test_components_list_changes_refresh_components_files(qcore_application):
    dppc = SimpleNamespace(name='DPPC', paths=())
    components = ByName([dppc])
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=components)
    backend = Backend(Session(sample_model=sample_model))
    loaded = backend.components.loaded
    group = backend.componentsFiles
    group.selectComponent('DPPC')
    spy = QSignalSpy(group.selectedComponentChanged)

    # A rename shows once; a change that keeps the name shows nothing
    dppc.name = 'DOPC'
    loaded.dataChanged.emit(QModelIndex(), QModelIndex(), [])
    loaded.dataChanged.emit(QModelIndex(), QModelIndex(), [])
    assert (group.selectedComponent, spy.count()) == ('DOPC', 1)

    # Private signals: sent the way a remove and a reset send them
    loaded.beginRemoveRows(QModelIndex(), 0, 0)
    components.remove(dppc)
    loaded.endRemoveRows()
    assert (group.selectedComponent, spy.count()) == ('', 2)

    components.append(dppc)
    group.selectComponent('DOPC')
    sample_model.structure = SimpleNamespace(components=ByName())
    loaded.beginResetModel()
    loaded.endResetModel()
    assert (group.selectedComponent, spy.count()) == ('', 4)


def test_generated_component_joins_the_list_and_components_files(qcore_application):
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=ByName())
    backend = Backend(Session(sample_model=sample_model))

    backend.smilesGenerator.externalComponentCreated.emit(SimpleNamespace(name='SDS', paths=()))

    assert sample_model.structure.components.names == ('SDS',)
    assert backend.componentsFiles.selectedComponent == 'SDS'
    assert backend.smilesGenerator.generated


def test_generated_component_of_a_taken_name_goes_to_the_error_dialog(qcore_application):
    sds = SimpleNamespace(name='SDS', paths=())
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=ByName([sds]))
    backend = Backend(Session(sample_model=sample_model))

    # A slot's exception goes to the hook; the emit goes on
    backend.smilesGenerator.externalComponentCreated.emit(SimpleNamespace(name='SDS', paths=()))

    assert backend.error.message == 'ValueError: The structure already holds SDS'
    assert sample_model.structure.components == [sds]
    assert backend.componentsFiles.selectedComponent == ''
    assert not backend.smilesGenerator.generated


def test_components_list_changes_refresh_the_smiles_name_check(qcore_application):
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=ByName([SimpleNamespace(name='SDS')]))
    backend = Backend(Session(sample_model=sample_model))
    loaded = backend.components.loaded
    spy = QSignalSpy(backend.smilesGenerator.nameTakenChanged)

    # Private signals: sent the way an append, an edit, a remove and a
    # reset send them
    loaded.beginInsertRows(QModelIndex(), 1, 1)
    loaded.endInsertRows()
    loaded.dataChanged.emit(QModelIndex(), QModelIndex(), [])
    loaded.beginRemoveRows(QModelIndex(), 0, 0)
    loaded.endRemoveRows()
    loaded.beginResetModel()
    loaded.endResetModel()

    assert spy.count() == 4
