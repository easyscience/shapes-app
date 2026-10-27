# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from shapes.project import Library as LibraryLib


class Library(QObject):
    """
    The shapespyer library's lists for QML: saved projects (Recent),
    examples, and the asset catalogs.
    """

    # Emitted by the root after a project is created, loaded or saved
    availableProjectsChanged = Signal()
    # Emitted by the root after an asset is saved
    availableAssetsChanged = Signal()

    @Property('QVariant', notify=availableProjectsChanged)
    def availableProjects(self):
        """
        Saved projects, most recently saved first: {name, path,
        modified} rows, modified as local 'dd Mon YYYY HH:MM'.
        """
        return [
            {
                'name': path.name,
                'path': str(path),
                'modified': saved.astimezone().strftime('%d %b %Y %H:%M'),
            }
            for path, saved in LibraryLib().available_projects
        ]

    @Property('QVariant', constant=True)
    def availableExamples(self):
        """
        Example projects, by folder name: {name, path} rows.
        """
        return [{'name': path.name, 'path': str(path)} for path in LibraryLib().available_examples]

    @Property('QVariant', notify=availableAssetsChanged)
    def availableAssets(self):
        """
        Names of every asset by type, local first, then remote ones not
        held locally. The Load from lib popup lists the editor's types.
        """
        return LibraryLib().available_assets

    @Property('QVariant', notify=availableAssetsChanged)
    def availableIons(self):
        """
        Names of the library's ions, local first, then remote ones not
        held locally. A counter-ion name the components list accepts.
        """
        return LibraryLib().available_assets.get('Ion', [])

    @Property('QVariant', notify=availableAssetsChanged)
    def availableSolvents(self):
        """
        Names of the library's solvents, local first, then remote ones
        not held locally. A name the solvent picker offers.
        """
        return LibraryLib().available_assets.get('Solvent', [])

    @Property('QVariant', notify=availableAssetsChanged)
    def availableSalts(self):
        """
        Names of the library's salts, local first, then remote ones not
        held locally. A name the Load buffer components popup offers.
        """
        return LibraryLib().available_assets.get('Salt', [])
