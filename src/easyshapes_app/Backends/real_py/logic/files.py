# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path


def export_taken(folder, file=None):
    """
    Whether an export to a folder would replace files: the namesake of
    one file, or for a whole asset (no file) anything in the folder.
    """
    folder = Path(folder)
    if file is not None:
        return (folder / Path(file).name).exists()
    return folder.is_dir() and any(folder.iterdir())
