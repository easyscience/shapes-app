# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
The app's entry point: the splash, the examples, then the window.
"""

import logging
import os
import subprocess  # noqa: S404 - only runs this app itself
import sys
import threading
from pathlib import Path

import EasyApplication
from PySide6.QtCore import QMetaObject
from PySide6.QtCore import Qt
from PySide6.QtCore import QUrl
from PySide6.QtCore import qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQml import qmlRegisterSingletonType

# Path to the QML components of the current project
CURRENT_DIR = Path(__file__).parent
# Parent dir of the installed EasyApplication package
EASYAPP_DIR = Path(EasyApplication.__path__[0]).resolve().parent


def show_splash():
    """
    Show the logo until the app closes this process's stdin, or ends.

    This runs as main.py --splash.
    """
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    engine.load(CURRENT_DIR / 'Splash.qml')

    def exit_when_app_is_up():
        os.read(0, 1)  # Returns when the app closes the pipe, or ends
        # Queued, so the GUI thread quits. A normal exit lets Qt clean
        # up; os._exit skipped that, and Qt warned about it
        QMetaObject.invokeMethod(app, 'quit', Qt.ConnectionType.QueuedConnection)

    threading.Thread(target=exit_when_app_is_up, daemon=True).start()
    sys.exit(app.exec())


if __name__ == '__main__':
    if '--splash' in sys.argv:
        show_splash()

    # The backend's imports take seconds: meanwhile the logo shows in
    # its own process, which nothing here can freeze. Packaged, the
    # executable is the app itself; else Python runs this file
    app_command = [sys.executable] if getattr(sys, 'frozen', False) else [sys.executable, __file__]
    splash = subprocess.Popen([*app_command, '--splash'], stdin=subprocess.PIPE)  # noqa: S603
    # Not at the top: shapespyer's job processes run this file's top
    # again. EasyApp's logger there would print their messages here,
    # instead of shapespyer sending them to the job's log file
    from Backends.real_backend import Backend
    from Backends.real_py.logic.examples import make_examples
    from EasyApplication.Logic.Logging import LoggerLevelHandler
    from EasyApplication.Logic.Logging import console
    from shapes.project.files import AppFileManager

    # Fills Project › Examples, unassembled, while the splash shows.
    # shortcut: an example already there is never rebuilt, so a changed
    # builder reaches only new installs; key the folders by version then
    try:
        make_examples(AppFileManager().app_path / 'Examples')
    # Offline, or the library lacks a component: the app starts anyway,
    # and the next start tries again
    except (OSError, ValueError, KeyError) as err:
        console.error(f'The examples could not be made: {err}')

    qInstallMessageHandler(console.qmlMessageHandler)
    console.debug('Custom Qt message handler defined')

    # This singleton object will be accessible in QML as follows:
    # import Backends 1.0 as Backends OR import Backends as Backends
    # property var activeBackend: Backends.PyBackend
    # Before the app and engine exist: registered after them,
    # main.qml fails to load
    qmlRegisterSingletonType(Backend, 'Backends', 1, 0, 'PyBackend')
    console.debug('Backend class is registered as a singleton type for QML')

    app = QGuiApplication(sys.argv)
    console.debug(f'Qt Application created {app}')

    engine = QQmlApplicationEngine()
    console.debug(f'QML application engine created {engine}')

    engine.addImportPath(CURRENT_DIR)
    engine.addImportPath(EASYAPP_DIR)
    console.debug('Paths added where QML searches for components')

    # EasyApp's Settings objects save to this file. Unset, they save
    # into EasyApp's package folder, which an update replaces
    settings_url = QUrl.fromLocalFile(str(AppFileManager().app_path / 'settings.ini')).toString()
    engine.rootContext().setContextProperty('pySettingsPath', settings_url)
    console.debug(f'Settings file set to {settings_url}')

    # ApplicationWindow.qml binds its level to the Preferences
    # logging level, so a change reaches the Python logger
    logger_level_handler = LoggerLevelHandler()
    engine.rootContext().setContextProperty('pyLoggerLevelHandler', logger_level_handler)
    # shapespyer logs to the stdlib logger '__main__', which the
    # handler doesn't reach; it gets the same level
    stdlib_levels = {'debug': logging.DEBUG, 'info': logging.INFO, 'error': logging.ERROR}
    logger_level_handler.levelChanged.connect(
        lambda: logging.getLogger('__main__').setLevel(
            stdlib_levels.get(logger_level_handler.level, logging.CRITICAL + 1)
        )
    )

    engine.load(CURRENT_DIR / 'main.qml')
    console.debug('Main QML component loaded')

    # The window is up: the splash process ends
    splash.stdin.close()

    console.debug('Application event loop is about to start')
    if not engine.rootObjects():
        sys.exit(-1)
    exit_code = app.exec()
    # The window goes before the backend singleton: the other way
    # round, on Python's exit, QML bindings read a deleted backend
    del engine
    sys.exit(exit_code)
