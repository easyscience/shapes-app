# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest
from shapes.project import Component
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField

from easyshapes_app.Backends.real_backend import Backend
from easyshapes_app.Backends.real_py.logic.session import Session


@pytest.mark.fast
@pytest.mark.usefixtures('fresh_file_manager')
def test_component_added_in_components_files_renames_saves_exports_and_leaves(
    qcore_application, tmp_path
):
    itp = tmp_path / 'TstNew.itp'
    itp.write_text('[ moleculetype ]\n')
    # A default analysis loads its force field from the library, empty
    # offline: give the first project one, as bare_project does
    session = Session(
        analysis=Analysis(equilibration=Equilibration(force_field=ForceField(name='Field')))
    )
    backend = Backend(session)
    backend.project.create('files', '', str(tmp_path / 'files'))
    group = backend.componentsFiles

    group.create()
    group.appendFile(str(itp))
    assert backend.components.rename(group.selectedComponent, 'TstNew') == ''
    # A second one, refused the name the first now holds: the reason
    # goes back to the caller, the components list keeps none
    group.create()
    assert (
        backend.components.rename(group.selectedComponent, 'TstNew')
        == 'Another component is already named TstNew'
    )
    second = group.selectedComponent
    group.selectComponent('TstNew')
    assert not group.nameTaken()
    group.save(False)
    group.exportTo(str(tmp_path / 'export'), -1, False)

    assert session.sample_model.structure.components.names == ('TstNew', second)
    assert backend.components.loaded.errors == ''
    assert [Path(path).name for path in group.files.paths] == ['TstNew.itp']
    assert backend.library.availableAssets['Component'] == ['TstNew']
    assert group.nameTaken()
    assert Component.import_from(tmp_path / 'export').name == 'TstNew'

    backend.components.remove(0)

    assert group.selectedComponent == ''
