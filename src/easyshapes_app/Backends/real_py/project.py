# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

from PySide6.QtCore import Property
from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtCore import Slot
from shapes.project import Project as ProjectLib

from .logic.session import Session


class Project(QObject):
    """
    The session's shapespyer project for QML: its fields, and create,
    load and save.

    Fields read '' while there is no project. Create and load put the
    new project into the session together with its sample model and
    analysis. Errors are not caught here; they go to the global error
    dialog (PROXY_LAYER.md section 2.7).
    """

    createdChanged = Signal()
    nameChanged = Signal()
    descriptionChanged = Signal()
    pathChanged = Signal()
    modifiedChanged = Signal()

    # Created, loaded or saved: the root tells the parts that may care
    externalProjectChanged = Signal()

    # The library class create builds and load reads; tests swap in a
    # fake
    _project_class = ProjectLib

    def __init__(self, session: Session, parent=None):
        super().__init__(parent)
        self._session = session

    ##########################
    # GUI accessible variables
    ##########################

    @Property(bool, notify=createdChanged)
    def created(self):
        return self._session.project is not None

    @Property(str, notify=nameChanged)
    def name(self):
        project = self._session.project
        return project.name if project else ''

    @name.setter
    def name(self, value):
        project = self._session.project
        if project is None or project.name == value:
            return
        project.name = value
        self.nameChanged.emit()

    @Property(str, notify=descriptionChanged)
    def description(self):
        project = self._session.project
        return project.description if project else ''

    @description.setter
    def description(self, value):
        project = self._session.project
        if project is None or project.description == value:
            return
        project.description = value
        self.descriptionChanged.emit()

    @Property(str, notify=pathChanged)
    def path(self):
        project = self._session.project
        return str(project.path) if project else ''

    @Property(str, notify=pathChanged)
    def pathParentUrl(self):
        """
        file:// URL of the folder holding the project, where the next
        create dialog opens; '' without a project.
        """
        project = self._session.project
        return project.path.parent.as_uri() if project else ''

    @Property(str, notify=modifiedChanged)
    def modified(self):
        """
        Last save as local 'dd Mon YYYY HH:MM'; '' before the first save
        or without a project.
        """
        project = self._session.project
        if project is None or project.modified is None:
            return ''
        return project.modified.astimezone().strftime('%d %b %Y %H:%M')

    ##########################
    # GUI accessible functions
    ##########################

    @Slot(str, result=bool)
    def locationTaken(self, path):
        """
        Whether a location typed for create already holds something: a
        file, or a folder that is not empty. An empty path means the
        library default, which its uid keeps new.
        """
        if not path:
            return False
        location = Path(path)
        try:
            return location.is_file() or (location.is_dir() and any(location.iterdir()))
        except OSError:
            # An unreadable folder cannot take the project either
            return True

    @Slot(str, str, str)
    def create(self, name, description, path):
        """
        Make a new project. The first one takes in the session's sample
        model and analysis.

        Empty name and path go to the library as None: it names the
        project by its uid and puts it in Projects/<full_name>.
        """
        first = self._session.project is None
        self._set_session_project(
            self._project_class(
                name=name or None,
                description=description,
                sample_model=self._session.sample_model if first else None,
                analysis=self._session.analysis if first else None,
                path=path or None,
            )
        )

    @Slot(str)
    def load(self, path):
        self._set_session_project(self._project_class.load(path))

    @Slot()
    def save(self):
        self._session.project.save()
        self.modifiedChanged.emit()
        self.externalProjectChanged.emit()

    #########
    # Helpers
    #########

    def _set_session_project(self, project):
        """
        Put a project into the session with its sample model and
        analysis, and tell QML.
        """
        self._session.project = project
        self._session.sample_model = project.sample_model
        self._session.analysis = project.analysis
        self.createdChanged.emit()
        self.nameChanged.emit()
        self.descriptionChanged.emit()
        self.pathChanged.emit()
        self.modifiedChanged.emit()
        self.externalProjectChanged.emit()
