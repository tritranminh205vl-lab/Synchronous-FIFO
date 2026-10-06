# GitHub Guide — Synchronous FIFO RTL/DV

This guide assumes Windows and Git Bash, but the same Git commands work in PowerShell or Linux/macOS.

## 1. Install Git and identify yourself

Check Git:

```bash
git --version
```

One-time identity setup:

```bash
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR_EMAIL@example.com"
```

## 2. Open the project folder

Extract the project, then open Git Bash in `sync_fifo_rtl_dv_project`.

Check that you can see:

```text
rtl/
tb/
docs/
.github/
Makefile
README.md
```

## 3. Run the regression before committing

With Icarus Verilog in PATH:

```bash
make basic
```

On Windows without `make`:

```bat
scripts\run_basic.bat
```

Optional checks:

```bash
make lint
make synth
```

Do not push a knowingly failing regression to `main`.

## 4. Create the local repository

```bash
git init
git branch -M main
git status
```

Recommended first commit:

```bash
git add .
git commit -m "feat: add synchronous FIFO RTL and DV project"
```

## 5. Create the GitHub repository

On GitHub:

1. Create a new repository, for example `sync-fifo-rtl-dv`.
2. Keep it empty initially if you already have this local README.
3. Copy the repository HTTPS URL.

Connect it:

```bash
git remote add origin https://github.com/YOUR_USERNAME/sync-fifo-rtl-dv.git
git remote -v
git push -u origin main
```

If GitHub asks for authentication, use the supported browser/credential-manager flow rather than putting a password or token into source files.

## 6. Use feature branches like a real team

Example for adding a new assertion:

```bash
git checkout -b test/add-pointer-assertions
```

Edit files, run regression, then:

```bash
git status
git diff
git add tb/sva/sync_fifo_sva.sv
git commit -m "test: add FIFO pointer assertions"
git push -u origin test/add-pointer-assertions
```

Create a Pull Request into `main` and let GitHub Actions run.

## 7. Suggested commit history for a portfolio project

Instead of uploading everything as one unexplained commit, a clean learning history can look like:

```text
chore: add synchronous FIFO project skeleton
feat(rtl): implement parameterized counter-based FIFO
test: add self-checking reference model and directed tests
test: add random regression and coverage tracking
test: add SystemVerilog assertions
verify: add UVM agent scoreboard and coverage
ci: add GitHub Actions RTL regression
docs: add RTL spec DV plan and traceability
```

If you already finished everything locally, do not fake old timestamps or rewrite history just to imitate this. Use clear commits from now on.

## 8. What the CI workflow does

`.github/workflows/rtl-regression.yml` runs for pushes and pull requests to `main` and performs:

```text
Icarus self-checking simulation
          ↓
Verilator lint
          ↓
Yosys synthesis sanity check
```

UVM is not included in public CI because common commercial simulators require licenses. Run UVM locally in Questa/VCS/Xcelium and preserve the command/logs you use.

## 9. Repository description suggestion

> Parameterized synchronous FIFO in SystemVerilog with self-checking DV, scoreboard, assertions, functional coverage, UVM environment, synthesis sanity checks, and CI.

## 10. What to show a recruiter

Keep the repository readable. A reviewer should be able to find, in this order:

```text
README.md          -> what the block does and how to run it
docs/RTL_SPEC.md   -> exact behavior
docs/DV_PLAN.md    -> what you verified
rtl/sync_fifo.sv   -> design implementation
tb/basic/          -> portable proof that it works
tb/sva/            -> protocol/invariant checks
tb/uvm/            -> scalable DV structure
GitHub Actions     -> repeatable automated regression
```
