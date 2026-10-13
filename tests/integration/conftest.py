# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""Suite-wide isolation of the AppFileManager and Library singletons.

Copied from shapespyer's tests/shapes_unit_tests/conftest.py, which is not installed
with the package; keep the two in step. bare_project comes from its test_library.py.

BaseAsset.__init__ constructs AppFileManager(), so merely creating a Solvent or a
Component reaches for the singleton, and whoever builds it first decides where it
points. Library works the same way, and its default construction syncs over the
network. The fixtures below build one offline manager and library per session and
make them the live singletons at the start of every test. Tests needing their own app
directory use fresh_file_manager.
"""

from collections.abc import Iterator
from pathlib import Path

import pytest
from shapes.project import Project
from shapes.project import SampleModel
from shapes.project.analysis import Analysis
from shapes.project.analysis import Equilibration
from shapes.project.analysis import ForceField
from shapes.project.files import AppFileManager
from shapes.project.files.library import Index
from shapes.project.files.library import Library
from shapes.project.species import Buffer
from shapes.project.species import Solvent


@pytest.fixture
def offline_library(tmp_path: Path) -> Library:
    """A Library with both indices empty and no remote to download from."""
    if hasattr(Library, '_instance'):
        del Library._instance
    idx_path = tmp_path / 'indices'
    idx_path.mkdir()
    return Library(
        Index(file_name='remote.yaml', path=idx_path),
        Index(file_name='local.yaml', path=idx_path),
        tmp_path / 'app' / 'LocalAssets',
    )


@pytest.fixture
def config_file(tmp_path: Path) -> Path:
    """A config file putting the app directory at tmp_path / 'app', with no GROMACS."""
    config_file = tmp_path / 'config.yaml'
    config_file.write_text(
        f'app_path: app\ngmx_executable: {tmp_path / "no-gmx"}\n', encoding='utf-8'
    )
    return config_file


@pytest.fixture
def fresh_file_manager(config_file: Path, offline_library: Library) -> Iterator[AppFileManager]:
    """A fresh AppFileManager in tmp_path / 'app', with the offline library live."""
    del offline_library  # requested for building it, which makes it the live library
    if hasattr(AppFileManager, '_instance'):
        del AppFileManager._instance
    yield AppFileManager(config_file)
    if hasattr(AppFileManager, '_instance'):
        del AppFileManager._instance


@pytest.fixture(scope='session')
def offline_session_config_file(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """A config file putting the session's app directory in a session temp directory."""
    config_file = tmp_path_factory.mktemp('config') / 'config.yaml'
    config_file.write_text(
        f'app_path: app\ngmx_executable: {config_file.parent / "no-gmx"}\n', encoding='utf-8'
    )
    return config_file


@pytest.fixture(scope='session')
def offline_session_library(
    tmp_path_factory: pytest.TempPathFactory, offline_session_config_file: Path
) -> Library:
    """An empty library in the session's app directory, with no remote to download from."""
    if hasattr(Library, '_instance'):
        del Library._instance
    idx_path = tmp_path_factory.mktemp('indices')
    remote = Index(file_name='remote.yaml', path=idx_path)
    local = Index(file_name='local.yaml', path=idx_path)
    return Library(remote, local, offline_session_config_file.parent / 'app' / 'LocalAssets')


@pytest.fixture(scope='session')
def offline_app_file_manager(offline_session_config_file: Path) -> AppFileManager:
    """An AppFileManager on the session's config file."""
    if hasattr(AppFileManager, '_instance'):
        del AppFileManager._instance
    return AppFileManager(offline_session_config_file)


@pytest.fixture(autouse=True)
def _isolate_app_file_manager(
    offline_app_file_manager: AppFileManager, offline_session_library: Library
) -> None:
    """Point the singletons at the offline manager and library before every test."""
    AppFileManager._instance = offline_app_file_manager
    Library._instance = offline_session_library


def bare_project(name: str) -> Project:
    """A project holding no files, with every part injected instead of loaded."""
    return Project(
        name=name,
        sample_model=SampleModel(
            name=f'{name}Model',
            buffer=Buffer(name=f'{name}Buffer', solvent=Solvent(name=f'{name}Solvent')),
        ),
        analysis=Analysis(
            name=f'{name}Analysis',
            equilibration=Equilibration(force_field=ForceField(name=f'{name}Field')),
        ),
    )
