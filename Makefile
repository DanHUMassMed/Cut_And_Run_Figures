SHELL := /bin/bash
VENV ?= .venv
PYTHON := $(VENV)/bin/python
UV ?= uv
KERNEL_NAME ?= cut-and-run
KERNEL_DISPLAY_NAME ?= Python 3.12 (Cut and Run)

# Enforce hardware architecture directly via kernel sysctl to bypass x86_64 Conda/Rosetta masking
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  IS_APPLE_SILICON := $(shell sysctl -n hw.optional.arm64 2>/dev/null)
  ifeq ($(IS_APPLE_SILICON),1)
    PY_SPEC = cpython-3.12-macos-aarch64-none
  else
    PY_SPEC = cpython-3.12-macos-x86_64-none
  endif
else
  PY_SPEC = 3.12
endif

.PHONY: help install liftover set-kernel notebook readme clean

help:
	@echo "Available targets:"
	@echo "  make install    - Create virtualenv with Python 3.12 via uv, install dependencies, register kernel, and liftOver"
	@echo "  make liftover   - Download standalone UCSC liftOver binary into $(VENV)/bin"
	@echo "  make set-kernel - Set the kernel for all notebooks to the local venv"
	@echo "  make notebook   - Launch Jupyter Lab"
	@echo "  make readme     - Render and preview README.md in default web browser via grip"
	@echo "  make clean      - Remove virtualenv and temporary build artifacts"

install:
	$(UV) python install $(PY_SPEC)
	$(UV) venv --clear --python $(PY_SPEC) $(VENV)
	@echo "Python architecture: $$($(PYTHON) -c 'import platform; print(platform.machine())')"
	VIRTUAL_ENV=$(VENV) CONDA_PREFIX= $(UV) pip install -e ".[notebook,yaml,test,doc]"
	$(PYTHON) -m ipykernel install --sys-prefix \
		--name $(KERNEL_NAME) \
		--display-name "$(KERNEL_DISPLAY_NAME)"
	@$(MAKE) set-kernel
	@$(MAKE) liftover
	@if [ ! -f .env ]; then \
		if [ -f env.example ]; then cp env.example .env; echo "Initialized default .env configuration."; \
		elif [ -f .env.example ]; then cp .env.example .env; echo "Initialized default .env configuration."; fi \
	fi
	@echo ""
	@echo "=================================================================="
	@echo " Installation Complete!"
	@echo " Run 'make notebook' to launch JupyterLab."
	@echo "=================================================================="

liftover:
	@mkdir -p $(VENV)/bin
	@OS=$$(uname -s); \
	IS_ARM64=$$(sysctl -n hw.optional.arm64 2>/dev/null || [ "$$(uname -m)" = "aarch64" ] && echo 1 || echo 0); \
	if [ "$$OS" = "Darwin" ] && [ "$$IS_ARM64" = "1" ]; then \
		echo "Downloading UCSC liftOver for macOS (arm64)..."; \
		curl -fsSL -o $(VENV)/bin/liftOver http://hgdownload.soe.ucsc.edu/admin/exe/macOSX.arm64/liftOver; \
		xattr -d com.apple.quarantine $(VENV)/bin/liftOver 2>/dev/null || true; \
	elif [ "$$OS" = "Darwin" ]; then \
		echo "Downloading UCSC liftOver for macOS (x86_64)..."; \
		curl -fsSL -o $(VENV)/bin/liftOver http://hgdownload.soe.ucsc.edu/admin/exe/macOSX.x86_64/liftOver; \
		xattr -d com.apple.quarantine $(VENV)/bin/liftOver 2>/dev/null || true; \
	else \
		echo "Downloading UCSC liftOver for Linux (x86_64)..."; \
		curl -fsSL -o $(VENV)/bin/liftOver http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver; \
	fi
	@chmod +x $(VENV)/bin/liftOver
	@echo "UCSC liftOver successfully installed to $(VENV)/bin/liftOver"

set-kernel:
	$(PYTHON) set_kernel.py

notebook:
	$(VENV)/bin/jupyter lab --notebook-dir=notebooks

readme:
	@PYTHONWARNINGS="ignore" $(VENV)/bin/grip README.md -b

clean:
	rm -rf $(VENV) build/ dist/ *.egg-info .pytest_cache .ipynb_checkpoints