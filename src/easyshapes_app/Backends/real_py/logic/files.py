# SPDX-FileCopyrightText: 2026 EasyScience contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause
"""
Checks before exporting to a folder.
"""

from pathlib import Path


def export_taken(folder, file=None):
    """
    Whether an export to a folder would replace files.

    For one file, that is a file of the same name. For a whole asset (no
    file), it is anything in the folder.
    """
    folder = Path(folder)
    if file is not None:
        return (folder / Path(file).name).exists()
    return folder.is_dir() and any(folder.iterdir())
