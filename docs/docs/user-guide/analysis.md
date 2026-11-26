---
icon: fontawesome/solid/microscope
---

# :fontawesome-solid-microscope: Analysis

The Analysis page equilibrates the assembled structure with GROMACS and
calculates its small-angle neutron scattering (SANS) curves.

The sidebar on the right has two tabs:

- **Basic controls** – the equilibration and the scattering calculation.
- **Advanced controls** – their files, the structure viewer's settings
  and the list of curves.

The main area on the left shows **Engine output** (the GROMACS log),
**Structure** (a stage's atoms) and **Scattering** (the curves).

**Continue**, at the bottom of the sidebar, opens the Summary page.

![Analysis page with the Equilibration group](img/analysis-basic-equilibration-light.png#only-light)
![Analysis page with the Equilibration group](img/analysis-basic-equilibration-dark.png#only-dark)

## Basic controls

### Equilibration

The equilibration runs the stages of a configuration one after another.
Stage k runs the configuration's `equil<k>.mdp`, starting where the
stage before ended. Stage eq0 starts from the assembled structure.

- **Configuration** – the `.mdp` files from the asset library, such as
  CHARMM36.
- **Force field** – the force field from the asset library.
- **First stage** – eq0, or a stage after one that has finished.
- **Last stage** – the stage to stop after.
- **Threads** – how many threads mdrun runs on. Empty lets mdrun choose.
- **Restrain to box centre** – anchors the position restraints of the
  structure's components at the centre of the box. Unticked, each
  restrained atom is held where it is when the stage starts. The
  [vesicle tutorial](../tutorials/mlv/index.md#two-ways-to-restrain)
  explains both ways.

**Equilibrate** starts the run. It needs GROMACS (see
[Installation & Setup](../installation-and-setup/index.md)). **Cancel
equilibration** stops it. The Engine output tab shows the progress.

### Scattering

Calculates the SANS curve of a structure. It needs no GROMACS.

- **Structure** – the assembled sample model, or a finished stage of the
  equilibration.
- **Kernel** – **Exact** works for any shape, but can be slow. **Fast**
  can take seconds even for a million atoms, but use it only for round
  aggregates.
- **Solvent SLD, 10⁻⁶ Å⁻²** – the scattering length density of the
  solvent around the aggregate, buffer salts included. H₂O is −0.56, D₂O
  6.36.
- **q min, Å⁻¹** and **q max, Å⁻¹** – the q range of the curve. Both
  above 0, and q min below q max.
- **q points** – how many q values, evenly spaced on a log scale. At
  least 5.
- **Polydispersity** – the spread of aggregate sizes, σ/R. 0 is one
  size. 0.25 puts about 2 in 3 aggregates within ±25 % of the simulated
  size.
- **Deuterate** – tick the components that are deuterated.

**Calculate** starts the calculation, and **Cancel calculation** stops
it. The new curve is added to [Scattering view](#scattering-view).

## Advanced controls

### Configuration Files

The configuration's `.mdp` files, with their sizes. :material-pencil:
opens a file in your system's default app. :material-minus-circle:
removes it. **Add new file(s)**, **Save to lib** and **Export** work as
in the Sample Model page's
[Library assets](sample-model.md#library-assets). Only files named
`equil<k>.mdp` run, each as stage k.

Until the project's first save, the configuration is the asset library's
own copy. Save the project before you edit a file.

![Configuration Files group with the .mdp files](img/analysis-advanced-configuration-files-light.png#only-light)
![Configuration Files group with the .mdp files](img/analysis-advanced-configuration-files-dark.png#only-dark)

### Force Field Files

The same, for the force field's files. Each run uses the force field's
first `.itp` file.

### Equilibration Files

The files of the equilibration and of each finished stage, picked in
**Files of**. The equilibration holds its copies of the model and the
topologies (`toppar/`), and its log. A stage holds the files GROMACS
wrote for it.

- :material-pencil: opens a file in your system's default app.
- **Export** – copies the selected file to a folder, or all the files
  shown when none is selected.
- **Open folder** – opens the folder of the files in your system's file
  browser.

Each **Equilibrate** copies `toppar/` and the model's `.gro` and `.top`
again, so changes to these copies are lost. Edit the components on the
Sample Model page, or the force field, instead.

### Structure viewer

The settings of the Sample Model page's
[Structure viewer](sample-model.md#structure-viewer), for this page's
Structure tab.

### Scattering view

The curves calculated so far, one row each:

- **Curve** – the curve's name, with its colour. Hover over the name to
  see how it was calculated.
- **Status** – done, or outdated once its structure has changed.
- **Rg, Å** – the radius of gyration.
- **Show** – draws the curve in the Scattering tab.
- :material-minus-circle: – removes the curve and its files.

Below the list:

- **Staggered view** – draws each further curve lower, by the decades
  set on the slider, so overlapping curves come apart. Only the chart
  changes.
- **Export data** – writes one `.dat` file per shown curve to a folder.
- **Export as PNG** – saves the Scattering tab's chart and legend as a
  PNG image.

## Main area

### Engine output

A log, picked in **Log** at the top right. **Equilibration** shows each
GROMACS command of the latest run and its output, while it grows. Each
run starts it anew. A finished stage shows its mdrun log.

![Engine output tab with the log of a run](img/analysis-main-engine-output-light.png#only-light)
![Engine output tab with the log of a run](img/analysis-main-engine-output-dark.png#only-dark)

### Structure

A structure, picked in **Stage** at the top right: the equilibration's
copy of the assembled model, or the final structure of a finished stage.
The [Structure viewer](#structure-viewer) group sets the slab and the
look. The mouse controls are those of the Sample Model page.

![Structure tab with an SDS ball after eq1](img/analysis-main-structure-light.png#only-light)
![Structure tab with an SDS ball after eq1](img/analysis-main-structure-dark.png#only-dark)

### Scattering

The curves ticked **Show** in Scattering view: I(q) in cm⁻¹ against q in
Å⁻¹, both on log scales. The buttons at the top right show or hide the
legend, show the values under the cursor, switch on pan or box zoom, and
reset the axes. A right-click on the chart also resets them.

![Scattering tab with two curves](img/analysis-main-scattering-light.png#only-light)
![Scattering tab with two curves](img/analysis-main-scattering-dark.png#only-dark)
