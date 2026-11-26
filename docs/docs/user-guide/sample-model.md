---
icon: fontawesome/solid/vial
---

# :fontawesome-solid-vial: Sample Model

The Sample Model page defines what to build: the structure's shape, its
components (molecules), how they are arranged, and the buffer around
them. **Assemble** then builds the structure's coordinates with
Shapespyer.

The sidebar on the right has two tabs:

- **Basic controls** – what to build.
- **Advanced controls** – the files behind it: the asset library, the
  components' files, the assembled model's files, the SMILES generator
  and the structure viewer's settings.

The main area on the left shows the model: **Shape** (a sketch of the
structure), **Components** (each molecule in 3D) and **Structure** (the
assembled atoms). A lattice model adds a **Lattice** tab.

**Continue**, at the bottom of the sidebar, opens the Analysis page.

![Sample Model page of a new project](img/sample-model-basic-model-definition-light.png#only-light)
![Sample Model page of a new project](img/sample-model-basic-model-definition-dark.png#only-dark)

## Basic controls

### Model Definition

One row for the project's sample model:

- **Name** – the model's name. The name matters when you save the model
  to the asset library or load it from there.
- **Type** – **Discrete** builds one structure. **Lattice** repeats it
  on a lattice and shows the [Lattice Parameters](#lattice-parameters)
  group. Switching back to Discrete drops the lattice settings.
- **Shape** – Ring, Ball, Vesicle, Rod, Bilayer or Monolayer. A new
  shape keeps the components, but its structure settings start from the
  defaults.

Below the row:

- **Load model** – replaces the model with one saved in the asset
  library.
- **Import model** – replaces the model with one from a folder, for
  example one a colleague exported with
  [Sample Model Files](#sample-model-files) › **Export**.

### Components

The molecules the structure is made of. One row per component:

- **Name** – a unique name, the residue name in the component's
  structure file.
- **Type** – Lipid, Surfactant or Component. Set in the asset library.
- **C-ion** – the counter-ion that goes with each molecule, from the
  ions in the asset library. Empty for none.
- **Mint** and **Mext** – the indices of two atoms of the molecule,
  counted from 0. The line from Mint to Mext, its "bone", sets how the
  molecule is placed: Mint points into the structure, Mext out of it.
  Hover over an atom in the main area's [Components](#components_1) tab
  to see its index.
- :material-minus-circle: – removes the component from the project. The
  asset library and the files on disk keep it.

Below the table:

- **Load component(s)** – adds one or more components from the asset
  library.
- **Import component** – adds a component from a folder, for example one
  exported with [Components Files](#components-files) › **Export**.

![Components of a vesicle, with the molecules drawn in the Shape tab](img/sample-model-basic-components-light.png#only-light)
![Components of a vesicle, with the molecules drawn in the Shape tab](img/sample-model-basic-components-dark.png#only-dark)

### Fractions

A **Fractions** table says how much of each component goes into a part
of the structure. Ring, Rod, Bilayer and Monolayer have one, in their
structure group. A ball has one per layer, and a vesicle one per lamella
or leaflet. One row per component:

- **Present** – tick to place the component here.
- **Component name** – the name from the Components group.
- **Mole ratio** – 0 or more. Ratios are relative: 70 and 30 give the
  same mix as 7 and 3.

### Structure definition

Each shape has its own **… Structure Definition** group. Distances are
in nm, angles in degrees. A value that can't be built turns red.

Several shapes share these controls:

- **Dmin** – the smallest distance between the bones of neighbouring
  molecules.
- **Rmin** – the radius of the empty space in the middle.
- **Fxz** – first flattens each molecule into the XZ plane, so it
  spreads less along Y.
- **Rev** – swaps Mint and Mext, so the molecules point the other way.
- **Fill** (Ball and Vesicle) – how the molecules cover the sphere.
  **FIBO** spreads them evenly along a Fibonacci spiral. **RINGS0**
  places them on rings of latitude, the same above and below the
  equator. **RINGS** also uses rings of latitude, often denser, but not
  always the same above and below.

#### Ring

One ring of molecules. Dmin, Rmin, Fxz and Rev, plus:

- **Alpha** – the starting angle of the molecules in the XY plane,
  0–360°.
- **Theta** – their tilt from the Z axis, 0–180°.
- **Ring Fractions**.

Rmin must be at least half of Dmin, or it turns red.

#### Ball

A sphere of one or more [layers](#layers). Fill, Fxz and Rev, plus
**Full radius**, the radius of the whole ball.

![Ball Structure Definition of a lattice of balls](img/sample-model-basic-ball-structure-light.png#only-light)
![Ball Structure Definition of a lattice of balls](img/sample-model-basic-ball-structure-dark.png#only-dark)

#### Vesicle

A sphere of one or more [lamellae](#lamellae), each a bilayer. Fill, Fxz
and Rev, plus **Full radius**, the radius of the whole vesicle.

![Vesicle Structure Definition of a vesicle with two lamellae](img/sample-model-basic-vesicle-structure-light.png#only-light)
![Vesicle Structure Definition of a vesicle with two lamellae](img/sample-model-basic-vesicle-structure-dark.png#only-dark)

#### Rod

A stack of rings with a half-sphere cap at each end. Dmin, Rmin, Fxz and
Rev, plus:

- **Turns** – how many rings are stacked, Dmin apart.
- **Rod Fractions**.

Rmin must be at least 1.6 times Dmin, or it turns red.

#### Bilayer

A flat, square patch of two leaflets:

- **Zsep** – the distance between the two leaflets' Mext atoms. At 0,
  their Mint atoms are placed Dmin apart instead.
- **Nside** – how many molecules along each side of the square. The
  patch is Nside × Dmin wide.
- **Dmin**.
- **Bilayer Fractions**.

#### Monolayer

The same controls as Bilayer, but the molecules point the other way: the
two sheets face each other with their Mext atoms, Zsep apart (Dmin apart
at 0).

### Layers

Shown for a ball. One row per layer, from the inside out:

- **Dmin, nm** – the smallest distance between molecules in the layer.
- **Rmin, nm** – the layer's inner radius.
- **Thickness, nm** – the length of the longest molecule in the layer.
- :material-minus-circle: – removes the layer.

Rmin must be at least 1.6 times Dmin, or both turn red: Shapespyer can't
build that. **Add layer** adds one. Select a row to set its fractions
below the table.

![Layers of an SDS ball](img/sample-model-basic-layers-light.png#only-light)
![Layers of an SDS ball](img/sample-model-basic-layers-dark.png#only-dark)

### Lamellae

Shown for a vesicle. One row per lamella, from the inside out:

- **Rmin, nm** – the lamella's inner radius.
- **Inner dmin, nm** and **Outer dmin, nm** – the smallest distance
  between molecules in the inner and in the outer leaflet.
- **Shell thickness, nm** – from Rmin to the end of the outer leaflet.
  It is set from the molecules when you add the lamella, and you can
  change it. A thin shell crowds the leaflets.
- **Symmetric** – both leaflets have the same fractions. Untick it to
  set the outer leaflet's fractions on their own.
- :material-minus-circle: – removes the lamella.

Each leaflet's radius must be at least 1.6 times its dmin, or its cells
turn red. **Add lamella** adds one. Select a row to set its fractions
below the table.

![Lamellae of a vesicle with two lamellae](img/sample-model-basic-lamellae-light.png#only-light)
![Lamellae of a vesicle with two lamellae](img/sample-model-basic-lamellae-dark.png#only-dark)

### Lattice Parameters

Shown when the model's Type is Lattice. The structure is one unit, and
the lattice repeats it:

- **Alpha** and **Theta** – turn every unit: Alpha about the Z axis
  (0–360°), Theta up from the XY plane (0–180°).
- **Sbuff** – the space between neighbouring units, in nm.
- **Type** – **LCUB** simple cubic, **LBCC** body-centred cubic,
  **LFCC** face-centred cubic, or **LHCP** hexagonal close packing.
- **Nlatx**, **Nlaty**, **Nlatz** – how many cells along X, Y and Z.

![Lattice Parameters of a lattice of balls](img/sample-model-basic-lattice-parameters-light.png#only-light)
![Lattice Parameters of a lattice of balls](img/sample-model-basic-lattice-parameters-dark.png#only-dark)

### Buffer

What surrounds the structure:

- **Solvent** – a solvent from the asset library, such as TIP3 water.
  Empty for none.
- **Buffer Components** – the salts in the solvent, with their
  **Concentration, mM**. :material-minus-circle: removes one.
- **Load components** – adds one or more salts from the asset library.
- **Import components** – adds them from a folder.

The online asset library has no salts yet. To make one, such as NaCl
from the ions NAT and CLA, use [Library assets](#library-assets) ›
**Create new** with the type Salt.

![Buffer of an SDS ball in water](img/sample-model-basic-buffer-light.png#only-light)
![Buffer of an SDS ball in water](img/sample-model-basic-buffer-dark.png#only-dark)

### Assemble

**Assemble**, below the groups, builds the structure with Shapespyer. It
runs in the background, and the main area switches to the
[Structure](#structure) tab. **Cancel assembly** stops it.

Adding a solvent, salts or counter-ions needs GROMACS. The status bar
shows whether the app has found it (see
[Installation & Setup](../installation-and-setup/index.md)). A dry
structure assembles without it.

Big structures take time: a vesicle of about 1.8 million atoms takes a
few minutes on a laptop.

## Advanced controls

### Library assets

The asset library holds what the **Load** buttons in Basic controls
offer. This group creates and changes its entries:

- **Create new** – starts a new asset.
- **Load from lib** – opens an asset from the library to change it.
- **Type** – Lipid, Surfactant, Component, Ion, Solvent or Salt.
- **Name** – the asset's name in the library.
- **C-ion**, **Mint**, **Mext** – for Lipid, Surfactant and Component,
  as in the [Components](#components) group. They are the defaults a
  loaded component starts with.
- **Salt composition** – for a Salt, instead of files: the **Cation**
  and the **Anion**, from the library's ions, and how many of each
  (**Count**).
- The files of the asset, with their **Path** and **Size**.
  :material-pencil: opens a file in your system's default app for its
  type. :material-minus-circle: removes it from the asset.
- **Add new file** – adds files from disk: structure files (.gro, .pdb,
  .xyz), topology files (.itp, .top) or SMILES files (.sml).
- **Save to lib** – saves the asset to the library. Components already
  in the project don't change. Load them again to use the new version.
- **Export** – copies the selected file to a folder, or the whole asset
  when no file is selected.

![Library assets group](img/sample-model-advanced-library-assets-light.png#only-light)
![Library assets group](img/sample-model-advanced-library-assets-dark.png#only-dark)

### Components Files

The same as Library assets, but for the components in the project:

- **Select component** – one of the components in Basic controls.
- **Name** – renames it, with the same checks as the Components table.
- **Add new component** – adds an empty component. Rename it, then add
  its files.
- The component's files, with :material-pencil: and
  :material-minus-circle: as in Library assets.
- **Add new file(s)**, **Save to lib** and **Export** – as in Library
  assets, for the selected component.

Until the project's first save, a component loaded from the asset
library still uses the library's files. :material-pencil: would then
change the library's own copy, which every new project uses. Save the
project before you edit a file.

![Components Files group](img/sample-model-advanced-components-files-light.png#only-light)
![Components Files group](img/sample-model-advanced-components-files-dark.png#only-dark)

### Sample Model Files

The sample model's own files, such as the assembled structure, with
their sizes:

- :material-pencil: opens a file in your system's default app.
  :material-minus-circle: removes it from the model.
- **Add new file(s)** – adds files from disk.
- **Save to lib** – saves the model, with its components and buffer, to
  the asset library.
- **Export** – copies the model, with its components and buffer, to a
  folder. **Import model** in Basic controls reads such a folder.

![Sample Model Files of an assembled vesicle](img/sample-model-advanced-sample-model-files-light.png#only-light)
![Sample Model Files of an assembled vesicle](img/sample-model-advanced-sample-model-files-dark.png#only-dark)

### SMILES generator

Builds a component from a SMILES string:

- **Name** – the residue name, up to 5 letters or digits.
- **Formula** – optional.
- **SMILES** – the molecule, for example `CCCCCCCCCCCCOS(=O)(=O)[O-]`
  for the dodecyl sulfate ion of SDS.
- **Box** (**Lx**, **Ly**, **Lz**) – the box size of the structure file,
  in nm.
- **Cis C=C** – makes C=C double bonds cis instead of trans.
- **Align Z** – turns the molecule so a bond at one of its ends lies
  along Z.
- **Flatten XZ** – flattens the aligned molecule into the XZ plane. Only
  with Align Z.
- **Type** – Lipid, Surfactant or Component.
- **Format** – the structure file's format, .gro or .pdb.
- **Generate** – builds the structure file and adds the new component to
  the project. Then set its Mint and Mext in the Components group. To
  save or share it, use [Components Files](#components-files).

![SMILES generator group](img/sample-model-advanced-smiles-generator-light.png#only-light)
![SMILES generator group](img/sample-model-advanced-smiles-generator-dark.png#only-dark)

### Structure viewer

Settings for the main area's [Structure](#structure) tab:

- **Background** – Theme, Black, White or Grey 50%.
- **Slab plane** – the plane the slab lies in: YZ, XZ or XY.
- **Lighting** – Default, Volumetric, Vol-tint, Hygge or Outline.
- **Slab thickness** – how much of the structure is shown, as a share of
  its size across the slab plane.
- **Continuous update** – cuts the slab while the slider moves. This is
  slow for millions of atoms.
- **Keep structure loaded** – when off, the structure is read again each
  time the Structure tab opens, and the slab starts at 5 %.
- **Show bonds** – draws the bonds between atoms, from the components'
  .itp files. This takes about three times the graphics memory of the
  atoms alone.
- **Residue** list – untick a residue to hide its atoms.

## Main area

The 3D views (Components, Structure and Lattice) take the same mouse
controls: drag with the left button to turn, drag with the right button
to move, and use the wheel to zoom.

### Shape

A sketch of the structure from its current settings, drawn without
assembling it. Each component's bone is an arrow from Mint to Mext,
spaced Dmin apart along the structure:

- Ring and Rod – one ring.
- Ball – one ring per layer.
- Vesicle – two leaflets per lamella, with the shell.
- Bilayer and Monolayer – two flat leaflets.

The lower left shows the whole unit with its sizes. The tick boxes at
the top add **Component names**, **Dimensions** (the distances and
radii), and **Molecules** (each molecule drawn along its bone). The
pictures in Basic controls above show this tab next to each group.

### Components

One component in 3D, picked in the **Component** list at the top right.
A gold arrow goes from its Mint atom to its Mext atom, both labelled.
Hover over an atom to see its index and element. Click it to keep the
label. The index counts from 0, as Mint and Mext do. A topology (`.itp`)
file counts atoms from 1.

![Components tab showing POPC, with its phosphorus labelled](img/sample-model-main-components-light.png#only-light)
![Components tab showing POPC, with its phosphorus labelled](img/sample-model-main-components-dark.png#only-dark)

### Structure

The assembled structure, atom by atom, cut to a slab. The
[Structure viewer](#structure-viewer) group sets the slab and the look.
While an assembly runs, this tab shows its progress.

![Structure tab with an assembled vesicle](img/sample-model-main-structure-light.png#only-light)
![Structure tab with an assembled vesicle](img/sample-model-main-structure-dark.png#only-dark)

### Lattice

Shown when the model's Type is Lattice. Each unit of the lattice is a
simple shape: a disc for a ring, a sphere for a ball or a vesicle, a
pill for a rod, and a box for a bilayer or a monolayer.

![Lattice tab with a lattice of balls](img/sample-model-main-lattice-light.png#only-light)
![Lattice tab with a lattice of balls](img/sample-model-main-lattice-dark.png#only-dark)
