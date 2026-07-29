TEMPLATE = app

# Application name. On WebAssembly this also names the output files:
# easyshapes_app.html, easyshapes_app.js, easyshapes_app.wasm
TARGET = easyshapes_app

CONFIG += c++17

# Qt modules linked into the binary. On WebAssembly everything is linked
# statically, so a module missing here is simply absent at runtime:
#   quick3d - Gui/Pages/SampleModel/MainArea/BaseMol3dQuick.qml
#   graphs  - Gui/Pages/Analysis/MainArea/Chart.qml, GraphsView.qml
QT += core quick qml quick3d graphs

# Opt-in QtWebEngine support, needed by the EaCharts.Plotly* and
# EaComponents.BasicReport components:
#   qmake easyshapes_app.pro CONFIG+=webengine
#   python scripts/gen_qrc.py --include-html
# QtWebEngine is Chromium. It has no WebAssembly build and never will, and
# on Windows it is built for MSVC only - not for MinGW.
webengine {
    wasm {
        error('CONFIG+=webengine is not possible on WebAssembly: QtWebEngine has no wasm build')
    }
    QT += webenginequick
    DEFINES += EASYSHAPES_WEBENGINE
}

SOURCES += \
    easyshapes_app/main.cpp

# Embeds all QML, qmldir, fonts and images, since the browser has no file
# system. Generated - see scripts/gen_qrc.py.
RESOURCES += easyshapes_app.qrc

# Location of the EasyApplication QML modules. Defaults to the EasyApp repo
# checked out next to shapes-app. Override on the command line:
#   qmake easyshapes_app.pro EASYAPP_DIR=/path/to/EasyApp/src
isEmpty(EASYAPP_DIR): EASYAPP_DIR = $$PWD/../../EasyApp/src

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH += \
    $$PWD/easyshapes_app \
    $$EASYAPP_DIR

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH += \
    $$PWD/easyshapes_app \
    $$EASYAPP_DIR
