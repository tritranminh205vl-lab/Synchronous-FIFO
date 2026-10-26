# My GitHub Workflow — Synchronous FIFO RTL/DV

I maintain this repository with a Git workflow that keeps design, verification, and documentation changes reviewable. The commands below are my workflow reference for Windows with Git Bash; most also work in PowerShell or Linux/macOS.

## 1. Git setup

I check the Git installation with:

```bash
git --version
```

For commit attribution, I configure my Git name and email locally. I use the following placeholders as a setup template and replace them with my own details before running the commands:

```bash
git config --global user.name "MY NAME"
git config --global user.email "MY_EMAIL@example.com"
```

## 2. Local checkout

To obtain a local copy of my repository, I use:

```bash
git clone https://github.com/tritranminh205vl-lab/Synchronous-FIFO.git
cd Synchronous-FIFO
```

I check that the checkout contains:

```text
rtl/
tb/
docs/
.github/
Makefile
README.md
```

## 3. Checks before committing

For RTL or verification changes, my workflow calls for the portable regression with Icarus Verilog available in PATH:

```bash
make basic
```

On Windows without Make, I use:

```bat
scripts\run_basic.bat
```

Additional checks, when the tools are installed, are:

```bash
make lint
make synth
```

I treat a failing regression as an issue to resolve before merging an RTL or verification change into `main`.

## 4. Feature branches and commits

For a new assertion, my workflow uses a dedicated branch:

```bash
git checkout -b test/add-pointer-assertions
```

After editing and running the relevant checks, I review and commit the change:

```bash
git status
git diff
git add tb/sva/sync_fifo_sva.sv
git commit -m "test: add FIFO pointer assertions"
git push -u origin test/add-pointer-assertions
```

I use a pull request into `main` to review the diff and the GitHub Actions results.

## 5. Commit organization

I describe the actual scope of each change in the commit message. Examples for future work include:

```text
feat(rtl): implement parameterized counter-based FIFO
test: add self-checking reference model and directed tests
test: add random regression and coverage tracking
test: add SystemVerilog assertions
verify: add UVM agent scoreboard and coverage
ci: add GitHub Actions RTL regression
docs: add RTL spec DV plan and traceability
```

These examples are naming conventions, not a reconstruction of my repository history. I preserve the actual commit history and timestamps.

## 6. CI workflow

I included `.github/workflows/rtl-regression.yml` for pushes and pull requests to `main`. It runs:

```text
Icarus self-checking simulation
          ↓
Verilator lint
          ↓
Yosys synthesis sanity check
```

I keep UVM outside this public CI workflow because the commercial simulators used for it require licenses. I document my EDA Playground runs separately under `docs/evidence/`, including the recorded commands and available console excerpts. Those reports retain the limits of the available source and coverage evidence.

## 7. Repository description

I describe the project as:

> My parameterized synchronous FIFO in SystemVerilog, with self-checking DV, a scoreboard, assertions, functional coverage, a UVM environment, synthesis sanity checks, and CI.

## 8. Project presentation

I organize my project so a reviewer can follow the design and verification approach in this order:

```text
README.md          -> project overview and run commands
docs/RTL_SPEC.md   -> FIFO behavior I specified
docs/DV_PLAN.md    -> my verification strategy and planned scenarios
rtl/sync_fifo.sv   -> my design implementation
tb/basic/          -> my portable self-checking testbench
tb/sva/            -> my invariant and temporal checks
tb/uvm/            -> my transaction-level verification environment
GitHub Actions     -> automated regression workflow
```
