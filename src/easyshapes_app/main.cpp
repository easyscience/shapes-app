// SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
// SPDX-License-Identifier: BSD-3-Clause

#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QSurfaceFormat>

#ifdef EASYSHAPES_WEBENGINE
#include <QtWebEngineQuick>
#endif


int main(int argc, char *argv[])
{
#ifdef EASYSHAPES_WEBENGINE
    // Must run before the QGuiApplication is constructed. Only defined for
    // desktop builds configured with CONFIG+=webengine - see the .pro file.
    QtWebEngineQuick::initialize();
#endif

    // Qt Quick clips with the stencil buffer whenever a scissor rectangle is
    // not enough, for instance inside a transform. WebGL gives no stencil
    // attachment unless one is requested, and clipping then fails silently:
    // the collapsed EaElements.GroupBox draws its content outside its own
    // bounds. Must be set before the application is constructed.
    QSurfaceFormat format = QSurfaceFormat::defaultFormat();
    format.setStencilBufferSize(8);
    format.setDepthBufferSize(24);
    QSurfaceFormat::setDefaultFormat(format);

    // Create Qt application
    QGuiApplication app(argc, argv);

    // Needed by the QML Settings elements (EasyApplication Vars/Colors/
    // PreferencesDialog). Without these, Settings warns and never persists.
    // On WebAssembly the values go to the browser IndexedDB store.
    QGuiApplication::setOrganizationName("EasyScience");
    QGuiApplication::setOrganizationDomain("easyscience.software");
    QGuiApplication::setApplicationName("EasyShapes");

    // Title bar and taskbar icon. Nothing in the QML sets one. PNG rather
    // than SVG, so that no QtSvg image plugin has to be linked in.
    // Has no effect on WebAssembly, where there is no window decoration.
    QGuiApplication::setWindowIcon(QIcon(":/Gui/Resources/Logos/App.png"));

    // Create the QML application engine
    QQmlApplicationEngine engine;

    // Add the paths where QML searches for components.
    // Everything is served from the compiled-in resources, since the browser
    // has no file system. Aliases in easyshapes_app.qrc map both the app's
    // own QML (Gui, Backends) and the EasyApplication modules under 'qrc:/'.
    engine.addImportPath("qrc:/");

    // Load the main QML component
    engine.load("qrc:/main.qml");

    // Start the application event loop
    if (engine.rootObjects().isEmpty())
        return -1;
    return app.exec();
}
