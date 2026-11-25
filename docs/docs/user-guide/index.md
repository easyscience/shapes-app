---
icon: material/book-open-variant
---

# :material-book-open-variant: User Guide

**EasyShapes** builds ordered molecular aggregates, such as vesicles,
bilayers and micelles, as starting structures for molecular dynamics
(MD) simulations. It can then equilibrate them with GROMACS and
calculate their small-angle neutron scattering (SANS).

## Workflow

The tabs at the top of the window lead through the work, from left to
right:

1. **Home** – click **Start** to open the Project page.
2. **Project** – create a new project, open an existing one, or start
   from an example or a recent project.
3. **Sample Model** – choose the structure type, add the components
   (molecules) and their fractions, set the structure's layers or
   lamellae and the buffer, then click **Assemble**. **Continue** opens
   the Analysis page.
4. **Analysis** – equilibrate the structure with GROMACS
   (**Equilibrate**) and calculate its scattering curves
   (**Calculate**). **Continue** opens the Summary page.
5. **Summary** – read an outline of the project and its results.

## Tutorials

Each tutorial starts from a goal: the system to build and the result to
aim for. Then it goes through only the controls needed to get there.

- [Multilamellar vesicle](../tutorials/mlv/index.md) – build a vesicle
  of concentric lipid lamellae. No GROMACS needed.
- [SDS ball (micelle)](../tutorials/sds-ball/index.md) – build a ball of
  SDS molecules, equilibrate it with GROMACS and calculate its
  scattering curve, following the Shapespyer example.

## Interface

One page per tab, describing each group and control:

- [Project](project.md)
- [Sample Model](sample-model.md)
- [Analysis](analysis.md)
- [Summary](summary.md)
