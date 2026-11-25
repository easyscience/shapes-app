---
icon: material/archive
---

# :material-archive: Project

A project holds everything you make in EasyShapes: the sample model, its
assembled structure, and the analysis with its equilibration and
scattering results. Each project is a folder on disk.

**Start** on the Home page opens this page.

![Project page with a new project](img/project-description-light.png#only-light)
![Project page with a new project](img/project-description-dark.png#only-dark)

## Basic controls

### Get started

- **Create a new project** – opens the Create project dialog (below).
- **Open an existing project** – opens a project folder.

Creating or opening a project replaces the open one without asking, so
save your work first. The whole Project tab is off while an assembly,
equilibration or scattering calculation runs.

The **Create project** dialog has three fields. All are optional:

- **Name** – starts with a letter, then 1–30 letters, digits, `_`, `-`
  or `.`. Empty gives a random name.
- **Description** – a short note about the project.
- **Location** – the folder to save the project in.
  :material-folder-open: picks one. It must be new or empty: otherwise
  it turns red and **OK** stays off. Empty saves to
  `Projects/<name>-<ID>` in Shapespyer's data folder (see
  [Installation & Setup](../installation-and-setup/index.md) for where
  it is).

The new project is written to disk at its first save.

![Create project dialog](img/project-create-dialog-light.png#only-light)
![Create project dialog](img/project-create-dialog-dark.png#only-dark)

### Examples

Ready-made projects to start from. Click one to open it. Saving it saves
a copy in the default projects folder, and the example stays as it is.

### Recent projects

The projects you have saved, newest first, each with the time of its
last save. Hover over one to see its folder; click it to open it.
Examples don't appear here.

## Description tab

The open project:

- **Name** – the large title. Click it to change it, with the same rule
  as in the Create project dialog.
- **Description** – click it to change it.
- **Location** – the project's folder. A long path loses its start;
  hover over it to see all of it.
- **Last saved** – empty until the first save.

Without a project, the page shows "No project defined".

## Saving

:material-content-save: at the top left of the window, or Ctrl+S, saves
the project into its folder. The first save creates the folder and adds
the project to Recent projects. Saving is off while an assembly,
equilibration or scattering calculation runs.

## Continue

**Continue** opens the Sample Model page. An opened project also unlocks
the Analysis page at once.

Without a project, the button reads **Continue without project**. You
can build a sample model then, but not save it. The first project you
create afterwards takes it in.
