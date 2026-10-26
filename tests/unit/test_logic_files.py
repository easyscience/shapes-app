# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from easyshapes_app.Backends.real_py.logic.files import export_taken


def test_export_taken_finds_what_an_export_would_replace(tmp_path):
    folder = tmp_path / 'export'

    assert not export_taken(folder)
    folder.mkdir()
    (folder / 'notes.txt').write_text('')
    assert export_taken(folder)
    assert not export_taken(folder, 'files/DPPC.itp')

    (folder / 'DPPC.itp').write_text('')
    assert export_taken(folder, 'files/DPPC.itp')
