# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from PySide6.QtCore import QObject
from PySide6.QtCore import QUrl
from PySide6.QtCore import Slot
from PySide6.QtQml import QQmlComponent
from PySide6.QtQml import QQmlEngine
from PySide6.QtTest import QSignalSpy

from easyshapes_app.Backends.real_py.error import Error


class Failing(QObject):
    @Slot()
    def fail(self):
        raise KeyError('ring')


def test_exception_from_qml_call_reaches_error_message(qcore_application):
    error = Error()
    spy = QSignalSpy(error.messageChanged)
    failing = Failing()
    engine = QQmlEngine()
    engine.rootContext().setContextProperty('failing', failing)
    component = QQmlComponent(engine)
    component.setData(b'import QtQml\nQtObject { Component.onCompleted: failing.fail() }', QUrl())

    component.create()

    assert error.message == "KeyError: 'ring'"
    assert spy.count() == 1
