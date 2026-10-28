# CUT&RUN Analysis & Figure Pipeline (C. elegans ce11)

[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![Environment uv](https://img.shields.io/badge/managed%20by-uv-orange.svg)](https://github.com/astral-sh/uv)
[![Build make](https://img.shields.io/badge/build-make-lightgrey.svg)](https://www.gnu.org/software/make/)

A reproducible genomics analysis and figure generation pipeline for *Caenorhabditis elegans* (`ce11`) CUT&RUN datasets. This project benchmarks CUT&RUN histone modifications (e.g., H3K4me3) against published modENCODE/modERN reference ChIP-seq datasets and Serizay et al. tissue-specific ATAC-seq profiles (Germline, Neurons, and Intestine).

> **Plain Text Guide:** For users without a markdown viewer, see the plain-text [`INSTALL.txt`](file:///Users/dan/Code/UMassMed_Projects/Cut_And_Run_Figures/INSTALL.txt) file in the project root.

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Ensure Make is Available](#1-ensure-make-is-available)
  - [2. Install Dependencies & Register Kernel](#2-install-dependencies--register-kernel)
  - [3. Configure Notebook Kernel (`set-kernel`)](#3-configure-notebook-kernel-set-kernel)
  - [4. Configure Environment Variables](#4-configure-environment-variables)
  - [5. Launch JupyterLab](#5-launch-jupyterlab)
- [Makefile Target Reference](#makefile-target-reference)
- [Pipeline & Notebook Workflow](#pipeline--notebook-workflow)
  - [Stage 1: Reference Data Acquisition](#stage-1-reference-data-acquisition)
  - [Stage 2: Feature & Profile Table Construction](#stage-2-feature--profile-table-construction)
  - [Stage 3: Figure Generation](#stage-3-figure-generation)
- [Outputs & Figures](#outputs--figures)
- [Maintenance & Cleanup](#maintenance--cleanup)

---

## Overview

This pipeline reproduces publication figures and quantitative genomic profiles:
- **Figure 1A:** Benchmarking CUT&RUN peak calls against modENCODE H3K4me3 L3-stage reference peaks lifted over from `ce6` to `ce11`.
- **Figure 2A:** Transcription Start Site (TSS) signal enrichment stratified across tissue-specific gene sets.
- **Figure 3:** Integration of tissue-specific ATAC-seq accessibility with H3K4me3 chromatin profiling.
- **Figure 7A:** Metagene profiles across long *C. elegans* genes (TSS to TES with flanking regions).

---

## Repository Structure

```text
Cut_And_Run_Figures/
├── Makefile                # Build automation and orchestration
├── required_dependencies.sh # Automated setup for system tools (curl, make, uv)
├── set_kernel.py           # Sets the default Jupyter kernel in all project notebooks
├── INSTALL.txt             # Plain-text installation instructions
├── README.md               # Project documentation (this file)
├── pyproject.toml          # Project package metadata and Python dependencies
├── env.example             # Template for external laboratory data paths
├── .env                    # Local environment configuration (untracked)
├── notebooks/
│   ├── 01a_ref_modENCODE_H3K4me3_L3_ce11.ipynb
│   ├── 01b_ref_serizay_atac_download.ipynb
│   ├── 02a_table_gene_tss_tes.ipynb
│   ├── 02b_table_tss_profile.ipynb
│   ├── 02c_tables_long_genes.ipynb
│   ├── 02d_table_atac_tss.ipynb
│   ├── 03_fig1a_cutrun_vs_modencode.ipynb
│   ├── 03_fig2a_tss_tissue_specific.ipynb
│   ├── 03_fig3_tissue_atac_vs_h3k4me3.ipynb
│   ├── 03_fig7a_long_gene_metagene.ipynb
│   ├── figures/            # Exported publication-ready figures (PNG & SVG)
│   ├── reference/          # Reference BigWigs, peak calls, and chain files
│   └── tables/             # Intermediate quantification matrices and CSV tables
└── results/                # Downstream analysis summaries
```

---

## Prerequisites

The included [`required_dependencies.sh`](file:///Users/dan/Code/UMassMed_Projects/Cut_And_Run_Figures/required_dependencies.sh) script automatically checks and installs all prerequisites:
- **`curl`:** Reference file and data download utility.
- **`make`:** Build and pipeline automation tool.
- **`uv`:** Ultra-fast Python package and virtual environment manager.

---

## Quickstart (4 Simple Steps)

### 1. Verify & Install System Dependencies

Run the automated prerequisite checker in the project root:

```bash
chmod +x required_dependencies.sh
./required_dependencies.sh
```

> **Automated:** If `curl`, `make`, or `uv` are missing, the script will automatically install them across macOS (via Homebrew or Apple Command Line Tools) and Linux.

### 2. Run the Automated Installer

Bootstrap the complete Python environment and project configuration:

```bash
make install
```

> **What `make install` does automatically:**
> 1. Creates `.venv` with Python 3.12 via `uv`.
> 2. Installs all project dependencies (`numpy`, `pandas`, `matplotlib`, `pyBigWig`, `jupyterlab`, `grip`, etc.).
> 3. Registers the `cut-and-run` Jupyter kernel (`Python 3.12 (Cut and Run)`).
> 4. Runs [`set_kernel.py`](file:///Users/dan/Code/UMassMed_Projects/Cut_And_Run_Figures/set_kernel.py) to configure all 10 notebooks to use this kernel automatically.
> 5. Downloads the UCSC `liftOver` binary directly into `.venv/bin/`.
> 6. Initializes `.env` from `env.example` if it does not already exist.

### 3. Configure Laboratory Data Path (`.env`)

Before launching the notebooks, configure the path to the Walker Lab CUT&RUN raw dataset.

**Option A — Quick terminal command (No text editor needed):**
```bash
echo 'WALKER_LAB_DIR="/path/to/Walker_lab_shared/Bioinformatics_parent/cut_run092226"' > .env
```

**Option B — Open with a desktop or terminal editor:**
- macOS (TextEdit): `open -e .env`
- Linux GUI: `xdg-open .env`
- Terminal: `nano .env`

### 4. Launch JupyterLab

Start JupyterLab pointing directly to the project notebooks:

```bash
make notebook
```

JupyterLab will launch in your default web browser. You can open any notebook and start executing cells without needing to configure kernels manually!

---

## Makefile Target Reference

All primary commands are driven via the root [`Makefile`](file:///Users/dan/Code/UMassMed_Projects/Cut_And_Run_Figures/Makefile):

| Target | Description |
| :--- | :--- |
| `make install` | Fully bootstraps `.venv`, dependencies, kernel registration, notebook configuration, `liftOver`, and default `.env`. |
| `make notebook` | Runs JupyterLab bound to `.venv` with `--notebook-dir=notebooks`. |
| `make readme` | Renders and opens `README.md` in your default browser with GitHub styling via `grip`. |
| `make set-kernel` | Re-syncs the default kernelspec for all notebooks in `notebooks/` to `cut-and-run`. |
| `make liftover` | Re-downloads the platform-specific UCSC `liftOver` executable into `.venv/bin/`. |
| `make clean` | Removes virtual environment (`.venv`), temporary build artifacts, and caches. |
| `make help` | Displays list of available Makefile targets. |



---

## Pipeline & Notebook Workflow

The notebooks are organized into numbered sequential stages:

### Stage 1: Reference Data Acquisition
- **`01a_ref_modENCODE_H3K4me3_L3_ce11.ipynb`**: Downloads modENCODE L3 H3K4me3 peak coordinates, uncompresses MACS peak files, and performs coordinate liftover from `ce6` to `ce11` via UCSC `liftOver`.
- **`01b_ref_serizay_atac_download.ipynb`**: Downloads adult tissue-specific ATAC-seq bigWigs (Germline, Neurons, Intestine) from GEO (Serizay et al., GSM4197238, GSM4197239, GSM4197242).

### Stage 2: Feature & Profile Table Construction
- **`02a_table_gene_tss_tes.ipynb`**: Builds the canonical *C. elegans* `ce11` TSS/TES coordinate reference.
- **`02b_table_tss_profile.ipynb`**: Computes signal matrices around TSS windows stratified by tissue specificity.
- **`02c_tables_long_genes.ipynb`**: Calculates metagene matrices for long *C. elegans* genes (>10kb and top 20% by length).
- **`02d_table_atac_tss.ipynb`**: Computes ATAC-seq signal around promoter regions across different tissues.

### Stage 3: Figure Generation
- **`03_fig1a_cutrun_vs_modencode.ipynb`**: Generates Figure 1A comparing CUT&RUN signal with modENCODE reference peaks.
- **`03_fig2a_tss_tissue_specific.ipynb`**: Produces Figure 2A TSS heatmaps and line plots across tissue sets.
- **`03_fig3_tissue_atac_vs_h3k4me3.ipynb`**: Produces Figure 3 integrating chromatin accessibility (ATAC) and H3K4me3 enrichment.
- **`03_fig7a_long_gene_metagene.ipynb`**: Generates Figure 7A metagene profiles for long gene structures.

---

## Outputs & Figures

Exported figures are saved in both PNG (raster preview) and SVG (publication vector) formats in `notebooks/figures/`:

- `fig1_panel_a_reproduced.{png,svg}`
- `fig2_panel_a_reproduced.{png,svg}`
- `fig2_tss_tissue_specific_reproduced.{png,svg}`
- `fig3_panel_b_reproduced.{png,svg}`
- `fig3_tissue_atac_vs_h3k4me3_reproduced.{png,svg}`
- `fig7a_long_gene_metagene.{png,svg}`

---

## Maintenance & Cleanup

To clean environment and generated build caches:
```bash
make clean
```
