# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

"""Generate the Qt resource file used by the C++/WebAssembly build.

A browser has no file system, so every QML file, qmldir, font and image
must be compiled into the binary. This script scans the application
sources and the EasyApplication QML modules and writes easyshapes_app.qrc.

Each entry gets an ``alias``, because the resource path is what QML sees
at runtime. main.cpp calls ``addImportPath("qrc:/")``, so the aliases
must reproduce the module layout:

    qrc:/main.qml
    qrc:/Gui/...                  <- import Gui
    qrc:/Backends/...             <- import Backends
    qrc:/EasyApplication/Gui/...  <- import EasyApplication.Gui.*

Without aliases the entries would land under their on-disk paths, such as
``:/../../EasyApp/src/...``, and no import would resolve.

Usage:
    python scripts/gen_qrc.py
    python scripts/gen_qrc.py --easyapp ../../EasyApp/src
    python scripts/gen_qrc.py --fonts referenced
"""

import argparse
import os
import re
import shutil
import sys
from pathlib import Path
from xml.sax.saxutils import quoteattr

# Files worth compiling into the binary. Everything else is skipped, since
# every byte here ends up in the download the reviewer waits for.
INCLUDED_SUFFIXES = {'.qml', '.js', '.ttf', '.otf', '.png', '.svg', '.jpg', '.jpeg', '.gif'}
INCLUDED_NAMES = {'qmldir'}

# Directories skipped wholesale.
EXCLUDED_DIRS = {'__pycache__', '.pixi', '.git'}

# Skipped unless --include-html is given. The Html directory holds the
# Plotly templates and plotly.js, reachable only through QtWebEngine.
# QtWebEngine is Chromium and has no WebAssembly build, so these files are
# dead weight in a browser target but needed by a desktop build that uses
# the EaCharts.Plotly* or EaComponents.BasicReport components.
WEBENGINE_DIRS = {'Html'}

# Same reason, but a single file inside a module that is otherwise used.
# BasicReport.qml imports QtWebEngine, so leaving it in the resource makes
# qmlimportscanner request a module that does not exist for WebAssembly.
# Nothing in shapes-app instantiates EaComponents.BasicReport, and the
# qmldir entry for it is harmless while the file is absent.
WEBENGINE_NAMES = {'BasicReport.qml'}

# Skipped unless --include-charts is given. qmlimportscanner reads the QML
# embedded in the resource and links whatever it imports, so the unused
# EasyApplication.Gui.Charts wrappers would pull in two broken modules:
#   QtCharts     - defines QAbstractAxis, as does QtGraphs. A static build
#                  linking both fails with duplicate symbols
#   QtWebEngine  - required by the Plotly* wrappers, no WebAssembly build
# Nothing in shapes-app imports the module.
CHARTS_DIRS = {'Charts'}

# Individual files skipped. The scratch QML files are not part of the app.
# RemoteController is an EasyApplication automation helper that imports
# QtMultimedia and QtTest; leaving it in makes qmake link both modules into
# the binary. Nothing in shapes-app instantiates it.
EXCLUDED_NAMES = {'test.qml', 'test2.qml', 'RemoteController.qml'}

# Platform icon formats. Nothing in the QML references them.
EXCLUDED_SUFFIXES = {'.ico', '.icns'}


def is_included(path: Path, include_html: bool, include_charts: bool) -> bool:
    """Return True if the file belongs in the resource."""
    if path.name in EXCLUDED_NAMES:
        return False
    if not include_html and path.name in WEBENGINE_NAMES:
        return False
    if path.suffix.lower() in EXCLUDED_SUFFIXES:
        return False
    skipped_dirs = set(EXCLUDED_DIRS)
    if not include_html:
        skipped_dirs |= WEBENGINE_DIRS
    if not include_charts:
        skipped_dirs |= CHARTS_DIRS
    if any(part in skipped_dirs for part in path.parts):
        return False
    if include_html and path.suffix.lower() == '.html':
        return True
    return path.name in INCLUDED_NAMES or path.suffix.lower() in INCLUDED_SUFFIXES


def referenced_fonts(easyapp_dir: Path) -> set[str]:
    """Return the font file names actually loaded by Style/Fonts.qml.

    Fonts.qml loads them as fontPath('PT_Sans', 'PTSans-Regular.ttf'), so
    the second argument of every call is the file name. Roughly a quarter
    of the shipped font files are referenced; the rest are unused weights
    and italics.
    """
    fonts_qml = easyapp_dir / 'EasyApplication' / 'Gui' / 'Style' / 'Fonts.qml'
    if not fonts_qml.is_file():
        sys.exit(f'error: cannot read {fonts_qml}')
    text = fonts_qml.read_text(encoding='utf-8')
    return set(re.findall(r'fontPath\(\s*[\'"][^\'"]+[\'"]\s*,\s*[\'"]([^\'"]+)[\'"]', text))


def collect(
    root: Path,
    alias_prefix: str,
    qrc_dir: Path,
    keep_fonts: set[str] | None,
    include_html: bool,
    include_charts: bool,
) -> list:
    """Collect (alias, path) pairs for every included file under root.

    alias  - where the file appears inside the binary
    path   - where the file sits on disk, relative to the qrc file
    """
    if not root.is_dir():
        sys.exit(f'error: not a directory: {root}')

    entries = []
    for path in sorted(root.rglob('*')):
        if not path.is_file() or not is_included(path, include_html, include_charts):
            continue
        if keep_fonts is not None and path.suffix.lower() in {'.ttf', '.otf'}:
            if path.name not in keep_fonts:
                continue
        alias = path.relative_to(root).as_posix()
        if alias_prefix:
            alias = f'{alias_prefix}/{alias}'
        # Relative paths keep the qrc portable across machines. They do
        # assume the EasyApp repository sits next to shapes-app.
        disk = Path(_relative_to(path, qrc_dir)).as_posix()
        entries.append((alias, disk))
    return entries


def _relative_to(path: Path, start: Path) -> str:
    """Relative path from start to path, allowing '..' segments."""
    return os.path.relpath(path, start)


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    repo_dir = script_dir.parent
    src_dir = repo_dir / 'src'

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--easyapp',
        default='../../EasyApp/src',
        help='directory holding the EasyApplication package, relative to '
        'the generated qrc (default: %(default)s)',
    )
    parser.add_argument(
        '--output',
        default=str(src_dir / 'easyshapes_app.qrc'),
        help='qrc file to write (default: %(default)s)',
    )
    parser.add_argument(
        '--fonts',
        choices=['all', 'referenced'],
        default='all',
        help="'referenced' embeds only the fonts loaded by Fonts.qml, which "
        'cuts several megabytes off the download (default: %(default)s)',
    )
    parser.add_argument(
        '--include-html',
        action='store_true',
        help='embed the QtWebEngine assets (Gui/Html: Plotly templates and '
        'plotly.js). Only useful for a desktop build that instantiates the '
        'EaCharts.Plotly* or EaComponents.BasicReport components, since '
        'QtWebEngine has no WebAssembly build',
    )
    parser.add_argument(
        '--include-charts',
        action='store_true',
        help='embed the EasyApplication.Gui.Charts module. Breaks a '
        'WebAssembly link, since its QtCharts wrappers clash with QtGraphs '
        'over QAbstractAxis, and its Plotly wrappers need QtWebEngine',
    )
    args = parser.parse_args()

    qrc_path = Path(args.output).resolve()
    qrc_dir = qrc_path.parent
    app_dir = (src_dir / 'easyshapes_app').resolve()
    easyapp_dir = (qrc_dir / args.easyapp).resolve()

    keep_fonts = referenced_fonts(easyapp_dir) if args.fonts == 'referenced' else None

    # The application's own QML keeps its layout: main.qml, Gui/, Backends/
    entries = collect(app_dir, '', qrc_dir, keep_fonts, args.include_html, args.include_charts)
    # EasyApplication is aliased under its module name, so that
    # 'import EasyApplication.Gui.Elements' resolves under qrc:/
    entries += collect(
        easyapp_dir / 'EasyApplication',
        'EasyApplication',
        qrc_dir,
        keep_fonts,
        args.include_html,
        args.include_charts,
    )

    lines = ['<RCC>', '    <qresource prefix="/">']
    for alias, disk in entries:
        lines.append(f'        <file alias={quoteattr(alias)}>{disk}</file>')
    lines.append('    </qresource>')
    lines.append('</RCC>')
    content = '\n'.join(lines) + '\n'

    # Keep a one-off copy of whatever was there before, for comparison.
    if qrc_path.is_file():
        backup = qrc_path.with_suffix('.qrc.bak')
        if not backup.is_file():
            shutil.copyfile(qrc_path, backup)
            print(f'saved previous version to {backup}')

    qrc_path.write_text(content, encoding='utf-8')
    print(f'wrote {qrc_path} with {len(entries)} entries')


if __name__ == '__main__':
    main()
