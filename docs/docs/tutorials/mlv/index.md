# Multilamellar Vesicle

!!! note "Screenshots coming"

    The screenshots for this tutorial are being made.

## The goal

Build a dry multilamellar vesicle of POPC and cholesterol, 70 : 30, with
two lamellae. Then prepare it for equilibration: restrain the lipids and
set the temperature.

The spacing comes from neutron scattering on POPC vesicles. The lamellae
repeat every 6.4 nm in pure POPC (Holme et al., ACS Cent. Sci. 2018,
[10.1021/acscentsci.8b00286](https://doi.org/10.1021/acscentsci.8b00286)),
and 30 mol% cholesterol adds 0.23 nm (Utterström et al., Bioconjugate
Chem. 2022,
[10.1021/acs.bioconjchem.2c00115](https://doi.org/10.1021/acs.bioconjchem.2c00115)).
So the lamellae here repeat every 6.6 nm: a bilayer of about 4 nm and
2.6 nm of space for water.

| Setting             | Lamella 1 | Lamella 2 |
| ------------------- | --------- | --------- |
| Rmin, nm            | 3.0       | 9.6       |
| Inner dmin, nm      | 0.65      | 0.65      |
| Outer dmin, nm      | 0.85      | 0.85      |
| Shell thickness, nm | 4.0       | 4.0       |
| POPC : CHL          | 70 : 30   | 70 : 30   |

The dmins give the two-tail lipids more room than the default 0.5 nm.
The result holds 3,600 POPC and 1,543 cholesterol molecules in a 28.5 nm
box.

The vesicle stays dry, so this tutorial needs no GROMACS. Running the
equilibration needs water and GROMACS;
[Tutorial 2](../sds-ball/index.md) shows a run.

## Before you start

- Install EasyShapes, see
  [Installation & Setup](../../installation-and-setup/index.md).
- GROMACS is not needed. The status bar may show "gmx not found".
- A laptop is enough. The assembly takes a few minutes.

## Create the project

1. On the Home page, click **Start**. The Project page opens.
2. Click **Create a new project**.
3. In the **Create project** dialog, set **Name** to `MLV` and click
   **OK**. An empty **Location** saves the project in the default
   projects folder.
4. Click **Continue**. The Sample Model page opens.

## Choose the shape

On the Sample Model page, in **Basic controls** › **Model Definition**:

1. Set **Shape** to Vesicle.
2. Keep **Type** at Discrete.

The **Vesicle Structure Definition** and **Lamellae** groups appear.

## Add the components

In **Basic controls** › **Components**:

1. Click **Load component(s)**.
2. In the list, click POPC, then Ctrl+click CHL. Click **OK**.

The table shows POPC and CHL.

## Set the lamellae

In **Basic controls** › **Lamellae**:

1. Click **Add lamella**. The table now has two rows.
2. In row 1, set **Rmin, nm** to 3, **Inner dmin, nm** to 0.65, **Outer
   dmin, nm** to 0.85 and **Shell thickness, nm** to 4.
3. In row 2, set the same values, but **Rmin, nm** to 9.6.
4. Select row 1. In the **Fractions** table below, set the **Mole
   ratio** of POPC to 70 and of CHL to 30.
5. Select row 2 and set the same ratios.

The main area's **Shape** tab shows both lamellae, each with "shell 4.00
nm".

<!-- Image: Lamellae group with the two rows, Shape tab beside it -->

## Assemble

Click **Assemble**, below the groups. The main area switches to the
**Structure** tab and shows the progress. It takes a few minutes.

!!! info "While it assembles"

    Shapespyer places the molecules ring by ring on each leaflet's
    sphere, at least dmin apart, and then writes the structure file.

    The library's POPC is straight and about 2.95 nm long. Two of them
    don't fit in a 4 nm shell, so the leaflets start overlapping. During
    equilibration the tails bend and get shorter, and the bilayer
    settles near the measured thickness.

    The 2.6 nm between the lamellae is where water goes when the vesicle
    is solvated.

<!-- Image: Structure tab with the assembled vesicle -->

## Restrain heads and tail ends

During equilibration, position restraints hold chosen atoms near
reference positions while everything else relaxes. Here each lipid's
head and one tail end are restrained. That keeps the molecules pointing
outward and the leaflets in place. Restrain only one tail: two
restrained tails can cause more clashes in a packed lamella.

The library's POPC and cholesterol have no restraints. You add them to
each component's topology file (`.itp`).

### Find the atoms

On the Sample Model page, open the main area's **Components** tab and
pick POPC in **Component**. Hover over an atom to see its number and
element, for example `19 (P)`. Click an atom to keep its label.

The viewer counts atoms from 0, and the `.itp` file counts from 1, so
add 1 to the viewer's number. The viewer shows the element, not the
atom's name.

- POPC: the phosphorus shows `19 (P)`, so it is atom 20. The last carbon
  of the longer tail shows `87 (C)`, so it is atom 88.
- Cholesterol: the only oxygen shows `2 (O)`, so it is atom 3. The tail
  ends in two carbons, C26 and C27. This tutorial uses C27, which shows
  `70 (C)`, so it is atom 71.

<!-- Image: Components tab with POPC, labels on P and the tail end -->

### Check them in the topology file

In **Advanced controls** › **Components Files**, set **Select
component** to POPC. Click :material-pencil: next to `POPC_DLF.itp`. It
opens in your system's default app for `.itp` files. If the system asks
which app to use, pick a text editor such as Notepad.

This is the project's copy of the file. The asset library keeps the
original.

Near the top of the file, the `[ atoms ]` list has one line per atom of
the molecule. It came with the component from the asset library:
DL_FIELD made it for the CHARMM36 force field. The first column, `nr`,
is the atom's number, and the fifth, `atom`, is its name:

```
[ atoms ]
; nr   type   resnr   residu    atom    cgnr    charge    mass
    1      NTL    1 POPC    N     1  -0.6000000   14.0067
...
   20       PL    1 POPC    P    20   1.5000000   30.9740
...
   88     CTL3    1 POPC C218    88  -0.2700000   12.0110
```

So atom 20 is P, the head, and atom 88 is C218, the end of the oleoyl
tail.

A `;` starts a comment: GROMACS ignores the rest of the line. The second
line is a comment that names the columns, as a reminder for you.

### Add the restraints

At the end of `POPC_DLF.itp`, add these lines and save the file:

```
#ifdef POSRES
[ position_restraints ]
;  ai  funct  fcx            fcy            fcz
   20      1  POSRES_FC_LIP  POSRES_FC_LIP  POSRES_FC_LIP   ; P, head
   88      1  POSRES_FC_LIP  POSRES_FC_LIP  POSRES_FC_LIP   ; C218, tail end
#endif
```

Then set **Select component** to CHL, open `CHL.itp` the same way, and
add at its end:

```
#ifdef POSRES
[ position_restraints ]
;  ai  funct  fcx            fcy            fcz
    3      1  POSRES_FC_LIP  POSRES_FC_LIP  POSRES_FC_LIP   ; O3, head
   71      1  POSRES_FC_LIP  POSRES_FC_LIP  POSRES_FC_LIP   ; C27, tail end
#endif
```

What the lines mean:

- `#ifdef POSRES` … `#endif` – GROMACS reads the block only in the
  stages whose `.mdp` file defines `POSRES`: `equil1` to `equil4`. The
  energy minimisation, `equil0`, and the last stages, `equil5` and
  `equil6`, run without restraints.
- `ai` – the atom's number from `[ atoms ]`.
- `funct` – 1 is a harmonic spring that pulls the atom back to its
  reference position.
- `fcx`, `fcy`, `fcz` – the spring's force constant along x, y and z.
  `POSRES_FC_LIP` is a name; each stage's `.mdp` file gives its value:
  200, 100, 50 and 20 kJ mol⁻¹ nm⁻². The springs get weaker stage by
  stage.
- `; P, head` – a comment that says which atom the line holds.

### Two ways to restrain

The reference position, where a spring pulls to, depends on **Restrain
to box centre** on the Analysis page, in **Basic controls** ›
**Equilibration**:

- Unticked – each atom is held where it is when the stage starts. This
  tutorial uses this way.
- Ticked – the reference of every restrained atom is the centre of the
  box.

Each way goes with its own `funct`:

| Restrain to box centre | funct                         | What it does                                                                                                                           | Use it for                                  |
| ---------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| Unticked               | 1, harmonic                   | Pulls each atom back to its position at the start of the stage                                                                         | Any shape, any number of lamellae           |
| Unticked               | 2, flat-bottom, small radius  | Lets each atom move freely up to the radius from its start; pulls it back beyond                                                       | A start that is nearly right but needs room |
| Ticked                 | 2, flat-bottom, sphere radius | Lets each atom move freely within the radius of the box centre; pulls it back beyond. A negative radius keeps the atom outside instead | A vesicle with one lamella, or a ball       |
| Ticked                 | 1, harmonic                   | Pulls every restrained atom to the centre of the box                                                                                   | Nothing: don't combine these                |

A flat-bottom line has the columns `ai`, `funct` (2), `g` (1 for a
sphere), `r` (the radius, nm) and `k` (the force constant). Two lines
for one atom, one with a positive and one with a negative radius, keep
it in a spherical shell. For example, for a cholesterol head between 4.5
and 8.5 nm from the centre of a vesicle with one lamella:

```
;  ai  funct  g     r   k
    1      2  1   8.5   POSRES_FC_LIP   ; within 8.5 nm of the centre
    1      2  1  -4.5   POSRES_FC_LIP   ; at least 4.5 nm from it
```

This tutorial can't use the shell way. One `.itp` file holds the
restraints for every POPC, in both lamellae, so one set of radii can't
fit two lamellae at different distances from the centre.

## Set the temperature

1. On the Sample Model page, click **Continue**. The Analysis page
   opens.
2. In **Advanced controls** › **Configuration Files**, click
   :material-pencil: next to `equil1.mdp`.
3. Change `ref_t` from 310 to 298.15 (25 °C, the temperature of the
   measurements) and save the file.
4. Do the same in `equil2.mdp` to `equil6.mdp`.

`equil0.mdp` is the energy minimisation: it has no temperature.

In `equil1.mdp` to `equil5.mdp`, the lines look like this:

```
tcoupl                  = berendsen
tc_grps                 = SYSTEM
tau_t                   = 1.0
ref_t                   = 310
```

After the change:

```
tcoupl                  = berendsen
tc_grps                 = SYSTEM
tau_t                   = 1.0
ref_t                   = 298.15
```

`equil6.mdp` has two `ref_t` lines. Change only the one without `;` at
the start. The other one is a comment:

```
;tcoupl                  = berendsen
;tc_grps                 = SYSTEM
;tau_t                   = 1.0
;ref_t                   = 310
;
tcoupl                  = nose-hoover ;berendsen
tc_grps                 = SYSTEM
tau_t                   = 1.0
ref_t                   = 298.15
```

The `;berendsen` after `nose-hoover` is also a comment: an older choice,
kept as a note.

The other settings in these files, such as the pressure coupling, are
already right.

## Choose per-atom restraints

On the Analysis page, in **Basic controls** › **Equilibration**, leave
**Restrain to box centre** unticked.

Don't click **Equilibrate**: the vesicle has no water, and the run needs
GROMACS.

## Save

Press Ctrl+S, or click :material-content-save: at the top left. The
project folder now holds the vesicle, the restraints and the
temperatures.

## Next

The vesicle needs water before it can be equilibrated.
[Tutorial 2](../sds-ball/index.md) shows how to add a buffer, run the
equilibration and calculate a scattering curve, with a ball of SDS.
