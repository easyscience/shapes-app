# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from shapes.project import Library as LibraryLib


class Library(QObject):
    """
    The shapespyer library's lists for QML: saved projects (Recent),
    examples, and the ion, solvent and salt catalogs.
    """

    # Emitted by the root after a project is created, loaded or saved
    availableProjectsChanged = Signal()

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

    @Property('QVariant', constant=True)
    def availableIons(self):
        """
        Names of the library's ions, local first, then remote ones not
        held locally. A counter-ion name the components list accepts.
        """
        # ponytail: constant until ions can be saved to the library
        # (step 5); then a notify signal the root emits after a save
        return LibraryLib().available_assets.get('Ion', [])

    @Property('QVariant', constant=True)
    def availableSolvents(self):
        """
        Names of the library's solvents, local first, then remote ones
        not held locally. A name the solvent picker offers.
        """
        # ponytail: constant, as availableIons
        return LibraryLib().available_assets.get('Solvent', [])

    @Property('QVariant', constant=True)
    def availableSalts(self):
        """
        Names of the library's salts, local first, then remote ones not
        held locally. A name the Load buffer components popup offers.
        """
        # ponytail: constant, as availableIons
        return LibraryLib().available_assets.get('Salt', [])
