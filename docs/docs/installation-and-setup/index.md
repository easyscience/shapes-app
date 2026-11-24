---
icon: material/cog-box
---

# :material-cog-box: Installation & Setup

**EasyShapes** is a cross-platform desktop application for Windows,
macOS, and Linux, compatible with **Python 3.11** through **3.13**.

To install and set up EasyShapes, we recommend using
[**Pixi**](https://pixi.prefix.dev), a modern package manager for
Windows, macOS, and Linux.

??? note "Main benefits of using Pixi"

    - **Ease of use**: Pixi simplifies the installation process, making it
      accessible even for users with limited experience in package management.
    - **Python version control**: Pixi allows specifying and managing different
      Python versions for each project, ensuring compatibility.
    - **Isolated environments**: Pixi creates isolated environments for each
      project, preventing conflicts between different package versions.
    - **PyPI and Conda support**: Pixi can install packages from both PyPI and
      Conda repositories, providing access to a wide range of libraries.

A packaged application, which needs no Pixi, will be available on the
[GitHub Releases page](https://github.com/easyscience/shapes-app/releases)
later.

## Installing with Pixi <small>recommended</small> { #installing-with-pixi data-toc-label="Installing with Pixi" }

This section describes the simplest way to set up EasyShapes using
**Pixi**.

#### Installing Pixi

- Install Pixi by following the instructions on the
  [official Pixi Installation Guide](https://pixi.prefix.dev/latest/installation).

#### Setting up EasyShapes with Pixi

<!-- prettier-ignore-start -->

- Check that your system is supported: Windows (64-bit), Linux (x86-64,
  glibc 2.35 or newer, e.g. Ubuntu 22.04+), or macOS 14 or newer on
  Apple Silicon.
- Make sure [Git](https://git-scm.com/downloads) is installed.
- Choose a project location (local drive recommended).

    ??? warning ":fontawesome-brands-windows: Windows + OneDrive"

        We **do not recommend creating a Pixi project inside OneDrive or other
        synced folders**.

        By default, Pixi creates the virtual environment inside the project
        directory (in `.pixi/`). On Windows, synced folders such as OneDrive
        may cause file‑system issues (e.g., path-length limitations or
        restricted link operations), which can lead to unexpected install
        errors or environments being recreated.

        Instead, create your project in a **local directory on your drive**
        where you have full write permissions.

<!-- prettier-ignore-end -->

- Download EasyShapes and navigate into it. Until the first release, the
  application is on the `develop` branch:
  ```txt
  git clone --branch develop https://github.com/easyscience/shapes-app.git
  cd shapes-app
  ```
- Install EasyShapes and everything it needs:
  ```txt
  pixi install
  ```
  This sets up the full development environment, including the tools for
  tests and documentation. The packaged application will be lighter.

#### Running EasyShapes

- Start the application inside the `shapes-app` directory:
  ```txt
  pixi run easyshapes-py
  ```

#### Updating EasyShapes

- Get the latest version and install what it needs:
  ```txt
  git pull
  pixi install
  ```
  Use `pixi install`, not `pixi update`: `pixi update` moves to newer
  package versions than EasyShapes was tested with.
- To update Pixi itself to the latest version:
  ```txt
  pixi self-update
  ```

#### Uninstalling EasyShapes and Pixi

- To remove EasyShapes, delete the `shapes-app` directory. Its environment
  is inside it, in `.pixi/`.
- By default, your projects and the Shapespyer settings are saved outside
  that directory: in `%APPDATA%\SimNavi\Shapespyer\` on Windows, in
  `~/Library/Application Support/Shapespyer/` on macOS, and in
  `~/.local/share/Shapespyer/` (projects) and `~/.config/Shapespyer/`
  (settings) on Linux. Delete them only if you no longer need your
  projects.
- To uninstall Pixi, follow the
  [official Pixi Guide](https://pixi.prefix.dev/latest/installation/#uninstall).

## GROMACS <small>optional</small> { #gromacs data-toc-label="GROMACS" }

EasyShapes builds structures on its own. To equilibrate them
(**Analysis** › **Equilibration**), it runs
[GROMACS](https://www.gromacs.org), which you install yourself.

- Install GROMACS by following the
  [GROMACS installation guide](https://manual.gromacs.org/current/install-guide/index.html).
  On Linux and macOS, package managers offer it (for example apt,
  Homebrew or conda-forge). On Windows, GROMACS has to be built from
  source; running EasyShapes inside WSL (Linux on Windows) is simpler.
- EasyShapes runs `gmx` from your `PATH`. The **Engine** item in the
  status bar shows the GROMACS version it found, or why it can't run it.
- If your GROMACS program has another name or is not on `PATH` (for
  example `gmx_mpi`), set it in the Shapespyer `config.yaml`, in the
  settings folder listed under
  [Uninstalling](#uninstalling-easyshapes-and-pixi):
  ```yaml
  gmx_executable: /path/to/gmx
  ```

## Development Setup

To work on the EasyShapes code itself (tests, formatting,
documentation), see the
[Contributing Guidelines](https://github.com/easyscience/shapes-app/blob/develop/CONTRIBUTING.md).
