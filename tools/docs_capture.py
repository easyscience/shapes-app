# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
Screenshots of the app for the docs. Run from the shapes-app folder:

    pixi run python tools/docs_capture.py OUTPUT_DIR

The app runs with the Python backend, in a 1280 x 800 window, once in
the light and once in the dark theme. Its settings and projects go to a
scrap folder that is deleted at the end, as is what its assemblies leave
in shapespyer's Temp. Close EasyShapes first: Temp folders it makes during
the run would be deleted too.

The assembled vesicle is made once, before any app window opens, and
kept in CACHE_DIR (easyshapes-docs-cache in the system's temp folder)
between runs; delete it after changing build_mlv.
"""

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import EasyApplication
from PySide6.QtCore import Q_ARG, QEventLoop, QMetaObject, QObject, QPointF, QRectF, QTimer, QUrl
from PySide6.QtGui import QColor, QGuiApplication, QPainter, QPen, QVector3D
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent, qmlRegisterSingletonType

APP_DIR = Path(__file__).resolve().parents[1] / 'src' / 'easyshapes_app'
EASYAPP_DIR = Path(EasyApplication.__path__[0]).resolve().parent
WIDTH, HEIGHT = 1280, 800
# EaStyle.Colors.Themes: LightTheme = 0, DarkTheme = 1
THEMES = {'light': 0, 'dark': 1}
# The docs site's orange, for the boxes in tutorial shots
BOX_COLOR = '#FF9800'
# Assembled examples, kept between runs: assembling takes minutes.
# shortcut: changes to an example don't reach its copy here, delete it
# by hand then; key the copies by a hash of the examples if that bites
CACHE_DIR = Path(tempfile.gettempdir()) / 'easyshapes-docs-cache'
# The Project scene's folder: never created, as the project is never
# saved, and with no user name in it, unlike a Temp path
PROJECT_LOCATION = str(Path(Path.home().anchor, 'Projects', 'POPC-vesicle'))

# main.py's own imports: Backends and Gui sit in the app folder
sys.path.insert(0, str(APP_DIR))

# Drives the app through the calls its own buttons make
DRIVER_QML = b"""
import QtQuick
import EasyApplication.Gui.Globals as EaGlobals
import Gui.Globals as Globals

QtObject {
    readonly property var tabs: Globals.References.applicationWindow.appBarCentralTabs
    // True while the Structure tab reads its atoms; why the read failed
    readonly property bool busy: Globals.BackendWrapper.structureViewLoading
    readonly property string error: Globals.BackendWrapper.structureViewError

    // A new project with its tabs enabled, as Home's Start and the
    // Project page's Continue leave them
    function createProject(name, description, path) {
        Globals.BackendWrapper.projectCreate(name, description, path)
        tabs.projectButton.opened = true
        tabs.sampleModelButton.enabled = true
    }
    // A saved project, whose Sample Model and Analysis tabs open at once
    function loadProject(path) {
        Globals.BackendWrapper.projectLoad(path)
        tabs.projectButton.opened = true
    }
    // toggle() would close a tab that is already open
    function openTab(name) { if (!tabs[name].checked) tabs[name].toggle() }
    // The Create project dialog, as Get started's first button opens it
    function showCreateDialog(shown) { EaGlobals.Vars.showProjectDescriptionDialog = shown }
}
"""


def call(driver, name, *args):
    """
    Call one of the driver's functions.
    """
    QMetaObject.invokeMethod(driver, name, *(Q_ARG('QVariant', arg) for arg in args))


def wait(ms):
    """
    Let the app run for a while, so pages load and views render.
    """
    loop = QEventLoop()
    QTimer.singleShot(ms, loop.quit)
    loop.exec()


def wait_until_idle(driver, limit_s=120):
    """
    Let the app run until the Structure tab has read its atoms. Raises
    the tab's error message if the read failed, and TimeoutError after
    limit_s seconds.
    """
    for _ in range(limit_s * 2):
        wait(500)
        if not driver.property('busy'):
            if driver.property('error'):
                raise RuntimeError(driver.property('error'))
            return
    raise TimeoutError(f'Reading the structure took longer than {limit_s} s')


def build_lattice_ball(path):
    """
    Save the interface page's lattice scene to a folder: a ball of SDS
    on a body-centred cubic lattice of 3 x 2 x 4 cells.
    """
    from shapes.project import Ball, Ion, Lattice, Project, SampleModel, Surfactant
    from shapes.project.species import Buffer, Components, Solvent

    sds = Surfactant.load('SDS')
    sds.counter_ion = Ion.load('NAT')
    ball = Ball(name='SDSBall', components=Components(items=[sds]))
    lattice = Lattice(motif=ball, lattice_type='LBCC', nlatx=3, nlaty=2, nlatz=4)
    project = Project(
        path=path,
        title='Lattice ball',
        sample_model=SampleModel(
            name='SDSBall',
            structure=lattice,
            buffer=Buffer(name='Water', solvent=Solvent.load('TIP3')),
        ),
        is_example=True,
    )
    project.save()
    return project


def find_item(window, accept, what):
    """
    The first item on screen that accept(item) takes. Hidden items are
    skipped with everything in them. Pages slid aside, such as the other
    tabs' pages, stay visible but lie outside the window, so an item
    counts only when its centre is inside it. Raises LookupError naming
    what was looked for.
    """
    pending = [window.contentItem()]
    while pending:
        item = pending.pop()
        if not item.isVisible():
            continue
        centre = item.mapToScene(QPointF(item.width() / 2, item.height() / 2))
        inside = 0 <= centre.x() < window.width() and 0 <= centre.y() < window.height()
        if inside and accept(item):
            return item
        pending.extend(item.childItems())
    raise LookupError(f'No {what} on screen')


def expand_group(window, title):
    """
    Open the sidebar group with this title, as a click on its header
    does: the other groups of its page close. Returns the group.
    """
    group = find_item(
        window,
        lambda item: item.property('title') == title and item.property('collapsed') is not None,
        f'sidebar group titled {title!r}',
    )
    group.setProperty('collapsed', False)
    return group


def click_tab(window, text):
    """
    Open the visible tab with this label, as a click on it does.
    Returns the tab.
    """
    tab = find_item(
        window,
        lambda item: item.property('text') == text and 'TabButton' in item.metaObject().className(),
        f'tab {text!r}',
    )
    # toggle() would close a tab that is already open
    if not tab.property('checked'):
        QMetaObject.invokeMethod(tab, 'toggle')
    return tab


def set_checked(window, text, checked):
    """
    Tick or untick the visible tick box with this label.
    """
    box = find_item(
        window,
        lambda item: item.property('text') == text and 'CheckBox' in item.metaObject().className(),
        f'tick box {text!r}',
    )
    box.setProperty('checked', checked)


def tilt_structure(window):
    """
    Turn the visible structure viewer 45° up from below and 45° about
    the vertical axis, as a drag on it would.
    """
    view = find_item(
        window,
        lambda item: item.inherits('QQuick3DViewport')
        and item.findChild(QObject, 'structureOrigin') is not None,
        'structure viewer',
    )
    origin = view.findChild(QObject, 'structureOrigin')
    origin.setProperty('eulerRotation', QVector3D(45, 45, 0))


def draw_boxes(image, items):
    """
    Draw an orange box around each of these items on a grab of the
    window.
    """
    # The grab keeps the screen's scale, so the painter takes window
    # coordinates
    painter = QPainter(image)
    painter.setRenderHint(QPainter.Antialiasing)
    painter.setPen(QPen(QColor(BOX_COLOR), 3))
    # A full-width group's margin would run past the window's edge
    inside = QRectF(2, 2, image.width() / image.devicePixelRatio() - 4,
                    image.height() / image.devicePixelRatio() - 4)
    for item in items:
        box = item.mapRectToScene(QRectF(0, 0, item.width(), item.height()))
        painter.drawRoundedRect(box.adjusted(-4, -4, 4, 4).intersected(inside), 4, 4)
    painter.end()


def temp_entries():
    """
    The folders in shapespyer's Temp, where assemblies and calculations
    work until a project is saved.
    """
    from shapes.project.files import AppFileManager

    return set((AppFileManager().app_path / 'Temp').glob('*/*'))


def main(output_dir, theme):
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    scrap = Path(tempfile.mkdtemp(prefix='easyshapes-docs-'))
    temp_before = temp_entries()
    try:
        from Backends.real_backend import Backend
        from Backends.real_py.logic.examples import build_mlv, build_sds_ball

        qmlRegisterSingletonType(Backend, 'Backends', 1, 0, 'PyBackend')
        app = QGuiApplication(sys.argv)  # noqa: F841 - must live while the window does
        engine = QQmlApplicationEngine()
        # The app reads its theme from the settings at start, so every
        # view is in it from the first frame (EasyApp Colors.qml:141-144).
        # The Shape view starts with its dimensions shown (Shape.qml:198-204)
        settings_file = scrap / 'settings.ini'
        settings_file.write_text(
            f'[Preferences.Appearance]\ntheme={THEMES[theme]}\n'
            '\n[SampleModel.Shape]\nshowDimensions=true\n'
        )
        settings = QUrl.fromLocalFile(str(settings_file)).toString()
        engine.rootContext().setContextProperty('pySettingsPath', settings)
        engine.addImportPath(str(APP_DIR))
        engine.addImportPath(str(EASYAPP_DIR))
        engine.load(APP_DIR / 'main.qml')
        if not engine.rootObjects():
            raise RuntimeError('main.qml did not load')
        window = engine.rootObjects()[0]

        component = QQmlComponent(engine)
        component.setData(DRIVER_QML, QUrl())
        driver = component.create()
        if driver is None:
            raise RuntimeError(component.errorString())

        basic, advanced = 'Basic controls', 'Advanced controls'
        # Each page's tab in the app bar, by its name in the file names
        page_tabs = {
            'project': 'projectButton',
            'sample-model': 'sampleModelButton',
            'analysis': 'analysisButton',
        }
        # Each scene: how it is made, the page it shows, and its shots:
        # name, sidebar tab, group to open (None: as the page shows it),
        # main-area tab, and for a tutorial a copy with boxes: its name
        # and the labels of the controls to box. A builder saves a
        # scene, which is then loaded; a name, a description and a
        # folder create one in the app. The Project scene comes first,
        # while the page still shows only Get started: Recent projects
        # lists your own
        scenes = {
            'project': (
                ('POPC-vesicle', 'Dry POPC and cholesterol, two lamellae.', PROJECT_LOCATION),
                'project',
                [
                    ('description', basic, None, 'Description'),
                    ('create-dialog', basic, None, 'Description'),
                ],
            ),
            'empty': (('', '', str(scrap / 'empty')), 'sample-model', [
                ('basic-model-definition', basic, None, 'Shape'),
            ]),
            'mlv-assembled': (
                lambda path: shutil.copytree(CACHE_DIR / 'MLV', path),
                'sample-model',
                [
                    ('main-structure', advanced, 'Structure viewer', 'Structure',
                     ('tutorial-mlv-structure', ['Structure'])),
                    ('advanced-sample-model-files', advanced, 'Sample Model Files', 'Structure'),
                ],
            ),
            'mlv': (build_mlv, 'sample-model', [
                ('basic-components', basic, 'Components', 'Shape',
                 ('tutorial-mlv-components', ['Load component(s)'])),
                ('basic-vesicle-structure', basic, 'Vesicle Structure Definition', 'Shape'),
                ('basic-lamellae', basic, 'Lamellae', 'Shape',
                 ('tutorial-mlv-lamellae', ['Add lamella'])),
                ('advanced-library-assets', advanced, 'Library assets', 'Shape'),
                ('advanced-components-files', advanced, 'Components Files', 'Shape',
                 ('tutorial-mlv-components-files', ['Select component'])),
                ('advanced-smiles-generator', advanced, 'SMILES generator', 'Shape'),
                ('main-components', basic, 'Components', 'Components',
                 ('tutorial-mlv-atoms', ['19 (P)'])),
            ]),
            # Engine output: a tab named Structure would be tilted and
            # waited on, and Scattering has nothing to show before a run
            'mlv-analysis': (build_mlv, 'analysis', [
                ('basic-equilibration', basic, 'Equilibration', 'Engine output',
                 ('tutorial-mlv-equilibration', ['Restrain to box centre'])),
                ('advanced-configuration-files', advanced, 'Configuration Files', 'Engine output'),
            ]),
            'sds-ball': (build_sds_ball, 'sample-model', [
                ('basic-layers', basic, 'Layers', 'Shape'),
                ('basic-buffer', basic, 'Buffer', 'Shape'),
            ]),
            'lattice-ball': (build_lattice_ball, 'sample-model', [
                ('basic-ball-structure', basic, 'Ball Structure Definition', 'Shape'),
                ('basic-lattice-parameters', basic, 'Lattice Parameters', 'Shape'),
                ('main-lattice', basic, 'Lattice Parameters', 'Lattice'),
            ]),
        }
        for scene, (build, page, shots) in scenes.items():
            if callable(build):
                path = str(scrap / scene)
                build(path)
                call(driver, 'loadProject', path)
            else:
                call(driver, 'createProject', *build)
            call(driver, 'openTab', page_tabs[page])
            wait(1000)
            for name, sidebar, group, main_tab, *boxed in shots:
                # Every shot the same size, even if the window was resized
                window.setWidth(WIDTH)
                window.setHeight(HEIGHT)
                click_tab(window, sidebar)
                tab = click_tab(window, main_tab)
                wait(1000)
                # The part the User Guide describes with this shot: the
                # main-area tab, or else the sidebar group it opens
                parts = [tab] if name.startswith('main-') else []
                if group is not None:
                    opened = expand_group(window, group)
                    parts = parts or [opened]
                if main_tab == 'Shape':
                    # Mint and Mext are read against the molecules
                    set_checked(window, 'Molecules', name == 'basic-components')
                if main_tab == 'Structure':
                    tilt_structure(window)
                    # The tab reads its atoms when it opens
                    wait_until_idle(driver)
                if name == 'main-components':
                    # POPC's phosphorus labelled, as a click on it does:
                    # the tutorial's "19 (P)"
                    viewer = find_item(
                        window,
                        lambda item: item.property('_pinnedIndex') is not None,
                        'component viewer',
                    )
                    viewer.setProperty('_pinnedIndex', 19)
                if name == 'create-dialog':
                    call(driver, 'showCreateDialog', True)
                wait(2500)
                image = window.grabWindow()
                # The tutorial's copy gets its own boxes, not the page's
                plain = image.copy()
                draw_boxes(image, parts)
                image.save(str(output_dir / f'{page}-{name}-{theme}.png'))
                for boxed_name, labels in boxed:
                    controls = [
                        # The outermost match: a button, not its text
                        find_item(
                            window,
                            lambda item, label=label: label
                            in (item.property('text'), item.property('title')),
                            f'control labelled {label!r}',
                        )
                        for label in labels
                    ]
                    draw_boxes(plain, controls)
                    plain.save(str(output_dir / f'{boxed_name}-{theme}.png'))
                # Closed again, or it would cover every later shot
                if name == 'create-dialog':
                    call(driver, 'showCreateDialog', False)

        # The window goes before the backend singleton, as in main.py
        del driver, component, engine
    finally:
        shutil.rmtree(scrap, ignore_errors=True)
        # Only what this run made: the user's own work in Temp stays
        for entry in temp_entries() - temp_before:
            if entry.is_dir():
                shutil.rmtree(entry, ignore_errors=True)
            else:
                entry.unlink(missing_ok=True)


if __name__ == '__main__':
    output_dir, *theme = sys.argv[1:]
    if theme:
        main(output_dir, theme[0])
    else:
        from Backends.real_py.logic.examples import make_examples

        # Here, with no window: assembling takes minutes, and a window
        # kept busy that long stops answering
        make_examples(CACHE_DIR, ['MLV'], assemble=True)
        # One app per theme: a status bar value keeps the colour of the
        # theme it last changed in (EasyApp StatusBarItem.qml:81-84)
        for name in THEMES:
            subprocess.run([sys.executable, __file__, output_dir, name], check=True)
