# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path
from types import SimpleNamespace

import pytest
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.components import Components
from easyshapes_app.Backends.real_py.components import ComponentsModel
from easyshapes_app.Backends.real_py.logic.session import Session
from tests.unit.factories import REFUSED
from tests.unit.factories import FakeSampleModel
from tests.unit.factories import refusals

Model = ComponentsModel
IONS = ('NA', 'CL')


class FakeComponent:
    def __init__(self, name, counter_ion=None):
        self.name = name
        self.counter_ion = counter_ion
        self.mint = 0
        self.mext = 1
        self.bone_length = None
        self.structure_file_path = None
        self.topology_file_path = None
        # Atoms of one molecule in its structure file; None without one
        self.number_of_atoms = None

    @property
    def bone(self):
        # As shapespyer's Species.bone
        if self.mint != self.mext:
            return self.mint, self.mext
        if self.number_of_atoms is None or self.number_of_atoms < 2:
            return None
        return self.number_of_atoms - 1, 0

    @classmethod
    def load(cls, name):
        return cls(name)

    @classmethod
    def import_from(cls, folder):
        return cls(Path(folder).name)


class Lipid(FakeComponent):
    """
    Named like the library class: componentType reads the class name.
    """


class FolderClash(FakeComponent):
    """
    Refuses every rename and keeps its name, as the library does when
    the new folder already exists.
    """

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        if hasattr(self, '_name'):
            raise ValueError(f'Folder {value} already exists')
        self._name = value


class FakeComponents(list):
    """
    The library's collection: rows by index, names, held names, remove
    by row.
    """

    @property
    def names(self):
        return tuple(component.name for component in self)

    def __contains__(self, name):
        return name in self.names

    def remove(self, row):
        del self[row]


class FakeIon:
    """
    Loads the ions named in IONS, as the library loads saved ones.
    """

    def __init__(self, name):
        self.name = name

    @classmethod
    def load(cls, name):
        if name not in IONS:
            raise LookupError(f'Asset with the name {name} was not found in the asset library.')
        return cls(name)


class OfflineComponentsModel(ComponentsModel):
    """
    Loads FakeIons, not library ones.
    """

    _ion_class = FakeIon


class OfflineComponents(Components):
    """
    Loads and imports fakes under the library's class names.
    """

    _types = {'Lipid': Lipid, 'Surfactant': FakeComponent, 'Component': FakeComponent}


def session_with_components():
    components = FakeComponents([
        Lipid('DPPC', FakeIon('NA')),
        FolderClash('CHOL'),
        Lipid('POPC'),
    ])
    sample_model = FakeSampleModel()
    sample_model.structure = SimpleNamespace(components=components)
    return Session(sample_model=sample_model), components


@pytest.fixture
def built(qcore_application):
    session, components = session_with_components()
    return OfflineComponentsModel(session), components


def write(model, row, value, role):
    return model.setData(model.index(row), value, role)


def emitted_roles(model):
    """
    The roles of each dataChanged, collected as they come.
    """
    emitted = []
    model.dataChanged.connect(lambda top, bottom, roles: emitted.append(list(roles)))
    return emitted


def test_rows_refuse_an_invalid_index_or_an_unknown_role(built):
    model, _ = built

    assert refusals(model, 'DOPC') == REFUSED


def test_rows_read_the_library_components(built):
    model, _ = built

    assert model.count == 3
    assert model.get(0) == {
        'name': 'DPPC',
        'componentType': 'Lipid',
        'counterIon': 'NA',
        'mint': 0,
        'mext': 1,
        'nameError': '',
    }
    assert model.get(2)['counterIon'] == ''


@pytest.mark.parametrize(('role', 'field'), [(Model.MintRole, 'mint'), (Model.MextRole, 'mext')])
def test_mint_and_mext_write_the_component_and_emit_only_on_change(built, role, field):
    model, components = built
    emitted = emitted_roles(model)

    assert write(model, 0, 5, role)
    assert write(model, 0, 5, role)

    assert getattr(components[0], field) == 5
    # The other end may change too: both are announced
    assert emitted == [[Model.MintRole, Model.MextRole]]


@pytest.mark.parametrize('number_of_atoms', [42, None], ids=['structure file', 'none'])
def test_an_unset_bone_shows_what_shapespyer_works_out(built, number_of_atoms):
    model, components = built
    components[0].mint = components[0].mext = 3
    components[0].number_of_atoms = number_of_atoms

    shown = (model.get(0)['mint'], model.get(0)['mext'])

    # The last atom to the first; the stored ends while it can't
    assert shown == ((41, 0) if number_of_atoms else (3, 3))


def test_an_edit_of_an_unset_bone_keeps_the_other_end_as_shown(built):
    model, components = built
    components[0].mint = components[0].mext = 3
    components[0].number_of_atoms = 42

    assert write(model, 0, 5, Model.MintRole)

    assert (components[0].mint, components[0].mext) == (5, 0)


@pytest.mark.parametrize(('role', 'value'), [(Model.MintRole, 1), (Model.MextRole, 0)])
def test_equal_ends_are_refused(built, role, value):
    model, components = built
    emitted = emitted_roles(model)

    assert not write(model, 0, value, role)

    assert (components[0].mint, components[0].mext) == (0, 1)
    assert emitted == []


@pytest.mark.parametrize(
    ('role', 'held'),
    [
        (Model.NameRole, 'DPPC'),
        (Model.CounterIonRole, 'NA'),
        (Model.MintRole, 0),
        (Model.MextRole, 1),
    ],
    ids=['name', 'counterIon', 'mint', 'mext'],
)
def test_writing_the_held_value_emits_nothing(built, role, held):
    model, _ = built
    emitted = emitted_roles(model)
    errors = QSignalSpy(model.errorsChanged)

    assert write(model, 0, held, role)

    assert emitted == []
    assert errors.count() == 0


def test_taken_name_is_refused_and_kept_with_its_reason(built):
    model, components = built
    emitted = emitted_roles(model)
    errors = QSignalSpy(model.errorsChanged)

    assert not write(model, 2, 'DPPC', Model.NameRole)

    assert components[2].name == 'POPC'
    assert model.get(2)['nameError'] == 'Another component is already named DPPC'
    assert model.errors == 'Row 3: Another component is already named DPPC'
    # Only the error role: the typed name stays in the cell
    assert emitted == [[Model.NameErrorRole]]
    assert errors.count() == 1


def test_folder_clash_is_kept_with_its_reason(built):
    model, components = built

    assert not write(model, 1, 'SOL', Model.NameRole)

    assert components[1].name == 'CHOL'
    assert model.errors == 'Row 2: Folder SOL already exists'


@pytest.mark.parametrize(
    ('name', 'roles'),
    [('DOPC', [Model.NameRole, Model.NameErrorRole]), ('POPC', [Model.NameErrorRole])],
    ids=['new', 'held'],
)
def test_accepted_name_clears_the_reason(built, name, roles):
    model, components = built
    write(model, 2, 'DPPC', Model.NameRole)
    emitted = emitted_roles(model)

    assert write(model, 2, name, Model.NameRole)

    assert components[2].name == name
    assert model.get(2)['nameError'] == ''
    assert model.errors == ''
    assert emitted == [roles]


@pytest.mark.parametrize(
    ('row', 'name', 'held'),
    [(2, 'CL', 'CL'), (0, '', None)],
    ids=['known', 'empty'],
)
def test_counter_ion_takes_a_library_ion_or_none(built, row, name, held):
    model, components = built

    assert write(model, row, name, Model.CounterIonRole)

    ion = components[row].counter_ion
    assert (ion.name if ion else None) == held
    assert model.get(row)['counterIon'] == name


def test_unknown_counter_ion_goes_to_the_error_dialog(built):
    model, components = built

    with pytest.raises(LookupError):
        write(model, 0, 'XX', Model.CounterIonRole)

    assert components[0].counter_ion.name == 'NA'


def test_errors_list_refusals_in_row_order(built):
    model, _ = built
    write(model, 2, 'DPPC', Model.NameRole)
    write(model, 1, 'SOL', Model.NameRole)

    assert model.errors.splitlines() == [
        'Row 2: Folder SOL already exists',
        'Row 3: Another component is already named DPPC',
    ]


def test_remove_drops_the_row_and_its_reasons(built):
    model, components = built
    write(model, 2, 'DPPC', Model.NameRole)
    count = QSignalSpy(model.countChanged)
    errors = QSignalSpy(model.errorsChanged)

    model.remove(2)

    assert components.names == ('DPPC', 'CHOL')
    assert model.count == 2
    assert model.errors == ''
    assert (count.count(), errors.count()) == (1, 1)


def test_reset_drops_every_reason(built):
    model, _ = built
    write(model, 2, 'DPPC', Model.NameRole)
    reset = QSignalSpy(model.modelReset)

    model.reset()

    assert model.errors == ''
    assert model.get(2)['nameError'] == ''
    assert reset.count() == 1


def test_refresh_files_shows_the_components_row_anew(built):
    model, components = built
    emitted = []
    model.dataChanged.connect(
        lambda top, bottom, roles: emitted.append((top.row(), bottom.row(), list(roles)))
    )

    model.refresh_files(components[2])

    # No roles: every role may have changed
    assert emitted == [(2, 2, [])]


def test_no_sample_model_has_no_rows(qcore_application):
    model = OfflineComponentsModel(Session())

    assert model.count == 0
    assert model.errors == ''


def test_part_shows_rows_removes_and_refreshes(qcore_application):
    session, components = session_with_components()
    part = Components(session)
    reset = QSignalSpy(part.loaded.modelReset)

    part.remove(0)
    part.refresh()

    assert isinstance(part.loaded, ComponentsModel)
    assert components.names == ('CHOL', 'POPC')
    assert part.loaded.count == 2
    assert reset.count() == 1
    # No structure file: nothing to read
    assert part.structureAtoms(0) == []


@pytest.mark.parametrize(('measured', 'shown'), [(1.5, 1.5), (None, 0.0)], ids=['set', 'unset'])
def test_bone_length_is_the_librarys_or_zero(qcore_application, measured, shown):
    session, components = session_with_components()
    components[0].bone_length = measured

    assert Components(session).boneLength(0) == shown


def test_bonds_come_from_the_components_topology_file(qcore_application, tmp_path):
    # The file's reading is test_logic_itp's
    itp = tmp_path / 'topology.itp'
    itp.write_text('[ moleculetype ]\nDPPC  3\n\n[ bonds ]\n1  2  1\n')
    session, components = session_with_components()
    components[0].topology_file_path = itp

    assert Components(session).structureBonds(0) == [[0, 1]]


def test_no_topology_file_has_no_bonds(qcore_application):
    session, _ = session_with_components()

    assert Components(session).structureBonds(0) == []


def test_part_appends_a_library_component_as_a_new_row(qcore_application):
    session, components = session_with_components()
    part = OfflineComponents(session)
    inserted = QSignalSpy(part.loaded.rowsInserted)
    count = QSignalSpy(part.loaded.countChanged)

    part.append('Lipid', 'DOPC')

    assert components.names == ('DPPC', 'CHOL', 'POPC', 'DOPC')
    assert part.loaded.get(3)['componentType'] == 'Lipid'
    assert (inserted.count(), count.count()) == (1, 1)


def test_held_name_raises_before_any_row_opens(qcore_application):
    session, components = session_with_components()
    part = OfflineComponents(session)
    opening = QSignalSpy(part.loaded.rowsAboutToBeInserted)

    with pytest.raises(ValueError, match='already holds POPC'):
        part.append('Lipid', 'POPC')

    assert len(components) == 3
    assert opening.count() == 0


def test_import_appends_the_class_its_record_names(qcore_application, tmp_path):
    folder = tmp_path / 'DOPC'
    folder.mkdir()
    (folder / 'ser_data.yaml').write_text('dtype: Lipid\n')
    session, components = session_with_components()
    part = OfflineComponents(session)

    part.importFrom(str(folder))

    assert components.names[-1] == 'DOPC'
    assert part.loaded.get(3)['componentType'] == 'Lipid'


def test_part_renames_through_the_name_cells_path(qcore_application):
    session, components = session_with_components()
    part = OfflineComponents(session)
    emitted = emitted_roles(part.loaded)

    assert part.rename('POPC', 'DOPC') == ''

    assert components.names == ('DPPC', 'CHOL', 'DOPC')
    assert emitted == [[Model.NameRole]]


@pytest.mark.parametrize(
    ('name', 'new_name', 'reason'),
    [
        ('POPC', 'DPPC', 'Another component is already named DPPC'),
        ('CHOL', 'SOL', 'Folder SOL already exists'),
    ],
    ids=['taken', 'folder'],
)
def test_refused_rename_returns_its_reason_and_leaves_the_list_alone(
    qcore_application, name, new_name, reason
):
    session, components = session_with_components()
    part = OfflineComponents(session)
    emitted = emitted_roles(part.loaded)
    errors = QSignalSpy(part.loaded.errorsChanged)

    assert part.rename(name, new_name) == reason

    assert components.names == ('DPPC', 'CHOL', 'POPC')
    assert part.loaded.errors == ''
    assert (emitted, errors.count()) == ([], 0)


def test_import_of_another_class_raises(qcore_application, tmp_path):
    (tmp_path / 'ser_data.yaml').write_text('dtype: Salt\n')
    session, components = session_with_components()

    with pytest.raises(ValueError, match='holds a Salt, not a component'):
        OfflineComponents(session).importFrom(str(tmp_path))

    assert len(components) == 3
