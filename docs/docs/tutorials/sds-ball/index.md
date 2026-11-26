# SDS Ball (Micelle)

## The goal

Build a ball of SDS (sodium dodecyl sulfate) molecules with their sodium
counter-ions in water: a model of an SDS micelle. Equilibrate it briefly
with GROMACS, then calculate two small-angle neutron scattering (SANS)
curves: one in heavy water (D₂O), and one in light water (H₂O) with
deuterated SDS.

The ball follows Shapespyer's SDS ball tutorial: one layer with 16
molecules on its equator, 0.4 nm apart. So Rmin is 16 × 0.4 / 2π, about
1.02 nm.

The assembled ball holds 80 SDS molecules, 80 sodium ions and about
4,900 water molecules: 18,212 atoms.

The equilibration runs two stages: an energy minimisation (eq0) and 25
ps of molecular dynamics with restraints (eq1). That takes minutes.

## Before you start

- Install EasyShapes and GROMACS (Linux, macOS, or WSL on Windows), see
  [Installation & Setup](../../installation-and-setup/index.md). The
  status bar shows whether the app found GROMACS.
- This tutorial edits a topology file the way the
  [vesicle tutorial](../mlv/index.md) explains. Read that one first.

## Create the project

1. On the Home page, click **Start**.
2. Click **Create a new project**, set **Name** to `SDSBall` and click
   **OK**.
3. Click **Continue**. The Sample Model page opens.

## Build the ball

In **Basic controls** › **Model Definition**, set **Shape** to Ball.
Keep **Type** at Discrete.

In **Basic controls** › **Components**:

1. Click **Load component(s)**, click SDS in the list and click **OK**.
2. In the SDS row, set **C-ion** to NAT. Each SDS gets one sodium ion.

![Components group with SDS, C-ion boxed](img/tutorial-sds-components-light.png#only-light)
![Components group with SDS, C-ion boxed](img/tutorial-sds-components-dark.png#only-dark)

In **Basic controls** › **Layers**, set **Dmin, nm** to 0.4 and **Rmin,
nm** to 1.02 in row 1.

![Layers group, Dmin and Rmin boxed](img/tutorial-sds-layers-light.png#only-light)
![Layers group, Dmin and Rmin boxed](img/tutorial-sds-layers-dark.png#only-dark)

In **Basic controls** › **Buffer**, set **Solvent** to TIP3.

![Buffer group, Solvent boxed](img/tutorial-sds-buffer-light.png#only-light)
![Buffer group, Solvent boxed](img/tutorial-sds-buffer-dark.png#only-dark)

## Save and assemble

Press Ctrl+S to save the project. As in the vesicle tutorial, save
before you edit any file.

Click **Assemble**. Shapespyer places the molecules, and GROMACS adds
the sodium ions and the water. The main area shows the Structure tab.

![Structure tab with the assembled ball](img/tutorial-sds-structure-light.png#only-light)
![Structure tab with the assembled ball](img/tutorial-sds-structure-dark.png#only-dark)

## Restrain the tails

In eq1, restraints keep the micelle's core together while the water
settles. Here they act on the tail carbons and are anchored at the
centre of the box: the second way in the vesicle tutorial's
[table](../mlv/index.md#two-ways-to-restrain).

In **Advanced controls** › **Components Files**, set **Select
component** to SDS and click :material-pencil: next to `SDS.itp`. At its
end, the library's file restrains only the sulfur atom:

```
#ifdef POSRES
[ position_restraints ]
    1     1    POSRES_FC_LIP    POSRES_FC_LIP    POSRES_FC_LIP
#endif
```

Replace these lines with the restraints of Shapespyer's SDS ball
example, and save the file:

```
#ifdef POSRES
[ position_restraints ]
;  ai  funct  g    r  k
    9      2  1  2.0  POSRES_FC_LIP   ; C2
   15      2  1  2.0  POSRES_FC_LIP   ; C4
   21      2  1  2.0  POSRES_FC_LIP   ; C6
   27      2  1  2.0  POSRES_FC_LIP   ; C8
   33      2  1  2.0  POSRES_FC_LIP   ; C10
   39      2  1  2.0  POSRES_FC_LIP   ; C12, the tail end
#endif
```

![Components Files group with SDS's files, Select component boxed](img/tutorial-sds-components-files-light.png#only-light)
![Components Files group with SDS's files, Select component boxed](img/tutorial-sds-components-files-dark.png#only-dark)

What the new lines mean:

- `ai` – every second carbon of the tail, C2 to C12, by its number in
  the file's `[ atoms ]` list.
- `funct` 2 – a flat-bottom restraint.
- `g` 1 – its shape: a sphere.
- `r` 2.0 – the sphere's radius, in nm. Inside it the atom moves freely.
  Outside it, a spring pulls the atom back.
- `k` – the spring's force constant. Each stage's `.mdp` file sets it:
  200 kJ mol⁻¹ nm⁻² in eq1.

With **Restrain to box centre** ticked (next section), the spheres sit
at the centre of the box. So every restrained carbon stays within 2 nm
of the centre, and the core holds together.

## Equilibrate

1. Click **Continue**. The Analysis page opens.
2. In **Basic controls** › **Equilibration**, keep **Configuration** and
   **Force field** at CHARMM36.
3. Keep **First stage** at eq0, and set **Last stage** to eq1.
4. Tick **Restrain to box centre**.
5. Click **Equilibrate**. The Engine output tab shows the GROMACS
   commands and their output while the run goes on.

![Equilibration group, Last stage and Restrain to box centre boxed](img/tutorial-sds-equilibration-light.png#only-light)
![Equilibration group, Last stage and Restrain to box centre boxed](img/tutorial-sds-equilibration-dark.png#only-dark)

!!! info "While it runs"

    eq0 minimises the energy: it moves the atoms out of each other's
    way, without restraints.

    eq1 runs 25 ps of molecular dynamics at 310 K, with the tail
    restraints at 200 kJ mol⁻¹ nm⁻².

    The configuration's later stages lower the restraints step by step
    and then run without them, for a better relaxed micelle. They take
    much longer.

## Look at the result

Open the main area's **Structure** tab and set **Stage** to eq1.

![Analysis Structure tab with eq1, Stage boxed](img/tutorial-sds-stage-light.png#only-light)
![Analysis Structure tab with eq1, Stage boxed](img/tutorial-sds-stage-dark.png#only-dark)

## Calculate the curves

In **Basic controls** › **Scattering**:

1. Set **Structure** to eq1.
2. Set **Solvent SLD, 10⁻⁶ Å⁻²** to 6.36, for D₂O, and click
   **Calculate**.
3. Set **Solvent SLD, 10⁻⁶ Å⁻²** to −0.56, for H₂O, tick SDS under
   **Deuterate**, and click **Calculate**.

Keep the other fields at their defaults.

![Scattering group, Solvent SLD and Deuterate boxed](img/tutorial-sds-scattering-setup-light.png#only-light)
![Scattering group, Solvent SLD and Deuterate boxed](img/tutorial-sds-scattering-setup-dark.png#only-dark)

!!! info "Why these two curves"

    The calculation scatters from the SDS atoms only. The water and the
    ions count as a uniform solvent, without a hydration shell.

    In D₂O, the hydrogen-rich tails stand out strongly against the heavy
    water: a common SANS measurement of SDS micelles. In H₂O, deuterated
    tails stand out just as strongly against the light water. The tails
    dominate both curves. The head groups have a different contrast in
    each, so the curves differ where the head-group shell matters.

## Read the curves

The Scattering tab draws both curves. In **Advanced controls** ›
**Scattering view**, the **Rg, Å** column gives each curve's radius of
gyration. Tick **Staggered view** to draw the second curve lower, so the
two don't overlap.

![Scattering tab with both curves, Rg and Staggered view boxed](img/tutorial-sds-scattering-light.png#only-light)
![Scattering tab with both curves, Rg and Staggered view boxed](img/tutorial-sds-scattering-dark.png#only-dark)

## Save

Press Ctrl+S.

## Next

The User Guide's [Analysis](../../user-guide/analysis.md) page describes
every control used here.
